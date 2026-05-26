#!/bin/bash
set -e

# Change directory to the script's physical location
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "🚀 Running E2E: Angular TS Cartridge Pipeline"
echo "=================================================="

# 1. Clean previous generated assets
echo "🧹 Cleaning previous artifacts..."
rm -rf generated src && mkdir -p src

# 2. Execute the generator for Angular cartridge
echo "⚡ Generating Angular cartridge assets..."
java -jar ../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=../../sample-schema.yaml \
  --cartridge=../../apibridge-cartridges/frontend-angular \
  --output=generated

# 3. Integrate generated files into TypeScript source directory
echo "📥 Merging Angular assets..."
cp generated/bridge-form.component.ts src/AngularBridgeFormComponent.ts

# 4. Resolve dependencies and trigger compiler checks
echo "📦 Installing Angular type definition dependencies..."
npm install --legacy-peer-deps

echo "🛠️ Executing strict Angular TypeScript compiler check (tsc --noEmit)..."
npx tsc --noEmit

echo "=================================================="
echo "✓ E2E: Angular TS Cartridge Pipeline SUCCESSFUL!"
echo "=================================================="
