---
name: run-generator
description: Run the ApiBridge generator JAR against a schema and cartridge. Use when you want to generate code for a specific cartridge or verify template output.
disable-model-invocation: true
---

# Run ApiBridge Generator

Usage: `/run-generator` (interactive) or `/run-generator <cartridge-name>`

## Build first (if JAR is stale)

```bash
mvn clean package -q
```

## Run against all cartridges

```bash
JAR=apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar
SCHEMA=sample-schema.yaml

for cartridge in apibridge-cartridges/*/; do
  name=$(basename "$cartridge")
  java -jar "$JAR" --schema="$SCHEMA" --cartridge="$cartridge" --output="output/$name"
  echo "Generated: output/$name"
done
```

## Run against a specific cartridge

If `$ARGUMENTS` is provided, run only that cartridge:

```bash
java -jar apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/$ARGUMENTS \
  --output=output/$ARGUMENTS
```

Available cartridges: `backend/spring-boot`, `backend/quarkus`, `frontend/angular`, `frontend/react`, `frontend/vue`, `frontend/ui-schema`, `devops/dockerfile`, `devops/docker-compose`, `devops/k8s/kubernetes`, `devops/k8s/openshift`

## Inspect output

```bash
find output/ -type f | sort
```
