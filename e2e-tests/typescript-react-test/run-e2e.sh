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

# 3b. Verify Service Worker generated (enableOfflineSupport: true in sample-schema)
echo "Verifying Service Worker..."
SW_FILE="generated/frontend/public/sw.js"
[ -f "$SW_FILE" ] && echo "  ✓ sw.js present" || { echo "  ✗ sw.js missing"; exit 1; }
grep -q "self.addEventListener" "$SW_FILE" && echo "  ✓ sw.js contains addEventListener" || { echo "  ✗ sw.js missing addEventListener"; exit 1; }

# 3c. Verify Search UI generated (enableSearch: true in sample-schema)
echo "Verifying Search UI..."
LIST_FILE="generated/frontend/src/ApiBridgeList.tsx"
[ -f "$LIST_FILE" ] && echo "  ✓ ApiBridgeList.tsx present" || { echo "  ✗ ApiBridgeList.tsx missing"; exit 1; }
grep -q "apib-search-bar" "$LIST_FILE" && echo "  ✓ search bar class present" || { echo "  ✗ missing apib-search-bar"; exit 1; }
grep -q "searchTerm" "$LIST_FILE" && echo "  ✓ searchTerm state present" || { echo "  ✗ missing searchTerm"; exit 1; }

# 4. Install deps and type-check
echo "Installing dependencies..."
(cd generated/frontend && npm install --legacy-peer-deps --silent)

echo "Running strict TypeScript check..."
(cd generated/frontend && npx tsc --noEmit)

echo "=================================================="
echo "E2E React PASSED"
echo "=================================================="
