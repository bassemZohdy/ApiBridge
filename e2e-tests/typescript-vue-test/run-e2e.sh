#!/bin/bash
set -e

# Change directory to the script's physical location
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "🚀 Running E2E: Vue TS Cartridge Pipeline"
echo "=================================================="

# 1. Clean previous generated assets
echo "🧹 Cleaning previous artifacts..."
rm -rf generated src && mkdir -p src

# 2. Execute the generator for Vue cartridge
echo "⚡ Generating Vue cartridge assets..."
java -jar ../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=../../sample-schema.yaml \
  --cartridge=../../apibridge-cartridges/frontend-vue \
  --output=generated

# 3. Integrate generated files into TypeScript source directory by extracting the script setup block
echo "✂️ Extracting TypeScript setup block from Vue Single File Component..."
sed -n '/<script lang="ts">/,/<\/script>/p' generated/ApiBridgeForm.vue | sed '1d;$d' > src/VueApiBridgeForm.ts

# 4. Resolve dependencies and trigger compiler checks
echo "📦 Installing Vue type definition dependencies..."
npm install --legacy-peer-deps

echo "🛠️ Executing strict Vue TypeScript compiler check (tsc --noEmit)..."
npx tsc --noEmit

echo "=================================================="
echo "✓ E2E: Vue TS Cartridge Pipeline SUCCESSFUL!"
echo "=================================================="
