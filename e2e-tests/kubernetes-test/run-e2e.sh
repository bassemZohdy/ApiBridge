#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: Kubernetes Manifest Validation"
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

# 3. Generate k8s manifests (Spring Boot flavor)
echo "Generating Kubernetes manifests..."
java -jar "$JAR" \
  --schema="$SCHEMA" \
  --cartridge=../../apibridge-cartridges/backend/spring-boot \
  --cartridge=../../apibridge-cartridges/devops/k8s/kubernetes \
  --output="$GENERATED" \
  --be-flavor=spring-boot

# 4. Verify expected k8s files exist
echo "Verifying Kubernetes manifest structure..."

for f in deployment.yaml service.yaml configmap.yaml kustomization.yaml; do
  FILE="$GENERATED/$f"
  [ -f "$FILE" ] && pass "$f present" || fail "$f missing"
done

# 5. Validate deployment.yaml content
echo "Validating deployment.yaml..."
DEPLOYMENT="$GENERATED/deployment.yaml"

grep -q "kind: Deployment" "$DEPLOYMENT"         && pass "kind: Deployment"     || fail "missing kind: Deployment"
grep -q "name: customer-onboarding-bridge" "$DEPLOYMENT" && pass "deployment name"       || fail "missing deployment name"
grep -q "containerPort: 8080" "$DEPLOYMENT"       && pass "containerPort: 8080"  || fail "missing containerPort"
grep -q "runAsNonRoot: true" "$DEPLOYMENT"        && pass "runAsNonRoot"         || fail "missing runAsNonRoot"
grep -q "runAsUser: 1001" "$DEPLOYMENT"           && pass "runAsUser: 1001"      || fail "missing runAsUser"
grep -q "actuator/health/liveness" "$DEPLOYMENT"  && pass "Spring Boot liveness" || fail "missing Spring Boot liveness probe"
grep -q "actuator/health/readiness" "$DEPLOYMENT" && pass "Spring Boot readiness" || fail "missing Spring Boot readiness probe"
grep -q "drop:" "$DEPLOYMENT"                     && pass "capabilities drop"    || fail "missing capabilities drop"
grep -q "name: ${id}-config" "$DEPLOYMENT" 2>/dev/null || true
grep -q "customer-onboarding-bridge-config" "$DEPLOYMENT" && pass "configMapRef" || fail "missing configMapRef"

# 6. Validate service.yaml content
echo "Validating service.yaml..."
SERVICE="$GENERATED/service.yaml"

grep -q "kind: Service" "$SERVICE"                && pass "kind: Service"        || fail "missing kind: Service"
grep -q "type: ClusterIP" "$SERVICE"              && pass "ClusterIP type"       || fail "missing ClusterIP"
grep -q "targetPort: http" "$SERVICE"             && pass "targetPort: http"     || fail "missing targetPort"

# 7. Validate configmap.yaml content
echo "Validating configmap.yaml..."
CONFIGMAP="$GENERATED/configmap.yaml"

grep -q "kind: ConfigMap" "$CONFIGMAP"            && pass "kind: ConfigMap"      || fail "missing kind: ConfigMap"
grep -q "MOCK_MODE" "$CONFIGMAP"                  && pass "MOCK_MODE"            || fail "missing MOCK_MODE"
grep -q "SERVER_PORT" "$CONFIGMAP"                && pass "SERVER_PORT (Spring)" || fail "missing SERVER_PORT"
grep -q "AUTH_SERVER_URL" "$CONFIGMAP"            && pass "AUTH_SERVER_URL"      || fail "missing AUTH_SERVER_URL"
grep -q "BACKEND_URL_" "$CONFIGMAP"               && pass "per-endpoint URLs"    || fail "missing per-endpoint URLs"
grep -q "MANAGEMENT_TRACING_ENABLED" "$CONFIGMAP" && pass "telemetry config"     || fail "missing telemetry config"

# 8. Validate kustomization.yaml content
echo "Validating kustomization.yaml..."
KUSTOMIZATION="$GENERATED/kustomization.yaml"

grep -q "kind: Kustomization" "$KUSTOMIZATION"    && pass "kind: Kustomization"  || fail "missing kind: Kustomization"
grep -q "configmap.yaml" "$KUSTOMIZATION"         && pass "configmap resource"   || fail "missing configmap resource"
grep -q "deployment.yaml" "$KUSTOMIZATION"        && pass "deployment resource"  || fail "missing deployment resource"
grep -q "service.yaml" "$KUSTOMIZATION"           && pass "service resource"     || fail "missing service resource"
grep -q "managed-by: apibridge" "$KUSTOMIZATION"  && pass "commonLabels"         || fail "missing commonLabels"

# 9. Re-generate with Quarkus flavor and verify health probes change
echo "Verifying Quarkus flavor..."
rm -rf "$GENERATED"
java -jar "$JAR" \
  --schema="$SCHEMA" \
  --cartridge=../../apibridge-cartridges/devops/k8s/kubernetes \
  --output="$GENERATED" \
  --be-flavor=quarkus

QUARKUS_DEPLOYMENT="$GENERATED/deployment.yaml"
grep -q "q/health/live" "$QUARKUS_DEPLOYMENT"         && pass "Quarkus liveness"    || fail "missing Quarkus liveness"
grep -q "q/health/ready" "$QUARKUS_DEPLOYMENT"        && pass "Quarkus readiness"   || fail "missing Quarkus readiness"
grep -q "q/health/started" "$QUARKUS_DEPLOYMENT"      && pass "Quarkus startup"     || fail "missing Quarkus startup"
grep -q "QUARKUS_HTTP_PORT" "$GENERATED/configmap.yaml" && pass "Quarkus port"       || fail "missing QUARKUS_HTTP_PORT"

echo "=================================================="
echo "E2E Kubernetes PASSED"
echo "=================================================="
