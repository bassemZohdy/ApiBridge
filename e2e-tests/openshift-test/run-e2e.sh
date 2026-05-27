#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: OpenShift Manifest Validation"
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

# 3. Generate OpenShift manifests
echo "Generating OpenShift manifests..."
java -jar "$JAR" \
  --schema="$SCHEMA" \
  --cartridge=../../apibridge-cartridges/backend/spring-boot \
  --cartridge=../../apibridge-cartridges/devops/k8s/openshift \
  --output="$GENERATED" \
  --be-flavor=spring-boot

# 4. Verify expected files exist
echo "Verifying OpenShift manifest structure..."

for f in deployment.yaml service.yaml configmap.yaml kustomization.yaml route.yaml; do
  FILE="$GENERATED/$f"
  [ -f "$FILE" ] && pass "$f present" || fail "$f missing"
done

# 5. Validate route.yaml content (OpenShift-specific)
echo "Validating route.yaml..."
ROUTE="$GENERATED/route.yaml"

grep -q "kind: Route" "$ROUTE"                     && pass "kind: Route"          || fail "missing kind: Route"
grep -q "route.openshift.io" "$ROUTE"              && pass "OpenShift API group"  || fail "missing OpenShift API group"
grep -q "name: customer-onboarding-bridge" "$ROUTE" && pass "route name"           || fail "missing route name"
grep -q "kind: Service" "$ROUTE"                   && pass "routes to Service"    || fail "missing Service target"
grep -q "termination: edge" "$ROUTE"               && pass "TLS edge termination" || fail "missing TLS termination"
grep -q "targetPort: http" "$ROUTE"                && pass "targetPort: http"     || fail "missing targetPort"

# 6. Validate kustomization.yaml includes route
echo "Validating kustomization.yaml..."
KUSTOMIZATION="$GENERATED/kustomization.yaml"

grep -q "route.yaml" "$KUSTOMIZATION"              && pass "route in resources"   || fail "missing route in resources"
grep -q "configmap.yaml" "$KUSTOMIZATION"          && pass "configmap resource"   || fail "missing configmap resource"
grep -q "deployment.yaml" "$KUSTOMIZATION"         && pass "deployment resource"  || fail "missing deployment resource"
grep -q "service.yaml" "$KUSTOMIZATION"            && pass "service resource"     || fail "missing service resource"

echo "=================================================="
echo "E2E OpenShift PASSED"
echo "=================================================="
