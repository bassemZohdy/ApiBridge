#!/bin/bash
# Verifies that the basePath and endpoint paths from the schema are present in
# all generated backend and frontend artifacts — catches template bugs where a
# cartridge emits a wrong or missing path.
set -e

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "Backend-Frontend Contract Symmetry Check"
echo "=================================================="

SCHEMA="../sample-schema.yaml"

SPRING_CONTROLLER="maven-spring-boot-test/generated/backend/src/main/java/com/apibridge/generated/BridgeController.java"
QUARKUS_RESOURCE="maven-quarkus-test/generated/backend/src/main/java/com/apibridge/generated/BridgeResource.java"
ANGULAR_SERVICE="typescript-angular-test/generated/frontend/src/app/bridge-api.service.ts"
REACT_API="typescript-react-test/generated/frontend/src/api/bridgeApi.ts"
VUE_API="typescript-vue-test/generated/frontend/src/api/bridgeApi.ts"

# 1. Verify all artifacts were generated
echo "Checking artifact existence..."
for FILE in "$SPRING_CONTROLLER" "$QUARKUS_RESOURCE" "$ANGULAR_SERVICE" "$REACT_API" "$VUE_API"; do
  if [ ! -f "$FILE" ]; then
    echo "MISSING: $FILE"
    exit 1
  fi
done
echo "  All artifacts present."

# 2. Extract base path and endpoint paths from the schema
BASE_PATH=$(grep 'basePath:' "$SCHEMA" | awk '{print $2}' | tr -d '"')
ENDPOINT_PATHS=()
while IFS= read -r line; do
  ENDPOINT_PATHS+=("$line")
done < <(grep '^\s*- path:' "$SCHEMA" | awk '{print $3}' | tr -d '"')

echo "Schema basePath   : $BASE_PATH"
echo "Schema endpoints  : ${ENDPOINT_PATHS[*]}"

# 3. Verify basePath appears in every artifact
echo "Checking basePath symmetry..."
for FILE in "$SPRING_CONTROLLER" "$QUARKUS_RESOURCE" "$ANGULAR_SERVICE" "$REACT_API" "$VUE_API"; do
  if grep -q "$BASE_PATH" "$FILE"; then
    echo "  ✓ $(basename "$FILE")"
  else
    echo "  ✗ basePath '$BASE_PATH' not found in $FILE"
    exit 1
  fi
done

# 4. Verify each endpoint path appears in every artifact
echo "Checking endpoint path symmetry..."
for EP in "${ENDPOINT_PATHS[@]}"; do
  for FILE in "$SPRING_CONTROLLER" "$QUARKUS_RESOURCE" "$ANGULAR_SERVICE" "$REACT_API" "$VUE_API"; do
    if grep -q "$EP" "$FILE"; then
      echo "  ✓ $EP  →  $(basename "$FILE")"
    else
      echo "  ✗ endpoint '$EP' not found in $FILE"
      exit 1
    fi
  done
done

echo "=================================================="
echo "Contract symmetry: ALL PASSED"
echo "=================================================="
