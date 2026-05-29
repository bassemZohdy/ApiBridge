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
  DEBUG_MODE: "false"
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
