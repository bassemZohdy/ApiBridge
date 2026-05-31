#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: OpenAPI Spec Validation"
echo "=================================================="

SCHEMA="../../sample-schema.yaml"
JAR="../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar"
GENERATED="generated"

pass() { echo "  ✓ $*"; }
fail() { echo "  ✗ $*"; exit 1; }

# 1. Clean
rm -rf "$GENERATED"

# 2. Build generator (skip when CI already built it)
if [ "${SKIP_GENERATOR_BUILD:-false}" = "true" ]; then
  echo "[skip] generator build"
else
  echo "Building ApiBridge Generator..."
  (cd ../.. && mvn package -q -DskipTests)
fi

# 3. Generate OpenAPI spec
echo "Generating OpenAPI specification..."
java -jar "$JAR" \
  --schema="$SCHEMA" \
  --cartridge=../../apibridge-cartridges/docs/openapi \
  --output="$GENERATED"

# 4. Verify file exists (cartridge is under docs/, so output is at root)
echo "Verifying OpenAPI spec structure..."

SPEC=""
for candidate in "$GENERATED/openapi.yaml" "$GENERATED/docs/openapi.yaml"; do
  if [ -f "$candidate" ]; then
    SPEC="$candidate"
    break
  fi
done

[ -n "$SPEC" ] && pass "openapi.yaml present ($SPEC)" || fail "openapi.yaml missing"

# 5. Validate OpenAPI spec content
echo "Validating OpenAPI spec content..."

grep -q "openapi:" "$SPEC"                         && pass "openapi version key"    || fail "missing openapi version key"
grep -q "customer-onboarding-bridge" "$SPEC"       && pass "service id"             || fail "missing service id"
grep -q "paths:" "$SPEC"                           && pass "paths section"          || fail "missing paths section"
grep -q "/submissions" "$SPEC"                     && pass "endpoint /submissions"  || fail "missing /submissions path"
grep -q "/initiate" "$SPEC"                        && pass "endpoint /initiate"     || fail "missing /initiate path"
grep -q "get:" "$SPEC"                             && pass "GET method"             || fail "missing GET method"
grep -q "post:" "$SPEC"                            && pass "POST method"            || fail "missing POST method"
grep -q "put:" "$SPEC"                             && pass "PUT method"             || fail "missing PUT method"
grep -q "delete:" "$SPEC"                          && pass "DELETE method"          || fail "missing DELETE method"
grep -q "bearerAuth:" "$SPEC"                      && pass "security scheme (bearer)" || fail "missing bearerAuth security scheme"
grep -q "securitySchemes:" "$SPEC"                 && pass "securitySchemes section" || fail "missing securitySchemes section"

# 6. Verify requestBody for Form endpoints
echo "Validating Form endpoint requestBody..."
grep -q "requestBody:" "$SPEC"                     && pass "requestBody present"    || fail "missing requestBody"
grep -q "required: true" "$SPEC"                   && pass "required fields"        || fail "missing required fields marker"

# 7. Verify parameters for path-variable endpoints
echo "Validating path parameters..."
grep -q "in: path" "$SPEC"                         && pass "path parameters"        || fail "missing path parameters"

# 8. Negative test: generate without enableOpenApi
echo "Verifying conditional generation..."
SCHEMA_NO_OPENAPI="schema-no-openapi.yaml"
cat > "$SCHEMA_NO_OPENAPI" <<'EOF'
id: "test-service"
basePath: "/api/test"
endpoints:
  - path: "/items"
    method: "GET"
    backendUrl: "https://example.com/items"
EOF

rm -rf "$GENERATED"
java -jar "$JAR" \
  --schema="$SCHEMA_NO_OPENAPI" \
  --cartridge=../../apibridge-cartridges/docs/openapi \
  --output="$GENERATED"

if [ -f "$GENERATED/openapi.yaml" ] || [ -f "$GENERATED/docs/openapi.yaml" ]; then
  # File might exist but be empty — check size
  FOUND=$(find "$GENERATED" -name "openapi.yaml" -size +0 2>/dev/null)
  if [ -n "$FOUND" ]; then
    fail "openapi.yaml should not be generated when enableOpenApi is absent"
  else
    pass "no openapi.yaml when enableOpenApi absent"
  fi
else
  pass "no openapi.yaml when enableOpenApi absent"
fi

rm -f "$SCHEMA_NO_OPENAPI"

echo "=================================================="
echo "E2E OpenAPI PASSED"
echo "=================================================="
