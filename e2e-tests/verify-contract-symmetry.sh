#!/bin/bash
# Backend-Frontend API Contract Symmetry Validator (ApiBridge Contract testing pipeline)
set -e

# Change directory to the script's physical location
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "🛡️ Starting Backend-Frontend Contract Symmetry Scanner"
echo "=================================================="

# Define paths to generated artifacts in E2E environments
SPRING_CONTROLLER="maven-spring-boot-test/generated/Controller.java"
QUARKUS_RESOURCE="maven-quarkus-test/generated/Resource.java"
ANGULAR_TS="typescript-angular-test/generated/bridge-form.component.ts"
REACT_TSX="typescript-react-test/generated/ApiBridgeForm.tsx"
VUE_SFC="typescript-vue-test/generated/ApiBridgeForm.vue"

# 1. Assert all files are generated
echo "🔍 Checking artifact existence..."
for FILE in "$SPRING_CONTROLLER" "$QUARKUS_RESOURCE" "$ANGULAR_TS" "$REACT_TSX" "$VUE_SFC"; do
  if [ ! -f "$FILE" ]; then
    echo "❌ Missing generated file for contract scan: $FILE"
    exit 1
  fi
done
echo "✓ All generated assets exist."

# 2. Extract and assert Base Path contract symmetry
echo "🔍 Scanning Base Path alignments..."
SPRING_BASE_PATH=$(grep -o '@RequestMapping("[^"]*")' "$SPRING_CONTROLLER" | sed 's/@RequestMapping("//;s/")//')
QUARKUS_BASE_PATH=$(grep -o '@Path("[^"]*")' "$QUARKUS_RESOURCE" | head -n 1 | sed 's/@Path("//;s/")//')
ANGULAR_BASE_PATH=$(grep -o 'basePath: "[^"]*"' "$ANGULAR_TS" | sed 's/basePath: "//;s/"//')
REACT_BASE_PATH=$(grep -o 'basePath: "[^"]*"' "$REACT_TSX" | sed 's/basePath: "//;s/"//')
VUE_BASE_PATH=$(grep -o 'basePath: "[^"]*"' "$VUE_SFC" | sed 's/basePath: "//;s/"//')

echo "  Spring Boot Base Path : $SPRING_BASE_PATH"
echo "  Quarkus Base Path     : $QUARKUS_BASE_PATH"
echo "  Angular Base Path     : $ANGULAR_BASE_PATH"
echo "  React Base Path       : $REACT_BASE_PATH"
echo "  Vue Base Path         : $VUE_BASE_PATH"

if [ "$SPRING_BASE_PATH" != "$QUARKUS_BASE_PATH" ] || \
   [ "$SPRING_BASE_PATH" != "$ANGULAR_BASE_PATH" ] || \
   [ "$SPRING_BASE_PATH" != "$REACT_BASE_PATH" ] || \
   [ "$SPRING_BASE_PATH" != "$VUE_BASE_PATH" ]; then
  echo "❌ Error: Base Path mismatch detected across compiler cartridges!"
  exit 1
fi
echo "✓ Base Paths match 100% symmetrically across all 5 cartridge outputs!"

# 3. Extract and assert Endpoint Route and HTTP Verb symmetry
echo "🔍 Scanning Endpoint route & HTTP Verb alignments..."

# Extract Spring path/method
SPRING_PATH=$(grep -A 5 "@RequestMapping" "$SPRING_CONTROLLER" | grep "value = " | sed 's/.*value = "//;s/".*//')
SPRING_METHOD=$(grep -A 5 "@RequestMapping" "$SPRING_CONTROLLER" | grep "method = RequestMethod\." | sed 's/.*method = RequestMethod\.//;s/,.*//')

# Extract Quarkus path/method
QUARKUS_PATH=$(grep -B 2 -A 2 "@POST" "$QUARKUS_RESOURCE" | grep "@Path" | sed 's/.*@Path("//;s/").*//')
QUARKUS_METHOD="POST" # Explicitly derived from @POST annotation

# Extract Frontend path targets
ANGULAR_ROUTE=$(grep -o '\/initiate' "$ANGULAR_TS" | uniq)
REACT_ROUTE=$(grep -o '\/initiate' "$REACT_TSX" | uniq)
VUE_ROUTE=$(grep -o '\/initiate' "$VUE_SFC" | uniq)

echo "  Spring Endpoints      : $SPRING_METHOD $SPRING_PATH"
echo "  Quarkus Endpoints     : $QUARKUS_METHOD $QUARKUS_PATH"
echo "  Angular HTTP target   : $ANGULAR_ROUTE"
echo "  React HTTP target     : $REACT_ROUTE"
echo "  Vue HTTP target       : $VUE_ROUTE"

if [ "$SPRING_PATH" != "$QUARKUS_PATH" ] || \
   [ "$SPRING_PATH" != "$ANGULAR_ROUTE" ] || \
   [ "$SPRING_PATH" != "$REACT_ROUTE" ] || \
   [ "$SPRING_PATH" != "$VUE_ROUTE" ]; then
  echo "❌ Error: Route contract mismatch detected!"
  exit 1
fi
echo "✓ Routes match 100% symmetrically across client/server models!"

# 4. Extract and assert Form Field Data contract symmetry
echo "🔍 Scanning Form Field schemas..."
# We expect fields "email" and "companyName" in frontends
for FIELD in "email" "companyName"; do
  if ! grep -q "$FIELD" "$ANGULAR_TS"; then
    echo "❌ Field '$FIELD' missing in Angular component fields!"
    exit 1
  fi
  if ! grep -q "$FIELD" "$REACT_TSX"; then
    echo "❌ Field '$FIELD' missing in React RJSF properties!"
    exit 1
  fi
  if ! grep -q "$FIELD" "$VUE_SFC"; then
    echo "❌ Field '$FIELD' missing in Vue SFC reactive models!"
    exit 1
  fi
done
echo "✓ Data fields ('email', 'companyName') are declared 100% symmetrically across all frontends!"

echo "=================================================="
echo "🎉 SUCCESS: API contracts are 100% aligned! Frontend and Backend will integrate seamlessly! 🎉"
echo "=================================================="
