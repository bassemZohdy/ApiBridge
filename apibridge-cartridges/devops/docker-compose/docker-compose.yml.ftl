<#function pathToEnvKey path>
  <#local s = path?replace("[{}]", "", "r")?replace("[^A-Za-z0-9]", "_", "r")?upper_case />
  <#local s = s?replace("_+", "_", "r")?remove_beginning("_")?remove_ending("_") />
  <#return s />
</#function>
services:
  ${id}:
    build:
      context: .
      dockerfile: Dockerfile
<#if (feFlavor!"") != "">
      args:
        # Frontend build-time base URL (leave empty when FE is co-hosted in the same container)
        VITE_API_BASE_URL: ""
<#if (flags.securityLevel!"") == "apiKey">
        # API key injected into the frontend bundle at build time
        VITE_API_KEY: ""
</#if>
</#if>
    image: ${id}:latest
    ports:
      - "8080:8080"
    environment:
      # ── White-label CSS override ───────────────────────────────────────────
      # Mount your brand CSS file and point CUSTOM_CSS_PATH at it; the app
      # serves it at /custom.css — override any :root CSS variable defined
      # in the frontend.  Omit (or leave blank) to use the built-in theme.
      # CUSTOM_CSS_PATH: "/config/custom.css"
      # ── Feature flags ──────────────────────────────────────────────────────
      MOCK_MODE: "false"
      BLOCK_TRAFFIC: "false"
      # ── Credentials ────────────────────────────────────────────────────────
<#if (flags.securityLevel!"") == "apiKey">
      API_KEY: ""                # Set to enforce X-API-Key validation; empty = disabled
</#if>
<#if (flags.securityLevel!"") == "bearer-token">
      AUTH_SERVER_URL: ""        # JWT introspection URL; empty = pass-through (non-empty header check only)
</#if>
      # ── CORS ───────────────────────────────────────────────────────────────
      CORS_ALLOWED_ORIGINS: "*"  # Restrict to specific origins in production
      # ── Server / JVM ───────────────────────────────────────────────────────
<#if backendFlavor == "spring-boot">
      SERVER_PORT: "8080"
      LOGGING_LEVEL_ROOT: "INFO"
<#else>
      QUARKUS_HTTP_PORT: "8080"
      QUARKUS_LOG_LEVEL: "INFO"
</#if>
      # JAVA_OPTS: "-Xms128m -Xmx256m"
      # ── Distributed tracing ────────────────────────────────────────────────
<#if flags.enableTelemetry>
<#if backendFlavor == "spring-boot">
      MANAGEMENT_TRACING_ENABLED: "true"
      MANAGEMENT_TRACING_SAMPLING_PROBABILITY: "1.0"
      MANAGEMENT_OTLP_TRACING_ENDPOINT: "http://localhost:4318/v1/traces"
<#else>
      QUARKUS_OTEL_ENABLED: "true"
      QUARKUS_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: "http://localhost:4317"
      QUARKUS_OTEL_SERVICE_NAME: "${id}"
</#if>
</#if>
      # ── Per-endpoint backend URL overrides ─────────────────────────────────
<#list endpoints as endpoint>
      BACKEND_URL_${pathToEnvKey(endpoint.path)}: "${endpoint.backendUrl}"
</#list>
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
        reservations:
          cpus: "0.25"
          memory: 128M
    healthcheck:
<#if backendFlavor == "spring-boot">
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/actuator/health/liveness"]
<#else>
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/q/health/live"]
</#if>
      interval: 30s
      timeout: 5s
      start_period: 60s
      retries: 3
    restart: unless-stopped
    # volumes:
    #   - ./brand/custom.css:/config/custom.css:ro   # white-label CSS override
    networks:
      - ${id}-net

networks:
  ${id}-net:
    driver: bridge
