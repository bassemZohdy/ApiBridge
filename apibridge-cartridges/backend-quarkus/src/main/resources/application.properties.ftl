quarkus.application.name=${id}
quarkus.http.port=8080

# Graceful shutdown
quarkus.shutdown.timeout=30S

# HTTP compression
quarkus.http.enable-compression=true

# Health probes
quarkus.smallrye-health.liveness-path=/q/health/live
quarkus.smallrye-health.readiness-path=/q/health/ready
quarkus.smallrye-health.startup-path=/q/health/started
quarkus.smallrye-health.ui.enable=false

# Structured JSON logging
quarkus.log.console.format=json
quarkus.log.console.json=true
<#if flags.enableTelemetry>

# OpenTelemetry exporter (override OTEL_EXPORTER_OTLP_ENDPOINT at runtime)
quarkus.otel.exporter.otlp.traces.endpoint=http://localhost:4317
quarkus.otel.service.name=${id}
</#if>

# ─── Runtime ENV VAR overrides ─────────────────────────────────────────────────
#   MOCK_MODE                  — return canned responses instead of proxying (default: false)
#   BLOCK_TRAFFIC              — reject all requests with 503 (default: false)
#   QUARKUS_HTTP_PORT          — override listening port (default: 8080)
#   QUARKUS_LOG_LEVEL          — root log level: ERROR | WARN | INFO | DEBUG (default: INFO)
#   OTEL_EXPORTER_OTLP_ENDPOINT — OpenTelemetry collector endpoint
