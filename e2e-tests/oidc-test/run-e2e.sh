#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: OIDC / SecurityConfig Validation"
echo "=================================================="

SCHEMA="schema-oidc.yaml"
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

# ── Positive case: OIDC enabled ──────────────────────────────────

echo "Testing OIDC-enabled generation (Spring Boot)..."
java -jar "$JAR" \
  --schema="$SCHEMA" \
  --cartridge=../../apibridge-cartridges/backend/spring-boot \
  --output="$GENERATED"

SECURITY_FILE="$GENERATED/src/main/java/com/apibridge/generated/SecurityConfig.java"

# 3. Verify SecurityConfig.java exists
echo "Verifying SecurityConfig.java..."
[ -f "$SECURITY_FILE" ] && pass "SecurityConfig.java present" || fail "SecurityConfig.java missing"

# 4. Validate SecurityConfig content
grep -q "@EnableWebSecurity" "$SECURITY_FILE"               && pass "@EnableWebSecurity"        || fail "missing @EnableWebSecurity"
grep -q "@Configuration" "$SECURITY_FILE"                   && pass "@Configuration"             || fail "missing @Configuration"
grep -q "oauth2ResourceServer" "$SECURITY_FILE"             && pass "oauth2ResourceServer"       || fail "missing oauth2ResourceServer"
grep -q "auth.example.com/realms/test" "$SECURITY_FILE"     && pass "OIDC issuer URI"            || fail "missing OIDC issuer URI"
grep -q "SecurityFilterChain" "$SECURITY_FILE"              && pass "SecurityFilterChain bean"   || fail "missing SecurityFilterChain"
grep -q "SessionCreationPolicy.STATELESS" "$SECURITY_FILE"  && pass "stateless sessions"         || fail "missing stateless session policy"

# 5. Verify pom.xml includes OAuth2 dependency
POM_FILE="$GENERATED/pom.xml"
[ -f "$POM_FILE" ] && pass "pom.xml present" || fail "pom.xml missing"
grep -q "spring-boot-starter-oauth2-resource-server" "$POM_FILE" && pass "OAuth2 dependency" || fail "missing OAuth2 dependency in pom.xml"

# 6. Compile check
echo "Verifying Maven compile..."
(cd "$GENERATED" && mvn compile -q) && pass "Maven compile succeeds" || fail "Maven compile failed"

# ── Negative case: OIDC disabled ─────────────────────────────────

echo "Testing OIDC-disabled generation..."
rm -rf "$GENERATED"

cat > "schema-no-oidc.yaml" <<'EOF'
id: "no-oidc-service"
basePath: "/api/v1"
endpoints:
  - path: "/items"
    method: "GET"
    backendUrl: "https://internal-mesh.local/items"
EOF

java -jar "$JAR" \
  --schema="schema-no-oidc.yaml" \
  --cartridge=../../apibridge-cartridges/backend/spring-boot \
  --output="$GENERATED"

if [ -f "$GENERATED/src/main/java/com/apibridge/generated/SecurityConfig.java" ]; then
  fail "SecurityConfig.java should NOT be generated when enableOidc is absent"
else
  pass "no SecurityConfig.java when enableOidc absent"
fi

rm -f "schema-no-oidc.yaml"

echo "=================================================="
echo "E2E OIDC / SecurityConfig PASSED"
echo "=================================================="
