<#function pathToEnvKey path>
  <#local s = path?replace("[{}]", "", "r")?replace("[^A-Za-z0-9]", "_", "r")?upper_case />
  <#local s = s?replace("_+", "_", "r")?remove_beginning("_")?remove_ending("_") />
  <#return s />
</#function>
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${id}-config
  labels:
    app: ${id}
data:
  # ── Feature flags ────────────────────────────────────────────────────────────
  MOCK_MODE: "false"
  BLOCK_TRAFFIC: "false"
  # ── Credentials ──────────────────────────────────────────────────────────────
<#if (flags.securityLevel!"") == "apiKey">
  API_KEY: ""             # Set to enforce X-API-Key validation; empty = disabled
  # Note: for production, store API_KEY in a Secret rather than a ConfigMap
</#if>
<#if (flags.securityLevel!"") == "bearer-token">
  AUTH_SERVER_URL: ""     # JWT introspection URL; empty = pass-through (non-empty header check only)
  # Note: for production, store AUTH_SERVER_URL in a Secret rather than a ConfigMap
</#if>
  # ── CORS ─────────────────────────────────────────────────────────────────────
  CORS_ALLOWED_ORIGINS: "*"  # Restrict to specific origins in production
  # ── Pagination defaults ──────────────────────────────────────────────────────
  PAGINATION_PAGE_PARAM: "page"
  PAGINATION_SIZE_PARAM: "size"
  PAGINATION_DEFAULT_PAGE_SIZE: "20"
  PAGINATION_SORT_PARAM: "sort"
  PAGINATION_DIRECTION_PARAM: "dir"
  CUSTOM_CSS_PATH: ""
  # ── Server / JVM ─────────────────────────────────────────────────────────────
<#if backendFlavor == "spring-boot">
  SERVER_PORT: "8080"
  LOGGING_LEVEL_ROOT: "INFO"
<#else>
  QUARKUS_HTTP_PORT: "8080"
  QUARKUS_LOG_LEVEL: "INFO"
</#if>
  # ── Distributed tracing ──────────────────────────────────────────────────────
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
  # ── Per-endpoint backend URL overrides ───────────────────────────────────────
  # Override any URL without rebuilding the image
<#list endpoints as endpoint>
  BACKEND_URL_${pathToEnvKey(endpoint.path)}: "${endpoint.backendUrl}"
</#list>
<#if (flags.enableCircuitBreaker)!false>
  # ── Circuit breaker + retry ──────────────────────────────────────────────────
  CB_FAILURE_RATE_THRESHOLD: "50"
  CB_WAIT_DURATION_SECONDS: "30"
  CB_SLIDING_WINDOW_SIZE: "10"
  CB_RETRY_MAX_ATTEMPTS: "3"
  CB_RETRY_WAIT_MS: "500"
</#if>
<#if (flags.enableResponseCache)!false>
  # ── Response cache ────────────────────────────────────────────────────────────
  CACHE_TTL_SECONDS: "60"
  CACHE_MAX_SIZE: "1000"
</#if>
<#if (flags.enableAuditLog)!false>
  # ── Audit log ────────────────────────────────────────────────────────────────
  # Note: for production, store connection strings in Secrets rather than ConfigMap
<#if backendFlavor == "spring-boot">
  SPRING_DATA_REDIS_URL: "redis://redis:6379"
  SPRING_DATA_MONGODB_URI: "mongodb://mongo:27017"
  SPRING_DATA_MONGODB_DATABASE: "${id}-audit"
<#else>
  QUARKUS_REDIS_HOSTS: "redis://redis:6379"
  QUARKUS_MONGODB_CONNECTION_STRING: "mongodb://mongo:27017"
  QUARKUS_MONGODB_DATABASE: "${id}-audit"
</#if>
  AUDIT_LOG_TTL_DAYS: "30"
</#if>
