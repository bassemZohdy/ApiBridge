#!/bin/bash
set -e

# Change directory to the script's physical location
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "🚀 Running E2E Integration Test: Maven Pipeline"
echo "=================================================="

# 1. Clean previous generated artifacts
echo "🧹 Cleaning previous artifacts..."
rm -rf generated src/main/java/CustomerOnboardingBridgeController.java

# 2. Build the generator engine fat jar (skip when already built by CI)
if [ "${SKIP_GENERATOR_BUILD:-false}" = "true" ]; then
  echo "⏩ Skipping generator build (SKIP_GENERATOR_BUILD=true)"
else
  echo "📦 Building ApiBridge Generator Engine..."
  (cd ../.. && mvn package -q -DskipTests)
fi

# 3. Execute the generator using Spring Boot cartridge
echo "⚡ Executing ApiBridge Generator CLI with Spring Boot cartridge..."
java -jar ../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=../../sample-schema.yaml \
  --cartridge=../../apibridge-cartridges/backend-spring-boot \
  --output=generated

# 4. Integrate generated Controller, renaming it to match the class name
echo "📥 Merging generated Controller into Maven src root..."
mkdir -p src/main/java
cp generated/Controller.java src/main/java/CustomerOnboardingBridgeController.java

# 5. Compile Maven test project to verify compiler/native readiness
echo "🛠️ Compiling Maven integration project..."
mvn clean compile

echo "=================================================="
echo "✓ E2E Integration Test: Maven Pipeline SUCCESSFUL!"
echo "=================================================="
