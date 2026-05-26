#!/bin/bash
set -e

# Change directory to the script's physical location
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "🚀 Running E2E: React TS Cartridge Pipeline"
echo "=================================================="

# 1. Clean previous generated assets
echo "🧹 Cleaning previous artifacts..."
rm -rf generated src && mkdir -p src

# 2. Execute the generator for React cartridge
echo "⚡ Generating React cartridge assets..."
java -jar ../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=../../sample-schema.yaml \
  --cartridge=../../apibridge-cartridges/frontend-react \
  --output=generated

# 3. Integrate generated files into TypeScript source directory
echo "📥 Merging React assets..."
cp generated/ApiBridgeForm.tsx src/ReactApiBridgeForm.tsx

# 4. Resolve dependencies and trigger compiler checks
echo "📦 Installing React type definition dependencies..."
npm install --legacy-peer-deps

echo "🛠️ Executing strict React TypeScript compiler check (tsc --noEmit)..."
npx tsc --noEmit

echo "=================================================="
echo "✓ E2E: React TS Cartridge Pipeline SUCCESSFUL!"
echo "=================================================="
