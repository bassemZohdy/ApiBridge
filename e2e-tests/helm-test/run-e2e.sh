#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: Helm Chart Validation"
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

# 3. Generate Helm chart
echo "Generating Helm chart..."
java -jar "$JAR" \
  --schema="$SCHEMA" \
  --cartridge=../../apibridge-cartridges/devops/k8s/helm \
  --output="$GENERATED"

# 4. Verify Helm chart structure
echo "Verifying Helm chart structure..."

for f in Chart.yaml values.yaml; do
  FILE="$GENERATED/$f"
  [ -f "$FILE" ] && pass "$f present" || fail "$f missing"
done

for f in deployment.yaml service.yaml ingress.yaml configmap.yaml _helpers.tpl; do
  FILE="$GENERATED/templates/$f"
  [ -f "$FILE" ] && pass "templates/$f present" || fail "templates/$f missing"
done

# 5. Validate Chart.yaml content
echo "Validating Chart.yaml..."
CHART="$GENERATED/Chart.yaml"

grep -q "apiVersion: v2" "$CHART"                       && pass "apiVersion: v2"           || fail "missing apiVersion: v2"
grep -q "name: customer-onboarding-bridge" "$CHART"     && pass "chart name"               || fail "missing chart name"
grep -q "description:" "$CHART"                         && pass "description present"      || fail "missing description"
grep -q "type: application" "$CHART"                    && pass "type: application"        || fail "missing type"

# 6. Validate values.yaml content
echo "Validating values.yaml..."
VALUES="$GENERATED/values.yaml"

grep -q "replicaCount:" "$VALUES"                       && pass "replicaCount"             || fail "missing replicaCount"
grep -q "repository:" "$VALUES"                         && pass "image repository"         || fail "missing image repository"
grep -q "AUTH_SERVER_URL" "$VALUES"                     && pass "security config"          || fail "missing AUTH_SERVER_URL (securityLevel=bearer-token)"
grep -q "MANAGEMENT_TRACING_ENABLED" "$VALUES"          && pass "telemetry config"         || fail "missing telemetry config"
grep -q "RATE_LIMIT_PERMITS" "$VALUES"                  && pass "rate limiter config"      || fail "missing rate limiter config"
grep -q "HEALTH_CHECK_INTERVAL" "$VALUES"               && pass "health check config"      || fail "missing health check config"
grep -q "SEARCH_PARAM" "$VALUES"                        && pass "search config"            || fail "missing search config"

# 7. Validate templates contain Helm syntax
echo "Validating Helm template syntax..."

DEPLOYMENT="$GENERATED/templates/deployment.yaml"
grep -q '{{' "$DEPLOYMENT"                              && pass "deployment has Helm expressions" || fail "missing Helm expressions in deployment"
grep -q '.Values.' "$DEPLOYMENT"                        && pass "deployment uses .Values"        || fail "missing .Values references in deployment"

SERVICE="$GENERATED/templates/service.yaml"
grep -q '{{' "$SERVICE"                                 && pass "service has Helm expressions"    || fail "missing Helm expressions in service"

CONFIGMAP="$GENERATED/templates/configmap.yaml"
grep -q '{{' "$CONFIGMAP"                               && pass "configmap has Helm expressions"  || fail "missing Helm expressions in configmap"

HELPERS="$GENERATED/templates/_helpers.tpl"
grep -q '{{-' "$HELPERS"                                && pass "helpers uses Helm partials"      || fail "missing Helm partials in helpers"

echo "=================================================="
echo "E2E Helm Chart PASSED"
echo "=================================================="
