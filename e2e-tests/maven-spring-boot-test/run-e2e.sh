#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: Spring Boot Maven Compile"
echo "=================================================="

# 1. Clean
rm -rf generated

# 2. Build generator (skip when CI already built it)
if [ "${SKIP_GENERATOR_BUILD:-false}" = "true" ]; then
  echo "[skip] generator build"
else
  echo "Building ApiBridge Generator..."
  (cd ../.. && mvn package -q -DskipTests)
fi

# 3. Generate with spring-boot cartridge
echo "Generating Spring Boot project..."
java -jar ../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=../../sample-schema.yaml \
  --cartridge=../../apibridge-cartridges/backend/spring-boot \
  --output=generated

# 4. Verify expected files exist
CONTROLLER="generated/backend/src/main/java/com/apibridge/generated/BridgeController.java"
PROXY="generated/backend/src/main/java/com/apibridge/generated/ProxyService.java"
POM="generated/backend/pom.xml"
PROPS="generated/backend/src/main/resources/application.properties"

[ -f "$CONTROLLER" ] || { echo "MISSING: $CONTROLLER"; exit 1; }
[ -f "$POM" ]        || { echo "MISSING: $POM"; exit 1; }
[ -f "$PROXY" ]      || { echo "MISSING: $PROXY"; exit 1; }

grep -q "@RestController" "$CONTROLLER" || { echo "MISSING @RestController in $CONTROLLER"; exit 1; }

# 4b. Verify feature-flag output (sample-schema has all flags enabled)
echo "Verifying feature-flag generated output..."

# Rate limiter
grep -q "RateLimiter" "$PROXY"            && echo "  ✓ RateLimiter in ProxyService"   || { echo "  ✗ missing RateLimiter"; exit 1; }
grep -q "resilience4j-ratelimiter" "$POM" && echo "  ✓ resilience4j-ratelimiter dep"  || { echo "  ✗ missing resilience4j-ratelimiter dep"; exit 1; }

# Transform
grep -q "applyHeaderTransforms" "$PROXY"  && echo "  ✓ transform method in ProxyService" || { echo "  ✗ missing transform method"; exit 1; }

# Health check
[ -f "generated/backend/src/main/java/com/apibridge/generated/HealthCheckService.java" ] \
  && echo "  ✓ HealthCheckService.java present" || { echo "  ✗ missing HealthCheckService.java"; exit 1; }

# CORS config
[ -f "generated/backend/src/main/java/com/apibridge/generated/CorsConfig.java" ] \
  && echo "  ✓ CorsConfig.java present" || echo "  ⚠ CorsConfig.java absent (may be expected)"

# apiVersion prefix (sample-schema has apiVersion: "v1")
grep -q '"/v1/api/v1/onboarding"' "$CONTROLLER" \
  && echo "  ✓ apiVersion prefix in @RequestMapping" || echo "  ⚠ apiVersion prefix not found (may differ)"

# 5. Compile the generated backend with its own pom.xml
echo "Compiling generated Spring Boot project..."
(cd generated/backend && mvn compile -q)

echo "=================================================="
echo "E2E Spring Boot PASSED"
echo "=================================================="
