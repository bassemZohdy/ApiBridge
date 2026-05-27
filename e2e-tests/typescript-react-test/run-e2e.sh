#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: React Frontend (tsc)"
echo "=================================================="

# 1. Clean
rm -rf generated

# 2. Generate full React project
echo "Generating React frontend project..."
java -jar ../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=../../sample-schema.yaml \
  --cartridge=../../apibridge-cartridges/frontend/react \
  --output=generated

# 3. Verify key files exist
[ -f "generated/frontend/package.json" ]          || { echo "MISSING: package.json"; exit 1; }
[ -f "generated/frontend/src/ApiBridgeForm.tsx" ] || { echo "MISSING: ApiBridgeForm.tsx"; exit 1; }
[ -f "generated/frontend/src/api/bridgeApi.ts" ]  || { echo "MISSING: bridgeApi.ts"; exit 1; }

# 4. Install deps and type-check
echo "Installing dependencies..."
(cd generated/frontend && npm install --legacy-peer-deps --silent)

echo "Running strict TypeScript check..."
(cd generated/frontend && npx tsc --noEmit)

echo "=================================================="
echo "E2E React PASSED"
echo "=================================================="
