#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: securityLevel=apiKey Validation"
echo "=================================================="

SCHEMA="schema-apikey.yaml"
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

# 3. Generate with apiKey security
echo "Generating Spring Boot project with securityLevel=apiKey..."
java -jar "$JAR" \
  --schema="$SCHEMA" \
  --cartridge=../../apibridge-cartridges/backend/spring-boot \
  --output="$GENERATED"

CONTROLLER="$GENERATED/src/main/java/com/apibridge/generated/BridgeController.java"

# 4. Verify apiKey-specific code
echo "Verifying apiKey security output..."
grep -q 'X-API-Key' "$CONTROLLER"              && pass "X-API-Key header check"       || fail "missing X-API-Key header check"
grep -q 'expectedApiKey' "$CONTROLLER"          && pass "expectedApiKey field"          || fail "missing expectedApiKey field"
grep -q 'API_KEY' "$CONTROLLER"                 && pass "API_KEY env var reference"     || fail "missing API_KEY env var"

# 5. Verify bearer-token code is NOT present
echo "Verifying bearer-token code is absent..."
if grep -q 'validateBearerToken' "$CONTROLLER"; then
  fail "bearer-token code should not be present with securityLevel=apiKey"
else
  pass "no bearer-token validation method"
fi

if grep -q 'Authorization' "$CONTROLLER"; then
  fail "Authorization header check should not be present with securityLevel=apiKey"
else
  pass "no Authorization header check"
fi

# 6. Verify Helm values.yaml includes API_KEY env
echo "Generating Helm values with securityLevel=apiKey..."
rm -rf "$GENERATED"
java -jar "$JAR" \
  --schema="$SCHEMA" \
  --cartridge=../../apibridge-cartridges/devops/k8s/helm \
  --output="$GENERATED"

VALUES="$GENERATED/values.yaml"
grep -q 'API_KEY:' "$VALUES"                    && pass "API_KEY in Helm values"        || fail "missing API_KEY in Helm values"

echo "=================================================="
echo "E2E apiKey Security PASSED"
echo "=================================================="
