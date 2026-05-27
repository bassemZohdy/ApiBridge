<#function pathToEnvKey path>
  <#local s = path?replace("[{}]", "", "r")?replace("[^A-Za-z0-9]", "_", "r")?upper_case />
  <#local s = s?replace("_+", "_", "r")?remove_beginning("_")?remove_ending("_") />
  <#return s />
</#function>
# =============================================================================
# Stage 1 — Frontend build
# =============================================================================
FROM node:20-alpine AS frontend-build

# Build-time env vars for the frontend bundle (set via --build-arg or docker-compose build.args)
ARG VITE_API_BASE_URL=""
ENV VITE_API_BASE_URL=${r"${VITE_API_BASE_URL}"}
<#if (flags.securityLevel!"") == "apiKey">
ARG VITE_API_KEY=""
ENV VITE_API_KEY=${r"${VITE_API_KEY}"}
</#if>

WORKDIR /app/frontend

COPY frontend/package.json ./
RUN npm install --prefer-offline --no-fund --no-audit

COPY frontend/ ./
RUN npm run build

# =============================================================================
# Stage 2 — Backend build (embeds compiled FE assets)
# =============================================================================
FROM maven:3.9-amazoncorretto-21-alpine AS backend-build

WORKDIR /app/backend

# Resolve dependencies as a separate cached layer
COPY backend/pom.xml ./
RUN mvn dependency:go-offline -q

COPY backend/src ./src

# Embed compiled frontend assets into the backend static-resource directory
<#if backendFlavor == "spring-boot">
<#if feFlavor == "angular">
COPY --from=frontend-build /app/frontend/dist/${id}-fe/browser/ ./src/main/resources/static/
<#else>
COPY --from=frontend-build /app/frontend/dist/ ./src/main/resources/static/
</#if>
<#else>
<#if feFlavor == "angular">
COPY --from=frontend-build /app/frontend/dist/${id}-fe/browser/ ./src/main/resources/META-INF/resources/
<#else>
COPY --from=frontend-build /app/frontend/dist/ ./src/main/resources/META-INF/resources/
</#if>
</#if>

RUN mvn package -DskipTests -q

# =============================================================================
# Stage 3 — Minimal runtime image
# =============================================================================
FROM amazoncorretto:21-alpine AS runtime

# OCI standard image labels
LABEL org.opencontainers.image.title="${id}" \
      org.opencontainers.image.description="ApiBridge generated service: ${id}" \
      org.opencontainers.image.version="0.1.0" \
      org.opencontainers.image.vendor="ApiBridge"

# Non-root user — UID/GID 1001.
# chmod g=u satisfies OpenShift's arbitrary-UID policy (runs as random UID in group 0).
RUN addgroup -S -g 1001 appgroup \
    && adduser -S -u 1001 -G appgroup appuser

WORKDIR /app

COPY --from=backend-build --chown=appuser:appgroup /app/backend/target/*.jar app.jar

RUN chmod g=u /app/app.jar

USER 1001

EXPOSE 8080

# ─── Runtime ENV VARs ─────────────────────────────────────────────────────────
# All variables below can be overridden with -e / docker-compose environment: / K8s ConfigMap.
ENV \
    # Feature flags
    MOCK_MODE=false \
    BLOCK_TRAFFIC=false \
    # JVM tuning
    JAVA_OPTS="" \
<#if backendFlavor == "spring-boot">
    # Port (Spring Boot reads SERVER_PORT automatically)
    SERVER_PORT=8080 \
    # Log level (Spring Boot reads LOGGING_LEVEL_ROOT automatically)
    LOGGING_LEVEL_ROOT=INFO \
    # CORS allowed origins (comma-separated; * = allow all)
    CORS_ALLOWED_ORIGINS=* \
<#else>
    # Port (Quarkus reads QUARKUS_HTTP_PORT automatically)
    QUARKUS_HTTP_PORT=8080 \
    # Log level (Quarkus reads QUARKUS_LOG_LEVEL automatically)
    QUARKUS_LOG_LEVEL=INFO \
    # CORS allowed origins (comma-separated; * = allow all)
    CORS_ALLOWED_ORIGINS=* \
</#if>
<#if flags.enableTelemetry>
<#if backendFlavor == "spring-boot">
    # Distributed tracing — OTLP exporter (Spring Boot)
    MANAGEMENT_TRACING_ENABLED=true \
    MANAGEMENT_TRACING_SAMPLING_PROBABILITY=1.0 \
    MANAGEMENT_OTLP_TRACING_ENDPOINT=http://localhost:4318/v1/traces \
<#else>
    # Distributed tracing — OTLP exporter (Quarkus)
    QUARKUS_OTEL_ENABLED=true \
    QUARKUS_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://localhost:4317 \
    QUARKUS_OTEL_SERVICE_NAME=${id} \
</#if>
</#if>
<#if (flags.securityLevel!"") == "apiKey">
    # API key validation — empty value disables validation
    API_KEY="" \
</#if>
    # Per-endpoint backend URLs — default to schema-defined values
<#list endpoints as endpoint>
<#if endpoint?has_next>
    BACKEND_URL_${pathToEnvKey(endpoint.path)}="${endpoint.backendUrl}" \
<#else>
    BACKEND_URL_${pathToEnvKey(endpoint.path)}="${endpoint.backendUrl}"
</#if>
</#list>

# Health probe — validated by Docker, docker-compose, and used as a fallback.
# K8s/OpenShift should define liveness/readiness probes in the Deployment manifest instead.
<#if backendFlavor == "spring-boot">
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health/liveness || exit 1
<#else>
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8080/q/health/live || exit 1
</#if>

# exec form via sh so that $JAVA_OPTS is expanded and the JVM receives SIGTERM directly.
ENTRYPOINT ["sh", "-c", "exec java \
  -XX:+UseContainerSupport \
  -XX:MaxRAMPercentage=75.0 \
  -Djava.security.egd=file:/dev/./urandom \
  -Dfile.encoding=UTF-8 \
  $JAVA_OPTS \
  -jar /app/app.jar"]
