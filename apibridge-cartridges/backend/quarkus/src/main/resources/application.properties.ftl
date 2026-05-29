<#function pathToEnvKey path>
  <#local s = path?replace("[{}]", "", "r")?replace("[^A-Za-z0-9]", "_", "r")?upper_case />
  <#local s = s?replace("_+", "_", "r")?remove_beginning("_")?remove_ending("_") />
  <#return s />
</#function>
quarkus.application.name=${id}
quarkus.http.port=8080

# Graceful shutdown — drain in-flight requests before exit
quarkus.shutdown.timeout=30S

# HTTP idle connection timeout
quarkus.http.idle-timeout=60S

# Static resources from META-INF/resources/ (embedded FE dist)
quarkus.http.root-path=/

# HTTP compression
quarkus.http.enable-compression=true

# Health probes — used by Docker HEALTHCHECK and K8s probes
quarkus.smallrye-health.liveness-path=/q/health/live
quarkus.smallrye-health.readiness-path=/q/health/ready
quarkus.smallrye-health.startup-path=/q/health/started
quarkus.smallrye-health.ui.enable=false

# Structured JSON logging for container log aggregators (EFK/Loki/CloudWatch)
quarkus.log.console.format=json
quarkus.log.console.json=true

# CORS — CORS_ALLOWED_ORIGINS env var controls allowed origins at runtime
quarkus.http.cors=true
quarkus.http.cors.origins=${r"${CORS_ALLOWED_ORIGINS:*}"}
quarkus.http.cors.methods=GET,POST,PUT,DELETE,PATCH,OPTIONS
quarkus.http.cors.headers=*
quarkus.http.cors.exposed-headers=*
quarkus.http.cors.access-control-max-age=3600
<#if flags.enableTelemetry>

# Distributed tracing — OTLP exporter
# Override QUARKUS_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT to point at your collector
quarkus.otel.enabled=true
quarkus.otel.exporter.otlp.traces.endpoint=http://localhost:4317
quarkus.otel.service.name=${id}
</#if>

# ─── Supported ENV VAR overrides ──────────────────────────────────────────────
#   MOCK_MODE=false                   Return canned responses instead of proxying
#   BLOCK_TRAFFIC=false               Reject all requests with 503
#   QUARKUS_HTTP_PORT=8080            Listening port
#   QUARKUS_LOG_LEVEL=INFO            Root log level: ERROR | WARN | INFO | DEBUG
#   CORS_ALLOWED_ORIGINS=*            Comma-separated allowed origins
#   CUSTOM_CSS_PATH=                  Absolute path to a CSS file mounted at runtime;
#                                     served at /custom.css for white-label styling.
#   PAGINATION_PAGE_PARAM=page        Query param name for page number
#   PAGINATION_SIZE_PARAM=size        Query param name for page size
#   PAGINATION_DEFAULT_PAGE_SIZE=20   Default page size
#   PAGINATION_SORT_PARAM=sort        Query param name for sort field
#   PAGINATION_DIRECTION_PARAM=dir    Query param name for sort direction (asc/desc)
#   PROXY_CONNECT_TIMEOUT=5000        Proxy connect timeout in milliseconds (default: 5000)
#   PROXY_READ_TIMEOUT=30000          Proxy read timeout in milliseconds (default: 30000)
#   DEBUG_MODE=false                   Enable debug logging (request/response details); off in production
<#if (flags.enableTransform)!false>
#   Transforms are schema-defined at build time — no runtime configuration needed.
#   Header transforms: add, remove, rename on request and response headers.
#   Field transforms: rename, remove on JSON request and response body fields.
</#if>
<#if (flags.enableAuditLog)!false>
#   QUARKUS_REDIS_HOSTS=redis://localhost:6379   Redis connection URL
#   QUARKUS_MONGODB_CONNECTION_STRING=mongodb://localhost:27017  MongoDB URI
#   QUARKUS_MONGODB_DATABASE=${id}-audit         MongoDB database name
#   AUDIT_LOG_TTL_DAYS=30            Days to retain audit records (MongoDB TTL index)
</#if>
<#if (flags.enableCircuitBreaker)!false>
#   CB_FAILURE_RATE_THRESHOLD=50     % failures (of CB_SLIDING_WINDOW_SIZE calls) to open circuit
#   CB_WAIT_DURATION_SECONDS=30      Seconds circuit stays OPEN before moving to HALF-OPEN
#   CB_SLIDING_WINDOW_SIZE=10        Number of calls sampled for failure rate calculation
#   CB_RETRY_MAX_ATTEMPTS=3          Total attempts per call (original + retries)
#   CB_RETRY_WAIT_MS=500             Wait between retry attempts in milliseconds
</#if>
<#if (flags.enableResponseCache)!false>
#   CACHE_REDIS_URL=                 Redis URL for distributed cache; empty/absent = embedded Caffeine
#   CACHE_TTL_SECONDS=60             TTL for cached GET responses
#   CACHE_MAX_SIZE=1000              Maximum cached entries (LRU eviction, Caffeine only)
</#if>
<#if (flags.enableRateLimiter)!false>
#   RATE_LIMIT_PERMITS=10            Max requests per rate limit period
#   RATE_LIMIT_PERIOD_SECONDS=1      Rate limit period in seconds
#   RATE_LIMIT_TIMEOUT_MILLIS=5000   Max wait for a permit before 429
</#if>
<#if (flags.securityLevel!"") == "apiKey">
#   API_KEY=                          Expected X-API-Key header; empty = validation disabled
</#if>
<#if (flags.securityLevel!"") == "bearer-token">
#   AUTH_SERVER_URL=                  URL of JWT introspection endpoint; empty = pass-through (non-empty header check only)
</#if>
<#if flags.enableTelemetry>
#   QUARKUS_OTEL_ENABLED=true
#   QUARKUS_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://<collector>:4317
#   QUARKUS_OTEL_SERVICE_NAME=${id}
</#if>
#
#   Per-endpoint backend URL overrides (default = schema-defined URL):
<#list endpoints as endpoint>
#   BACKEND_URL_${pathToEnvKey(endpoint.path)}=${endpoint.backendUrl}
</#list>
