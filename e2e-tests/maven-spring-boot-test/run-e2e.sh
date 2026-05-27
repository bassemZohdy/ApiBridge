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
POM="generated/backend/pom.xml"
[ -f "$CONTROLLER" ] || { echo "MISSING: $CONTROLLER"; exit 1; }
[ -f "$POM" ]        || { echo "MISSING: $POM"; exit 1; }
grep -q "@RestController" "$CONTROLLER" || { echo "MISSING @RestController in $CONTROLLER"; exit 1; }

# 5. Compile the generated backend with its own pom.xml
echo "Compiling generated Spring Boot project..."
(cd generated/backend && mvn compile -q)

echo "=================================================="
echo "E2E Spring Boot PASSED"
echo "=================================================="
