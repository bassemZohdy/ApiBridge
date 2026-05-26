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

# Structured JSON logging for container log aggregators (EFK/Loki/CloudWatch)
quarkus.log.console.format=json
quarkus.log.console.json=true

# Disable the SmallRye Health UI in production (re-enable for dev if needed)
quarkus.smallrye-health.ui.enable=false
