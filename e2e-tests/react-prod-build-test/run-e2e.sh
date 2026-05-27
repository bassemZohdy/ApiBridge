#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: React Production Build"
echo "=================================================="

# 1. Clean
rm -rf generated

# 2. Generate React frontend
echo "Generating React frontend..."
java -jar ../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=../../sample-schema.yaml \
  --cartridge=../../apibridge-cartridges/frontend/react \
  --output=generated

# 3. Verify key files
[ -f "generated/frontend/package.json" ]          || { echo "MISSING: package.json"; exit 1; }
[ -f "generated/frontend/src/ApiBridgeForm.tsx" ] || { echo "MISSING: ApiBridgeForm.tsx"; exit 1; }
[ -f "generated/frontend/src/ApiBridgeList.tsx" ] || { echo "MISSING: ApiBridgeList.tsx"; exit 1; }
[ -f "generated/frontend/src/ApiBridgeView.tsx" ] || { echo "MISSING: ApiBridgeView.tsx"; exit 1; }

# 4. Install dependencies
echo "Installing dependencies..."
(cd generated/frontend && npm install --legacy-peer-deps --silent)

# 5. Production build (Vite)
echo "Running production build (npm run build)..."
(cd generated/frontend && npm run build)

# 6. Verify dist output
[ -d "generated/frontend/dist" ] || { echo "MISSING: dist/ directory after build"; exit 1; }
[ -f "generated/frontend/dist/index.html" ] || { echo "MISSING: dist/index.html"; exit 1; }

echo "=================================================="
echo "E2E React Production Build PASSED"
echo "=================================================="
