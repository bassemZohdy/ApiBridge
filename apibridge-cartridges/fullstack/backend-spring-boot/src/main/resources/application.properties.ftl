<#function pathToEnvKey path>
  <#local s = path?replace("[{}]", "", "r")?replace("[^A-Za-z0-9]", "_", "r")?upper_case />
  <#local s = s?replace("_+", "_", "r")?remove_beginning("_")?remove_ending("_") />
  <#return s />
</#function>
spring.application.name=${id}
server.port=8080

# Graceful shutdown — wait up to 30 s for in-flight requests before JVM exits
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s

# HTTP response compression
server.compression.enabled=true
server.compression.mime-types=application/json,application/javascript,text/css,text/html,text/plain
server.compression.min-response-size=1024

# Static resources (embedded FE dist, served at /)
spring.web.resources.static-locations=classpath:/static/
spring.web.resources.cache.cachecontrol.max-age=365d
spring.web.resources.cache.cachecontrol.cache-public=true

# Actuator — health probes used by Docker HEALTHCHECK and K8s probes
management.endpoints.web.exposure.include=health,info
management.endpoint.health.probes.enabled=true
management.endpoint.health.show-details=never

# Structured JSON logging for container log aggregators (EFK/Loki/CloudWatch)
logging.structured.format.console=ecs
<#if flags.enableTelemetry>

# Distributed tracing — OTLP exporter
# Override MANAGEMENT_OTLP_TRACING_ENDPOINT to point at your collector
management.tracing.enabled=true
management.tracing.sampling.probability=1.0
management.otlp.tracing.endpoint=http://localhost:4318/v1/traces
</#if>

# ─── Supported ENV VAR overrides ──────────────────────────────────────────────
# All values below can be set as environment variables at runtime.
# Spring Boot reads ENV VARs automatically (e.g. SERVER_PORT overrides server.port).
#
#   MOCK_MODE=false               Return canned responses instead of proxying
#   BLOCK_TRAFFIC=false           Reject all requests with 503
#   SERVER_PORT=8080              Listening port
#   LOGGING_LEVEL_ROOT=INFO       Root log level: ERROR | WARN | INFO | DEBUG
#   LOGGING_LEVEL_COM_APIBRIDGE=INFO  Package-level log level
#   CORS_ALLOWED_ORIGINS=*        Comma-separated allowed origins (CorsConfig)
<#if (flags.securityLevel!"") == "apiKey">
#   API_KEY=                      Expected X-API-Key header value; empty = validation disabled
</#if>
<#if flags.enableTelemetry>
#   MANAGEMENT_TRACING_ENABLED=true
#   MANAGEMENT_TRACING_SAMPLING_PROBABILITY=1.0
#   MANAGEMENT_OTLP_TRACING_ENDPOINT=http://<collector>:4318/v1/traces
</#if>
#
#   Per-endpoint backend URL overrides (default = schema-defined URL):
<#list endpoints as endpoint>
#   BACKEND_URL_${pathToEnvKey(endpoint.path)}=${endpoint.backendUrl}
</#list>
