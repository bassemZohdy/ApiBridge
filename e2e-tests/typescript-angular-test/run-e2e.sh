#!/bin/bash
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Running E2E: Angular Frontend (tsc)"
echo "=================================================="

# 1. Clean
rm -rf generated

# 2. Generate full Angular project
echo "Generating Angular frontend project..."
java -jar ../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=../../sample-schema.yaml \
  --cartridge=../../apibridge-cartridges/frontend/angular \
  --output=generated

# 3. Verify key files exist
[ -f "generated/frontend/package.json" ]                                     || { echo "MISSING: package.json"; exit 1; }
[ -f "generated/frontend/src/app/bridge-form.component.ts" ]                 || { echo "MISSING: bridge-form.component.ts"; exit 1; }
[ -f "generated/frontend/src/app/bridge-api.service.ts" ]                    || { echo "MISSING: bridge-api.service.ts"; exit 1; }

# 4. Install deps and type-check
echo "Installing dependencies..."
(cd generated/frontend && npm install --legacy-peer-deps --silent)

echo "Running strict TypeScript check..."
(cd generated/frontend && npx tsc --noEmit)

echo "=================================================="
echo "E2E Angular PASSED"
echo "=================================================="
