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
