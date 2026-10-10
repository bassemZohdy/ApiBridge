#!/bin/bash
# json-server E2E Test — Tests List/View/Form pages against a live json-server mock
# Runs two combinations: Spring Boot + React, Quarkus + Vue

set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GENERATOR_JAR="../../apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar"
PASSED=0
FAILED=0

# ─── helpers ──────────────────────────────────────────────────────────────────

log()  { echo "[json-server-e2e] $*"; }
pass() { log "PASS: $*"; PASSED=$((PASSED + 1)); }
fail() { log "FAIL: $*"; FAILED=$((FAILED + 1)); }

wait_for_http() {
  local url="$1" timeout="${2:-60}" interval=2 elapsed=0
  while ! curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "^2"; do
    sleep "$interval"
    elapsed=$((elapsed + interval))
    if [ "$elapsed" -ge "$timeout" ]; then
      log "Timeout waiting for $url"
      return 1
    fi
  done
}

run_combination() {
  local label="$1" schema="$2" out_dir="$3" image_tag="$4" be_cartridge="$5" fe_cartridge="$6"
  local failures_before="$FAILED"
  log ""
  log "=== $label ==="

  # 1. Generate
  log "Generating from $schema..."
  rm -rf "$out_dir"
  mkdir -p "$out_dir"
  java -jar "$GENERATOR_JAR" \
    --schema="$schema" \
    --cartridge="../../apibridge-cartridges/$be_cartridge" \
    --cartridge="../../apibridge-cartridges/$fe_cartridge" \
    --cartridge=../../apibridge-cartridges/devops/dockerfile \
    --output="$out_dir" 2>/dev/null

  # Verify key files were generated
  if [ ! -f "$out_dir/Dockerfile" ]; then
    fail "$label: Dockerfile not generated"
    return
  fi
  pass "$label: project generated"

  # 2. Build Docker image
  log "Building Docker image $image_tag..."
  if ! docker build -t "$image_tag" "$out_dir" -q; then
    fail "$label: Docker build failed"
    return
  fi
  pass "$label: Docker image built"

  # 3. Start docker-compose (app + json-server)
  local compose_file
  compose_file=$(mktemp /tmp/apib-e2e-compose-XXXXX.yml)
  cat > "$compose_file" <<EOF
services:
  json-server:
    image: node:20-alpine
    command: ["npx", "--yes", "json-server@0.17.4", "--watch", "/data/db.json", "--host", "0.0.0.0"]
    volumes:
      - $(pwd)/data:/data
    expose:
      - "3000"

  app:
    image: $image_tag
    ports:
      - "18080:8080"
    environment:
      CUSTOM_CSS_PATH: /config/brand.css
      PAGINATION_PAGE_PARAM: "_page"
      PAGINATION_SIZE_PARAM: "_limit"
      PAGINATION_DEFAULT_PAGE_SIZE: "5"
      PAGINATION_SORT_PARAM: "_sort"
      PAGINATION_DIRECTION_PARAM: "_order"
    volumes:
      - $(pwd)/brand.css:/config/brand.css:ro
    depends_on:
      - json-server
EOF

  log "Starting services..."
  docker compose -f "$compose_file" up -d

  # 4. Wait for app
  if ! wait_for_http "http://localhost:18080/" 90; then
    fail "$label: app did not start within 90s"
    docker compose -f "$compose_file" logs --tail 100
    docker compose -f "$compose_file" down -v 2>/dev/null
    rm -f "$compose_file"
    return
  fi
  pass "$label: app started"

  # npx installs the pinned mock on a fresh runner; app startup is not mock readiness.
  if ! docker compose -f "$compose_file" exec -T json-server node -e '
    (async () => {
      for (let i = 0; i < 45; i++) {
        try {
          const response = await fetch("http://localhost:3000/customers");
          if (response.ok) process.exit(0);
        } catch {}
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
      process.exit(1);
    })();'; then
    fail "$label: json-server did not become ready within 90s"
    docker compose -f "$compose_file" logs --tail 100
    docker compose -f "$compose_file" down -v 2>/dev/null
    rm -f "$compose_file"
    return
  fi

  # 5. Tests
  # Test: static page served
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:18080/)
  if [ "$HTTP" = "200" ]; then pass "$label: GET / → 200"; else fail "$label: GET / → $HTTP"; fi

  # Test: bridge-config endpoint
  CONFIG=$(curl -s http://localhost:18080/api/bridge-config)
  if echo "$CONFIG" | grep -q "pagination"; then
    pass "$label: GET /api/bridge-config → has pagination"
  else
    fail "$label: GET /api/bridge-config missing pagination"
  fi

  # Test: ENV VAR override applied
  if echo "$CONFIG" | grep -q '"_page"'; then
    pass "$label: pagination ENV VAR override applied"
  else
    fail "$label: pagination ENV VAR override not applied"
  fi

  # Test: custom CSS served
  CSS=$(curl -s http://localhost:18080/custom.css)
  if echo "$CSS" | grep -q "accent"; then
    pass "$label: GET /custom.css → brand CSS served"
  else
    fail "$label: GET /custom.css → empty or missing"
  fi

  # Test: list endpoint proxied through app (json-server pagination)
  LIST=$(curl -s "http://localhost:18080/api/v1/customers?_page=1&_limit=5")
  if echo "$LIST" | grep -q "Alice\|Bob\|Clara"; then
    pass "$label: GET /api/v1/customers → list data proxied"
  else
    fail "$label: GET /api/v1/customers → unexpected: $LIST"
  fi

  # Test: view endpoint proxied
  VIEW=$(curl -s "http://localhost:18080/api/v1/customers/1")
  if echo "$VIEW" | grep -q '"id"' && echo "$VIEW" | grep -q '"name"'; then
    pass "$label: GET /api/v1/customers/1 → record proxied"
  else
    fail "$label: GET /api/v1/customers/1 → unexpected: $VIEW"
  fi

  # Test: POST (create) proxied
  CREATE=$(curl -s -X POST http://localhost:18080/api/v1/customers \
    -H "Content-Type: application/json" \
    -d '{"name":"Test User","email":"test@example.com","company":"TestCo"}')
  if echo "$CREATE" | grep -q '"id"'; then
    pass "$label: POST /api/v1/customers → record created"
  else
    fail "$label: POST /api/v1/customers → unexpected: $CREATE"
  fi

  # 6. Cleanup
  if [ "$FAILED" -gt "$failures_before" ]; then
    docker compose -f "$compose_file" logs --tail 100
  fi
  docker compose -f "$compose_file" down -v 2>/dev/null
  rm -f "$compose_file"

  # The default generated image must also start with optional branding absent.
  if [ "$be_cartridge" = "backend/quarkus" ]; then
    local unbranded_name="$image_tag-unbranded" unbranded_ready=false
    docker run -d --name "$unbranded_name" --network none "$image_tag" >/dev/null
    for ((i=0; i<45; i++)); do
      if docker exec "$unbranded_name" wget -T 2 -qO- http://localhost:8080/api/bridge-config \
          | grep -q '"customCssPath":""'; then
        unbranded_ready=true; break
      fi
      sleep 2
    done
    if [ "$unbranded_ready" = true ]; then
      pass "$label: default image starts with empty optional branding"
    else
      fail "$label: default image failed without branding"
      docker logs --tail 100 "$unbranded_name"
    fi
    docker rm -f "$unbranded_name" >/dev/null
  fi
}

# ─── Build generator if not skipped ───────────────────────────────────────────
if [ "${SKIP_GENERATOR_BUILD:-false}" != "true" ]; then
  log "Building generator..."
  (cd ../.. && mvn package -q -DskipTests)
fi

# ─── Run combinations ─────────────────────────────────────────────────────────
run_combination \
  "Spring Boot + React" \
  "schema-spring-react.yaml" \
  "/tmp/apib-jse2e-spring-react" \
  "apib-jse2e-spring-react" \
  "backend/spring-boot" \
  "frontend/react"

run_combination \
  "Quarkus + Vue" \
  "schema-quarkus-vue.yaml" \
  "/tmp/apib-jse2e-quarkus-vue" \
  "apib-jse2e-quarkus-vue" \
  "backend/quarkus" \
  "frontend/vue"

# ─── Report ───────────────────────────────────────────────────────────────────
log ""
log "=================================================="
log "  json-server E2E Results"
log "=================================================="
log "  PASSED: $PASSED"
log "  FAILED: $FAILED"
log "=================================================="

[ "$FAILED" -eq 0 ] && exit 0 || exit 1
