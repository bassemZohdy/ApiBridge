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

# ─── Supported ENV VAR overrides ──────────────────────────────────────────────
#   MOCK_MODE=false                   Return canned responses instead of proxying
#   BLOCK_TRAFFIC=false               Reject all requests with 503
#   QUARKUS_HTTP_PORT=8080            Listening port
#   QUARKUS_LOG_LEVEL=INFO            Root log level: ERROR | WARN | INFO | DEBUG
#   CORS_ALLOWED_ORIGINS=*            Comma-separated allowed origins
<#if (flags.securityLevel!"") == "apiKey">
#   API_KEY=                          Expected X-API-Key header; empty = validation disabled
</#if>
#
#   Per-endpoint backend URL overrides (default = schema-defined URL):
<#list endpoints as endpoint>
#   BACKEND_URL_${pathToEnvKey(endpoint.path)}=${endpoint.backendUrl}
</#list>
