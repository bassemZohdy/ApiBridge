replicaCount: 1

image:
  repository: ${id}
  pullPolicy: IfNotPresent
  tag: "latest"

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: false
  className: ""
  annotations: {}
  host: ${id}.local
  path: /
  pathType: Prefix
  tls: []

resources: {}

env:
  MOCK_MODE: "false"
  BLOCK_TRAFFIC: "false"
  DEBUG_MODE: "false"
  CORS_ALLOWED_ORIGINS: "*"
  PAGINATION_PAGE_PARAM: "page"
  PAGINATION_SIZE_PARAM: "size"
  PAGINATION_DEFAULT_PAGE_SIZE: "20"
  PAGINATION_SORT_PARAM: "sort"
  PAGINATION_DIRECTION_PARAM: "dir"
  CUSTOM_CSS_PATH: ""
<#if (flags.securityLevel!"") == "apiKey">
  API_KEY: ""
</#if>
<#if (flags.securityLevel!"") == "bearer-token">
  AUTH_SERVER_URL: ""
</#if>
<#if (flags.enableTelemetry)!false>
  MANAGEMENT_TRACING_ENABLED: "true"
  MANAGEMENT_TRACING_SAMPLING_PROBABILITY: "1.0"
  MANAGEMENT_OTLP_TRACING_ENDPOINT: "http://localhost:4318/v1/traces"
</#if>
<#if (flags.enableRateLimiter)!false>
  RATE_LIMIT_PERMITS: "10"
  RATE_LIMIT_PERIOD_SECONDS: "1"
  RATE_LIMIT_TIMEOUT_MILLIS: "5000"
</#if>
<#if (flags.enableResponseCache)!false>
  CACHE_TTL_SECONDS: "60"
  CACHE_MAX_SIZE: "1000"
  CACHE_REDIS_URL: ""
</#if>
<#if (flags.enableCircuitBreaker)!false>
  CB_FAILURE_RATE_THRESHOLD: "50"
  CB_SLIDING_WINDOW_SIZE: "10"
  CB_WAIT_DURATION_SECONDS: "30"
  CB_RETRY_MAX_ATTEMPTS: "3"
  CB_RETRY_WAIT_MS: "500"
</#if>
<#if (flags.enableHealthCheck)!false>
  HEALTH_CHECK_INTERVAL_SECONDS: "30"
  HEALTH_CHECK_TIMEOUT_MS: "3000"
</#if>
<#if (flags.enableSearch)!false>
  SEARCH_PARAM: "q"
</#if>
<#if (flags.enableAuditLog)!false>
  SPRING_DATA_REDIS_URL: "redis://redis:6379"
  SPRING_DATA_MONGODB_URI: "mongodb://mongo:27017"
  SPRING_DATA_MONGODB_DATABASE: "${id}-audit"
  AUDIT_LOG_TTL_DAYS: "30"
</#if>
<#if (flags.enableOidc)!false>
  OIDC_ISSUER_URI: "${oidcIssuerUri}"
</#if>
