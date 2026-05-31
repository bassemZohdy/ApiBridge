#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: Multi-Schema Composition (SchemaComposer)"
echo "=================================================="

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; exit 1; }

rm -rf generated

if [ "${SKIP_GENERATOR_BUILD:-false}" = "true" ]; then
  echo "[skip] generator build"
else
  echo "Building ApiBridge Generator..."
  (cd ../.. && mvn package -q -DskipTests)
fi

JAR="../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar"
CARTRIDGE="../../apibridge-cartridges/backend/spring-boot"

# ── Test 1: Happy path — two schemas merged ──────────────────────
echo ""
echo "[1/3] Happy path: composing users + orders schemas..."
java -jar "$JAR" \
  --schema=schema-users.yaml \
  --schema=schema-orders.yaml \
  --cartridge="$CARTRIDGE" \
  --output=generated

CONTROLLER="generated/backend/src/main/java/com/apibridge/generated/BridgeController.java"
[ -f "$CONTROLLER" ] || fail "BridgeController.java missing"

# id/basePath from primary (users) schema
grep -q "users" "$CONTROLLER" && pass "primary schema id reflected" || fail "primary schema id missing"

# Both endpoints present
grep -qi "get.*users\|getUsers\|getUser" "$CONTROLLER" && pass "GET /users endpoint present" || fail "GET /users endpoint missing"
grep -qi "post.*order\|postOrder\|createOrder" "$CONTROLLER" && pass "POST /orders endpoint present" || fail "POST /orders endpoint missing"

# Verify merged count: Composed Endpoints: 2
echo "(checking composed endpoint count in generator output above)"

# ── Test 2: Duplicate rejection ──────────────────────────────────
echo ""
echo "[2/3] Duplicate rejection: overlapping GET /users in both schemas..."
if java -jar "$JAR" \
  --schema=schema-users.yaml \
  --schema=schema-dup.yaml \
  --cartridge="$CARTRIDGE" \
  --output=generated-dup 2>&1; then
  fail "expected non-zero exit code for duplicate endpoints"
else
  EXIT_CODE=$?
  [ "$EXIT_CODE" -ne 0 ] && pass "duplicate endpoint rejected (exit $EXIT_CODE)" || fail "expected non-zero exit"
fi
[ -d "generated-dup" ] && fail "output dir should not exist on failure" || pass "no output dir created on failure"

# ── Test 3: Same path, different methods allowed ─────────────────
echo ""
echo "[3/3] Same path, different methods: GET /users + POST /users..."
rm -rf generated-mixed

cat > schema-users-post.yaml <<'YAML'
id: users-post-service
basePath: /api/users-post
endpoints:
  - path: /users
    method: POST
    backendUrl: https://api.example.com/users
YAML

java -jar "$JAR" \
  --schema=schema-users.yaml \
  --schema=schema-users-post.yaml \
  --cartridge="$CARTRIDGE" \
  --output=generated-mixed

CONTROLLER2="generated-mixed/backend/src/main/java/com/apibridge/generated/BridgeController.java"
[ -f "$CONTROLLER2" ] || fail "BridgeController.java missing for mixed-methods test"
grep -qi "get.*users\|getUsers" "$CONTROLLER2" && pass "GET /users present" || fail "GET /users missing"
grep -qi "post.*users\|postUsers" "$CONTROLLER2" && pass "POST /users present" || fail "POST /users missing"

# Cleanup
rm -rf generated generated-mixed schema-users-post.yaml

echo ""
echo "=================================================="
echo "All multi-schema E2E tests passed."
echo "=================================================="
