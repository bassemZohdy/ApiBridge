#!/bin/bash
set -e

# Change directory to the script's physical location
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "🚀 Running E2E Integration Test: Quarkus Pipeline"
echo "=================================================="

# 1. Clean previous generated artifacts
echo "🧹 Cleaning previous artifacts..."
rm -rf generated src/main/java/com/apibridge/generated src/main/java/CustomerOnboardingBridgeResource.java

# 2. Build the generator engine fat jar from parent root (if not already done)
echo "📦 Building ApiBridge Generator Engine..."
(cd ../.. && mvn package)

# 3. Execute the generator using backend-quarkus cartridge
echo "⚡ Executing ApiBridge Generator CLI with Quarkus cartridge..."
java -jar ../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=../../sample-schema.yaml \
  --cartridge=../../apibridge-cartridges/backend-quarkus \
  --output=generated

# 4. Integrate generated JAX-RS Resource, renaming it to match the class name
echo "📥 Merging generated JAX-RS Resource into Maven src root..."
mkdir -p src/main/java
cp generated/Resource.java src/main/java/CustomerOnboardingBridgeResource.java

# 5. Compile Maven test project to verify JAX-RS correctness
echo "🛠️ Compiling Quarkus integration project..."
mvn clean compile

echo "=================================================="
echo "✓ E2E Integration Test: Quarkus Pipeline SUCCESSFUL!"
echo "=================================================="
