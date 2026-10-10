#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: Angular Production Build"
echo "=================================================="

# 1. Clean
rm -rf generated

# 2. Generate Angular frontend
echo "Generating Angular frontend..."
java -jar ../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=../../sample-schema.yaml \
  --cartridge=../../apibridge-cartridges/frontend/angular \
  --output=generated

# 3. Verify key files
[ -f "generated/frontend/package.json" ]              || { echo "MISSING: package.json"; exit 1; }
[ -f "generated/frontend/src/app/bridge-form.component.ts" ] || { echo "MISSING: bridge-form.component.ts"; exit 1; }
[ -f "generated/frontend/src/app/bridge-list.component.ts" ] || { echo "MISSING: bridge-list.component.ts"; exit 1; }
[ -f "generated/frontend/src/app/bridge-view.component.ts" ] || { echo "MISSING: bridge-view.component.ts"; exit 1; }

# 4. Install dependencies
echo "Installing dependencies..."
(cd generated/frontend && npm install --legacy-peer-deps --silent)

# 5. Production build (ng build --configuration production)
echo "Running production build (npm run build)..."
(cd generated/frontend && npm run build)

# 6. Verify dist output
[ -d "generated/frontend/dist" ] || { echo "MISSING: dist/ directory after build"; exit 1; }
[ -f "generated/frontend/dist/customer-onboarding-bridge-fe/browser/index.html" ] || { echo "MISSING: dist/index.html"; exit 1; }

echo "=================================================="
echo "E2E Angular Production Build PASSED"
echo "=================================================="
