#!/bin/bash
# Master E2E Coordinator Script for ApiBridge Pluggable Cartridges (Decoupled E2E pipelines)

# Change directory to the script's physical location
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "🌟 Initiating ApiBridge Master E2E Validation 🌟"
echo "=================================================="

# Build the generator once up front, then let each sub-test skip it.
if [ "${SKIP_GENERATOR_BUILD:-false}" != "true" ]; then
  echo "Building ApiBridge Generator..."
  (cd .. && mvn package -q -DskipTests)
fi
export SKIP_GENERATOR_BUILD=true

# Track results
SPRING_BOOT_STATUS="PENDING"
QUARKUS_STATUS="PENDING"
ANGULAR_STATUS="PENDING"
REACT_STATUS="PENDING"
VUE_STATUS="PENDING"
CONTRACT_STATUS="PENDING"
FULLSTACK_STATUS="PENDING"
JSONSERVER_STATUS="PENDING"
KUBERNETES_STATUS="PENDING"
OPENSHIFT_STATUS="PENDING"
REACT_PROD_STATUS="PENDING"
OPENAPI_STATUS="PENDING"
HELM_STATUS="PENDING"
UI_SCHEMA_STATUS="PENDING"
OIDC_STATUS="PENDING"
APIKEY_STATUS="PENDING"
VUE_PROD_STATUS="PENDING"
ANGULAR_PROD_STATUS="PENDING"
MULTI_SCHEMA_STATUS="PENDING"

# 1. Run Spring Boot E2E
echo -e "\n--------------------------------------------------"
echo "📋 [1/19] Executing Spring Boot E2E Validation..."
echo "--------------------------------------------------"
if ./maven-spring-boot-test/run-e2e.sh; then
  SPRING_BOOT_STATUS="SUCCESS"
else
  SPRING_BOOT_STATUS="FAILED"
fi

# 2. Run Quarkus E2E
echo -e "\n--------------------------------------------------"
echo "📋 [2/19] Executing Quarkus E2E Validation..."
echo "--------------------------------------------------"
if ./maven-quarkus-test/run-e2e.sh; then
  QUARKUS_STATUS="SUCCESS"
else
  QUARKUS_STATUS="FAILED"
fi

# 3. Run Angular E2E
echo -e "\n--------------------------------------------------"
echo "📋 [3/19] Executing Angular Frontend E2E Validation..."
echo "--------------------------------------------------"
if ./typescript-angular-test/run-e2e.sh; then
  ANGULAR_STATUS="SUCCESS"
else
  ANGULAR_STATUS="FAILED"
fi

# 4. Run React E2E
echo -e "\n--------------------------------------------------"
echo "📋 [4/19] Executing React Frontend E2E Validation..."
echo "--------------------------------------------------"
if ./typescript-react-test/run-e2e.sh; then
  REACT_STATUS="SUCCESS"
else
  REACT_STATUS="FAILED"
fi

# 5. Run Vue E2E
echo -e "\n--------------------------------------------------"
echo "📋 [5/19] Executing Vue Frontend E2E Validation..."
echo "--------------------------------------------------"
if ./typescript-vue-test/run-e2e.sh; then
  VUE_STATUS="SUCCESS"
else
  VUE_STATUS="FAILED"
fi

# 6. Run Contract Symmetry check
echo -e "\n--------------------------------------------------"
echo "📋 [6/19] Executing Backend-Frontend Contract Symmetry Scanner..."
echo "--------------------------------------------------"
if ./verify-contract-symmetry.sh; then
  CONTRACT_STATUS="SUCCESS"
else
  CONTRACT_STATUS="FAILED"
fi

# 7. Run Fullstack Docker E2E
echo -e "\n--------------------------------------------------"
echo "📋 [7/19] Executing Fullstack Docker E2E Validation..."
echo "--------------------------------------------------"
if ./docker-fullstack-test/run-e2e.sh; then
  FULLSTACK_STATUS="SUCCESS"
else
  FULLSTACK_STATUS="FAILED"
fi

# 8. Run json-server List/View/Form E2E
echo -e "\n--------------------------------------------------"
echo "📋 [8/19] Executing json-server List/View/Form E2E..."
echo "--------------------------------------------------"
if ./json-server-test/run-e2e.sh; then
  JSONSERVER_STATUS="SUCCESS"
else
  JSONSERVER_STATUS="FAILED"
fi

# 9. Run Kubernetes manifest validation
echo -e "\n--------------------------------------------------"
echo "📋 [9/19] Executing Kubernetes Manifest Validation..."
echo "--------------------------------------------------"
if ./kubernetes-test/run-e2e.sh; then
  KUBERNETES_STATUS="SUCCESS"
else
  KUBERNETES_STATUS="FAILED"
fi

# 10. Run OpenShift manifest validation
echo -e "\n--------------------------------------------------"
echo "📋 [10/19] Executing OpenShift Manifest Validation..."
echo "--------------------------------------------------"
if ./openshift-test/run-e2e.sh; then
  OPENSHIFT_STATUS="SUCCESS"
else
  OPENSHIFT_STATUS="FAILED"
fi

# 11. Run React production build
echo -e "\n--------------------------------------------------"
echo "📋 [11/19] Executing React Production Build E2E..."
echo "--------------------------------------------------"
if ./react-prod-build-test/run-e2e.sh; then
  REACT_PROD_STATUS="SUCCESS"
else
  REACT_PROD_STATUS="FAILED"
fi

# 12. Run OpenAPI spec validation
echo -e "\n--------------------------------------------------"
echo "📋 [12/19] Executing OpenAPI Spec Validation..."
echo "--------------------------------------------------"
if ./openapi-test/run-e2e.sh; then
  OPENAPI_STATUS="SUCCESS"
else
  OPENAPI_STATUS="FAILED"
fi

# 13. Run Helm chart validation
echo -e "\n--------------------------------------------------"
echo "📋 [13/19] Executing Helm Chart Validation..."
echo "--------------------------------------------------"
if ./helm-test/run-e2e.sh; then
  HELM_STATUS="SUCCESS"
else
  HELM_STATUS="FAILED"
fi

# 14. Run UI schema validation
echo -e "\n--------------------------------------------------"
echo "📋 [14/19] Executing UI Schema Validation..."
echo "--------------------------------------------------"
if ./ui-schema-test/run-e2e.sh; then
  UI_SCHEMA_STATUS="SUCCESS"
else
  UI_SCHEMA_STATUS="FAILED"
fi

# 15. Run OIDC / SecurityConfig E2E
echo -e "\n--------------------------------------------------"
echo "📋 [15/19] Executing OIDC / SecurityConfig E2E..."
echo "--------------------------------------------------"
if ./oidc-test/run-e2e.sh; then
  OIDC_STATUS="SUCCESS"
else
  OIDC_STATUS="FAILED"
fi

# 16. Run apiKey security validation
echo -e "\n--------------------------------------------------"
echo "📋 [16/19] Executing apiKey Security E2E..."
echo "--------------------------------------------------"
if ./apikey-test/run-e2e.sh; then
  APIKEY_STATUS="SUCCESS"
else
  APIKEY_STATUS="FAILED"
fi

# 17. Run Vue production build
echo -e "\n--------------------------------------------------"
echo "📋 [17/19] Executing Vue Production Build E2E..."
echo "--------------------------------------------------"
if ./vue-prod-build-test/run-e2e.sh; then
  VUE_PROD_STATUS="SUCCESS"
else
  VUE_PROD_STATUS="FAILED"
fi

# 18. Run Angular production build
echo -e "\n--------------------------------------------------"
echo "📋 [18/19] Executing Angular Production Build E2E..."
echo "--------------------------------------------------"
if ./angular-prod-build-test/run-e2e.sh; then
  ANGULAR_PROD_STATUS="SUCCESS"
else
  ANGULAR_PROD_STATUS="FAILED"
fi

# 19. Run multi-schema composition
echo -e "\n--------------------------------------------------"
echo "📋 [19/19] Executing Multi-Schema Composition E2E..."
echo "--------------------------------------------------"
if ./multi-schema-test/run-e2e.sh; then
  MULTI_SCHEMA_STATUS="SUCCESS"
else
  MULTI_SCHEMA_STATUS="FAILED"
fi

# Print final report card dashboard
echo -e "\n=================================================="
echo "          ApiBridge E2E COMPLIANCE REPORT"
echo "=================================================="
printf "  %-35s | %s\n" "Integration Pipeline" "Status"
echo "--------------------------------------------------"
if [ "$SPRING_BOOT_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Spring Boot (Maven Compile)" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Spring Boot (Maven Compile)" "FAILED"
fi

if [ "$QUARKUS_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Quarkus JAX-RS (Maven Compile)" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Quarkus JAX-RS (Maven Compile)" "FAILED"
fi

if [ "$ANGULAR_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Angular Frontend (Strict tsc)" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Angular Frontend (Strict tsc)" "FAILED"
fi

if [ "$REACT_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "React Frontend (Strict tsc)" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "React Frontend (Strict tsc)" "FAILED"
fi

if [ "$VUE_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Vue Frontend (Strict tsc)" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Vue Frontend (Strict tsc)" "FAILED"
fi

if [ "$CONTRACT_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Backend-Frontend Contract Alignment" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Backend-Frontend Contract Alignment" "FAILED"
fi

if [ "$FULLSTACK_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Fullstack Docker (Struct + Content)" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Fullstack Docker (Struct + Content)" "FAILED"
fi

if [ "$JSONSERVER_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "json-server List/View/Form E2E" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "json-server List/View/Form E2E" "FAILED"
fi

if [ "$KUBERNETES_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Kubernetes Manifest Validation" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Kubernetes Manifest Validation" "FAILED"
fi

if [ "$OPENSHIFT_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "OpenShift Manifest Validation" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "OpenShift Manifest Validation" "FAILED"
fi

if [ "$REACT_PROD_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "React Production Build" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "React Production Build" "FAILED"
fi

if [ "$OPENAPI_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "OpenAPI Spec Validation" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "OpenAPI Spec Validation" "FAILED"
fi

if [ "$HELM_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Helm Chart Validation" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Helm Chart Validation" "FAILED"
fi

if [ "$UI_SCHEMA_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "UI Schema Validation" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "UI Schema Validation" "FAILED"
fi

if [ "$OIDC_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "OIDC / SecurityConfig" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "OIDC / SecurityConfig" "FAILED"
fi

if [ "$APIKEY_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "apiKey Security" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "apiKey Security" "FAILED"
fi

if [ "$VUE_PROD_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Vue Production Build" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Vue Production Build" "FAILED"
fi

if [ "$ANGULAR_PROD_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Angular Production Build" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Angular Production Build" "FAILED"
fi

if [ "$MULTI_SCHEMA_STATUS" = "SUCCESS" ]; then
  printf "  %-35s | \033[0;32m%s\033[0m\n" "Multi-Schema Composition" "SUCCESS"
else
  printf "  %-35s | \033[0;31m%s\033[0m\n" "Multi-Schema Composition" "FAILED"
fi
echo "=================================================="

# Exit with error if any pipeline failed
if [ "$SPRING_BOOT_STATUS" != "SUCCESS" ] || \
   [ "$QUARKUS_STATUS" != "SUCCESS" ] || \
   [ "$ANGULAR_STATUS" != "SUCCESS" ] || \
   [ "$REACT_STATUS" != "SUCCESS" ] || \
   [ "$VUE_STATUS" != "SUCCESS" ] || \
   [ "$CONTRACT_STATUS" != "SUCCESS" ] || \
   [ "$FULLSTACK_STATUS" != "SUCCESS" ] || \
   [ "$JSONSERVER_STATUS" != "SUCCESS" ] || \
   [ "$KUBERNETES_STATUS" != "SUCCESS" ] || \
   [ "$OPENSHIFT_STATUS" != "SUCCESS" ] || \
   [ "$REACT_PROD_STATUS" != "SUCCESS" ] || \
   [ "$OPENAPI_STATUS" != "SUCCESS" ] || \
   [ "$HELM_STATUS" != "SUCCESS" ] || \
   [ "$UI_SCHEMA_STATUS" != "SUCCESS" ] || \
   [ "$OIDC_STATUS" != "SUCCESS" ] || \
   [ "$APIKEY_STATUS" != "SUCCESS" ] || \
   [ "$VUE_PROD_STATUS" != "SUCCESS" ] || \
   [ "$ANGULAR_PROD_STATUS" != "SUCCESS" ] || \
   [ "$MULTI_SCHEMA_STATUS" != "SUCCESS" ]; then
  echo "❌ Error: One or more integration pipelines failed."
  exit 1
else
  echo "🎉 Success: All plugin cartridges are 100% compliant!"
  exit 0
fi
