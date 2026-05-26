#!/bin/bash
# Master E2E Coordinator Script for ApiBridge Pluggable Cartridges (Decoupled E2E pipelines)

# Change directory to the script's physical location
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=================================================="
echo "🌟 Initiating ApiBridge Master E2E Validation 🌟"
echo "=================================================="

# Track results
SPRING_BOOT_STATUS="PENDING"
QUARKUS_STATUS="PENDING"
ANGULAR_STATUS="PENDING"
REACT_STATUS="PENDING"
VUE_STATUS="PENDING"
CONTRACT_STATUS="PENDING"
FULLSTACK_STATUS="PENDING"

# 1. Run Spring Boot E2E
echo -e "\n--------------------------------------------------"
echo "📋 [1/6] Executing Spring Boot E2E Validation..."
echo "--------------------------------------------------"
if ./maven-spring-boot-test/run-e2e.sh; then
  SPRING_BOOT_STATUS="SUCCESS"
else
  SPRING_BOOT_STATUS="FAILED"
fi

# 2. Run Quarkus E2E
echo -e "\n--------------------------------------------------"
echo "📋 [2/6] Executing Quarkus E2E Validation..."
echo "--------------------------------------------------"
if ./maven-quarkus-test/run-e2e.sh; then
  QUARKUS_STATUS="SUCCESS"
else
  QUARKUS_STATUS="FAILED"
fi

# 3. Run Angular E2E
echo -e "\n--------------------------------------------------"
echo "📋 [3/6] Executing Angular Frontend E2E Validation..."
echo "--------------------------------------------------"
if ./typescript-angular-test/run-e2e.sh; then
  ANGULAR_STATUS="SUCCESS"
else
  ANGULAR_STATUS="FAILED"
fi

# 4. Run React E2E
echo -e "\n--------------------------------------------------"
echo "📋 [4/6] Executing React Frontend E2E Validation..."
echo "--------------------------------------------------"
if ./typescript-react-test/run-e2e.sh; then
  REACT_STATUS="SUCCESS"
else
  REACT_STATUS="FAILED"
fi

# 5. Run Vue E2E
echo -e "\n--------------------------------------------------"
echo "📋 [5/6] Executing Vue Frontend E2E Validation..."
echo "--------------------------------------------------"
if ./typescript-vue-test/run-e2e.sh; then
  VUE_STATUS="SUCCESS"
else
  VUE_STATUS="FAILED"
fi

# 6. Run Contract Symmetry check
echo -e "\n--------------------------------------------------"
echo "📋 [6/7] Executing Backend-Frontend Contract Symmetry Scanner..."
echo "--------------------------------------------------"
if ./verify-contract-symmetry.sh; then
  CONTRACT_STATUS="SUCCESS"
else
  CONTRACT_STATUS="FAILED"
fi

# 7. Run Fullstack Docker E2E
echo -e "\n--------------------------------------------------"
echo "📋 [7/7] Executing Fullstack Docker E2E Validation..."
echo "--------------------------------------------------"
if ./docker-fullstack-test/run-e2e.sh; then
  FULLSTACK_STATUS="SUCCESS"
else
  FULLSTACK_STATUS="FAILED"
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
echo "=================================================="

# Exit with error if any pipeline failed
if [ "$SPRING_BOOT_STATUS" != "SUCCESS" ] || \
   [ "$QUARKUS_STATUS" != "SUCCESS" ] || \
   [ "$ANGULAR_STATUS" != "SUCCESS" ] || \
   [ "$REACT_STATUS" != "SUCCESS" ] || \
   [ "$VUE_STATUS" != "SUCCESS" ] || \
   [ "$CONTRACT_STATUS" != "SUCCESS" ] || \
   [ "$FULLSTACK_STATUS" != "SUCCESS" ]; then
  echo "❌ Error: One or more integration pipelines failed."
  exit 1
else
  echo "🎉 Success: All plugin cartridges are 100% compliant!"
  exit 0
fi
