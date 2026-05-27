spring.application.name=${id}
server.port=8080

# Graceful shutdown
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s

# HTTP response compression
server.compression.enabled=true
server.compression.mime-types=application/json,text/plain
server.compression.min-response-size=1024

# Actuator health probes
management.endpoints.web.exposure.include=health,info
management.endpoint.health.probes.enabled=true
management.endpoint.health.show-details=never
<#if flags.enableTelemetry>
# Actuator must expose the tracing endpoint for OTLP push
management.endpoints.web.exposure.include=health,info,metrics
</#if>

# Structured JSON logging for container log aggregators
logging.structured.format.console=ecs
<#if flags.enableTelemetry>

# Distributed tracing — OTLP exporter
# Override MANAGEMENT_OTLP_TRACING_ENDPOINT to point at your collector
management.tracing.enabled=true
management.tracing.sampling.probability=1.0
management.otlp.tracing.endpoint=http://localhost:4318/v1/traces
</#if>

# ─── Runtime ENV VAR overrides ─────────────────────────────────────────────────
#   MOCK_MODE            — return canned responses instead of proxying (default: false)
#   BLOCK_TRAFFIC        — reject all requests with 503 (default: false)
#   SERVER_PORT          — override listening port (default: 8080)
#   LOGGING_LEVEL_ROOT   — root log level: ERROR | WARN | INFO | DEBUG (default: INFO)
#   LOGGING_LEVEL_COM_APIBRIDGE — package-level log level
<#if flags.enableTelemetry>
#   MANAGEMENT_TRACING_ENABLED=true
#   MANAGEMENT_TRACING_SAMPLING_PROBABILITY=1.0
#   MANAGEMENT_OTLP_TRACING_ENDPOINT=http://<collector>:4318/v1/traces
</#if>
