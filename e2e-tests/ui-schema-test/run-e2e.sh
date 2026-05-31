#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: UI Schema Validation"
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

# 3. Generate UI schema
echo "Generating UI schema..."
java -jar "$JAR" \
  --schema="$SCHEMA" \
  --cartridge=../../apibridge-cartridges/frontend/ui-schema \
  --output="$GENERATED"

# 4. Verify file exists
echo "Verifying UI schema structure..."

UI_SCHEMA=""
for candidate in "$GENERATED/UiLayoutSchema.json" "$GENERATED/frontend/UiLayoutSchema.json"; do
  if [ -f "$candidate" ]; then
    UI_SCHEMA="$candidate"
    break
  fi
done

[ -n "$UI_SCHEMA" ] && pass "UiLayoutSchema.json present ($UI_SCHEMA)" || fail "UiLayoutSchema.json missing"

# 5. Validate it is valid JSON
echo "Validating JSON syntax..."
if command -v python3 &>/dev/null; then
  python3 -c "import json; json.load(open('$UI_SCHEMA'))" && pass "valid JSON" || fail "invalid JSON"
elif command -v jq &>/dev/null; then
  jq . "$UI_SCHEMA" > /dev/null && pass "valid JSON" || fail "invalid JSON"
else
  grep -q '"id"' "$UI_SCHEMA" && pass "looks like JSON (has id)" || fail "missing JSON id key"
fi

# 6. Validate content
echo "Validating UI schema content..."

grep -q '"id": "customer-onboarding-bridge"' "$UI_SCHEMA"  && pass "service id"          || fail "missing service id"
grep -q '"basePath": "/api/v1/onboarding"' "$UI_SCHEMA"    && pass "basePath"             || fail "missing basePath"
grep -q '"component": "List"' "$UI_SCHEMA"                  && pass "List component"       || fail "missing List component"
grep -q '"component": "View"' "$UI_SCHEMA"                  && pass "View component"       || fail "missing View component"
grep -q '"component": "Form"' "$UI_SCHEMA"                  && pass "Form component"       || fail "missing Form component"
grep -q '"name": "email"' "$UI_SCHEMA"                      && pass "field name: email"    || fail "missing field name: email"
grep -q '"name": "companyName"' "$UI_SCHEMA"                && pass "field name: companyName" || fail "missing field name: companyName"
grep -q '"method": "GET"' "$UI_SCHEMA"                      && pass "GET method"           || fail "missing GET method"
grep -q '"method": "POST"' "$UI_SCHEMA"                     && pass "POST method"          || fail "missing POST method"
grep -q '"method": "PUT"' "$UI_SCHEMA"                      && pass "PUT method"           || fail "missing PUT method"
grep -q '"method": "DELETE"' "$UI_SCHEMA"                   && pass "DELETE method"        || fail "missing DELETE method"
grep -q '"required": true' "$UI_SCHEMA"                     && pass "required field marker" || fail "missing required field marker"

# 7. Verify endpoints without uiLayout have null
echo "Verifying null layout for endpoints without uiLayout..."
grep -q '"uiLayout": null' "$UI_SCHEMA"                     && pass "null layout for bare endpoints" || fail "missing null uiLayout"

echo "=================================================="
echo "E2E UI Schema PASSED"
echo "=================================================="
