#!/bin/bash
# E2E for composable fullstack Docker output.
# Generates a project from multiple cartridges, verifies structure,
# builds the Docker image, and tests MOCK_MODE + BLOCK_TRAFFIC.

set -euo pipefail
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

GENERATED_DIR="generated"
SCHEMA="../../sample-schema.yaml"
JAR="../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar"
IMAGE_TAG="apibridge-e2e-fullstack:test"
CONTAINER_NAME="apibridge-e2e-run"
HOST_PORT=18080

BE_FLAVOR="${BE_FLAVOR:-spring-boot}"
FE_FLAVOR="${FE_FLAVOR:-react}"

HEALTH_PATH="/actuator/health/liveness"
if [ "$BE_FLAVOR" = "quarkus" ]; then
  HEALTH_PATH="/q/health/live"
fi

BASE_PATH="/api/v1/onboarding"
TEST_ENDPOINT="/initiate"

pass() { echo "  ✓ $*"; }
fail() { echo "  ✗ $*"; exit 1; }

cleanup() {
  docker rm -f "$CONTAINER_NAME" &>/dev/null || true
  docker rmi "$IMAGE_TAG" &>/dev/null || true
}

wait_healthy() {
  local url="$1"
  local timeout=180
  local interval=5
  local elapsed=0
  echo "  Waiting for $url (up to ${timeout}s)..."
  until curl -sf "$url" &>/dev/null; do
    sleep $interval
    elapsed=$(( elapsed + interval ))
    if [ $elapsed -ge $timeout ]; then
      echo "  ✗ Service did not become healthy within ${timeout}s"
      docker logs "$CONTAINER_NAME" --tail 40
      exit 1
    fi
    echo "    ...${elapsed}s"
  done
  pass "Service healthy at ${url}"
}

run_generator() {
  local out="$1"; shift
  local extra_args=("$@")
  rm -rf "$out"
  java -jar "$JAR" \
    --schema="$SCHEMA" \
    --cartridge="../../apibridge-cartridges/backend/${BE_FLAVOR}" \
    --cartridge="../../apibridge-cartridges/frontend/${FE_FLAVOR}" \
    --cartridge="../../apibridge-cartridges/devops/dockerfile" \
    "${extra_args[@]}" \
    --output="$out" \
    --be-flavor="$BE_FLAVOR" \
    --fe-flavor="$FE_FLAVOR"
}

echo "=================================================="
echo "Running E2E: Fullstack Docker (BE=$BE_FLAVOR FE=$FE_FLAVOR)"
echo "=================================================="

# 1. Build generator (skip when CI already built it)
echo ""
if [ "${SKIP_GENERATOR_BUILD:-false}" = "true" ]; then
  echo "[1/8] Skipping generator build"
else
  echo "[1/8] Building ApiBridge Generator..."
  (cd ../.. && mvn package -q -DskipTests)
fi

# 2. Generate BE+FE+Dockerfile only — no deployment cartridge
echo ""
echo "[2/8] Generation check: dockerfile cartridge only (no docker-compose)..."
run_generator "$GENERATED_DIR"
[ -f "$GENERATED_DIR/Dockerfile" ]          && pass "Dockerfile present" \
  || fail "Dockerfile missing"
[ ! -f "$GENERATED_DIR/docker-compose.yml" ] && pass "docker-compose.yml absent" \
  || fail "docker-compose.yml should not be present"
[ ! -d "$GENERATED_DIR/k8s" ]               && pass "k8s/ absent" \
  || fail "k8s/ should not be present"

# 3. Generate with docker-compose cartridge added
echo ""
echo "[3/8] Generation check: + docker-compose cartridge..."
run_generator "$GENERATED_DIR" --cartridge="../../apibridge-cartridges/devops/docker-compose"
[ -f "$GENERATED_DIR/docker-compose.yml" ]  && pass "docker-compose.yml present" \
  || fail "docker-compose.yml missing"
[ ! -d "$GENERATED_DIR/k8s" ]               && pass "k8s/ absent (not kubernetes)" \
  || fail "k8s/ should not be present"

# 4. Verify backend subtree
echo ""
echo "[4/8] Verifying backend output (BE=$BE_FLAVOR)..."
if [ "$BE_FLAVOR" = "quarkus" ]; then
  CONTROLLER_FILE="src/main/java/com/apibridge/generated/BridgeResource.java"
  CONTROLLER_ANNOTATION="@Path"
else
  CONTROLLER_FILE="src/main/java/com/apibridge/generated/BridgeController.java"
  CONTROLLER_ANNOTATION="@RestController"
fi
for f in pom.xml \
         "$CONTROLLER_FILE" \
         src/main/java/com/apibridge/generated/ProxyService.java \
         src/main/resources/application.properties; do
  [ -f "$GENERATED_DIR/backend/$f" ] && pass "backend/$f" || fail "Missing backend/$f"
done
grep -q "$CONTROLLER_ANNOTATION" "$GENERATED_DIR/backend/$CONTROLLER_FILE" \
  && pass "Controller has $CONTROLLER_ANNOTATION" \
  || fail "Controller missing $CONTROLLER_ANNOTATION"

# 5. Verify frontend subtree
echo ""
echo "[5/8] Verifying frontend output (FE=$FE_FLAVOR)..."
if [ "$FE_FLAVOR" = "angular" ]; then
  MAIN_FILE="src/main.ts"
else
  MAIN_FILE="src/main.tsx"
fi
for f in package.json "$MAIN_FILE"; do
  [ -f "$GENERATED_DIR/frontend/$f" ] && pass "frontend/$f" || fail "Missing frontend/$f"
done

# 6. Docker build
if ! command -v docker &>/dev/null || ! docker info &>/dev/null 2>&1; then
  echo ""
  echo "[6-8/8] Docker not available — skipping container tests"
  echo "=================================================="
  echo "E2E Fullstack (no Docker) PASSED"
  echo "=================================================="
  exit 0
fi

echo ""
echo "[6/8] Docker build..."
cleanup
(cd "$GENERATED_DIR" && docker build --no-cache -t "$IMAGE_TAG" .)
pass "Docker image built: $IMAGE_TAG"

# 7. Test MOCK_MODE
echo ""
echo "[7/8] Container runtime test (MOCK_MODE=true)..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "${HOST_PORT}:8080" \
  -e MOCK_MODE=true \
  -e BLOCK_TRAFFIC=false \
  "$IMAGE_TAG"

wait_healthy "http://localhost:${HOST_PORT}${HEALTH_PATH}"

MOCK_RESPONSE=$(curl -sf -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}' \
  "http://localhost:${HOST_PORT}${BASE_PATH}${TEST_ENDPOINT}" || echo "")

echo "$MOCK_RESPONSE" | grep -q '"status":"mock"' \
  && pass "MOCK_MODE: got mock response" \
  || fail "MOCK_MODE: unexpected response: $MOCK_RESPONSE"

docker rm -f "$CONTAINER_NAME" &>/dev/null

# 8. Test BLOCK_TRAFFIC
echo ""
echo "[8/8] Container runtime test (BLOCK_TRAFFIC=true)..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "${HOST_PORT}:8080" \
  -e MOCK_MODE=false \
  -e BLOCK_TRAFFIC=true \
  "$IMAGE_TAG"

wait_healthy "http://localhost:${HOST_PORT}${HEALTH_PATH}"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d '{}' \
  "http://localhost:${HOST_PORT}${BASE_PATH}${TEST_ENDPOINT}" || echo "000")

[ "$HTTP_STATUS" = "503" ] \
  && pass "BLOCK_TRAFFIC: got 503" \
  || fail "BLOCK_TRAFFIC: expected 503, got $HTTP_STATUS"

cleanup

echo ""
echo "=================================================="
echo "E2E Fullstack Docker PASSED"
echo "=================================================="
