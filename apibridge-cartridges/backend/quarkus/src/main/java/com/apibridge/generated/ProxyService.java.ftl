package com.apibridge.generated;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.config.inject.ConfigProperty;
<#if (flags.enableAuditLog)!false>
import com.apibridge.generated.audit.ProxySendEvent;
import com.apibridge.generated.audit.ProxySuccessEvent;
import com.apibridge.generated.audit.ProxyFailEvent;
import jakarta.enterprise.event.Event;
import jakarta.inject.Inject;
import java.util.UUID;
</#if>
<#if (flags.enableCircuitBreaker)!false>
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.retry.RetryRegistry;
import java.time.Duration;
import java.util.function.Supplier;
</#if>
<#if (flags.enableRateLimiter)!false>
import io.github.resilience4j.ratelimiter.RateLimiter;
import io.github.resilience4j.ratelimiter.RateLimiterConfig;
import io.github.resilience4j.ratelimiter.RateLimiterRegistry;
import io.github.resilience4j.ratelimiter.RequestNotPermitted;
import java.time.Duration;
import java.util.function.Supplier;
</#if>
<#if (flags.enableResponseCache)!false>
import com.github.ben-manes.caffeine.cache.Caffeine;
import java.util.concurrent.TimeUnit;
<#if (flags.enableAuditLog)!false>
import io.quarkus.redis.client.RedisClient;
import io.quarkus.redis.client.reactive.ReactiveRedisDataSource;
import io.vertx.redis.client.Response;
</#if>
</#if>

import java.util.Set;
import java.util.concurrent.TimeUnit;
<#if (flags.enableTransform)!false>
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
</#if>

@ApplicationScoped
public class ProxyService {

    private static final Set<String> HOP_BY_HOP = Set.of(
            "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
            "te", "trailers", "transfer-encoding", "upgrade", "content-length", "host"
    );

    @ConfigProperty(name = "proxy.connect-timeout", defaultValue = "5000")
    int connectTimeout;

    @ConfigProperty(name = "proxy.read-timeout", defaultValue = "30000")
    int readTimeout;

    private Client client;
<#if (flags.enableAuditLog)!false>

    @Inject
    Event<ProxySendEvent> sendEvent;

    @Inject
    Event<ProxySuccessEvent> successEvent;

    @Inject
    Event<ProxyFailEvent> failEvent;
</#if>
<#if (flags.enableCircuitBreaker)!false>
    private CircuitBreaker circuitBreaker;
    private Retry retry;
</#if>
<#if (flags.enableResponseCache)!false>
    private ResponseCache responseCache;

    interface ResponseCache {
        String getIfPresent(String key);
        void put(String key, String value);
        void invalidateAll();
    }

    static class CaffeineResponseCache implements ResponseCache {
        private final com.github.ben-manes.caffeine.cache.Cache<String, String> cache;
        CaffeineResponseCache(long ttlSeconds, long maxSize) {
            this.cache = Caffeine.newBuilder()
                    .maximumSize(maxSize)
                    .expireAfterWrite(ttlSeconds, TimeUnit.SECONDS)
                    .build();
        }
        @Override public String getIfPresent(String key) { return cache.getIfPresent(key); }
        @Override public void put(String key, String value) { cache.put(key, value); }
        @Override public void invalidateAll() { cache.invalidateAll(); }
    }
<#if (flags.enableAuditLog)!false>

    static class RedisResponseCache implements ResponseCache {
        private final RedisClient redisClient;
        private final long ttlSeconds;
        RedisResponseCache(RedisClient redisClient, long ttlSeconds) {
            this.redisClient = redisClient;
            this.ttlSeconds = ttlSeconds;
        }
        @Override public String getIfPresent(String key) {
            Response resp = redisClient.get(key);
            return resp != null ? resp.toString() : null;
        }
        @Override public void put(String key, String value) {
            redisClient.setex(key, String.valueOf(ttlSeconds), value);
        }
        @Override public void invalidateAll() { redisClient.flushdb(); }
    }
</#if>
</#if>
<#if (flags.enableRateLimiter)!false>
    private RateLimiter rateLimiter;
</#if>

    @PostConstruct
    void init() {
        client = ClientBuilder.newBuilder()
                .connectTimeout(connectTimeout, TimeUnit.MILLISECONDS)
                .readTimeout(readTimeout, TimeUnit.MILLISECONDS)
                .build();
<#if (flags.enableCircuitBreaker)!false>
        CircuitBreakerConfig cbConfig = CircuitBreakerConfig.custom()
                .failureRateThreshold(Float.parseFloat(System.getenv().getOrDefault("CB_FAILURE_RATE_THRESHOLD", "50")))
                .waitDurationInOpenState(Duration.ofSeconds(Long.parseLong(System.getenv().getOrDefault("CB_WAIT_DURATION_SECONDS", "30"))))
                .slidingWindowSize(Integer.parseInt(System.getenv().getOrDefault("CB_SLIDING_WINDOW_SIZE", "10")))
                .build();
        RetryConfig retryConfig = RetryConfig.custom()
                .maxAttempts(Integer.parseInt(System.getenv().getOrDefault("CB_RETRY_MAX_ATTEMPTS", "3")))
                .waitDuration(Duration.ofMillis(Long.parseLong(System.getenv().getOrDefault("CB_RETRY_WAIT_MS", "500"))))
                .build();
        this.circuitBreaker = CircuitBreakerRegistry.of(cbConfig).circuitBreaker("proxy");
        this.retry = RetryRegistry.of(retryConfig).retry("proxy");
</#if>
<#if (flags.enableResponseCache)!false>
        String redisUrl = System.getenv().getOrDefault("CACHE_REDIS_URL", "");
        long cacheTtl = Long.parseLong(System.getenv().getOrDefault("CACHE_TTL_SECONDS", "60"));
        long cacheMaxSize = Long.parseLong(System.getenv().getOrDefault("CACHE_MAX_SIZE", "1000"));
        if (!redisUrl.isBlank()) {
<#if (flags.enableAuditLog)!false>
            this.responseCache = new RedisResponseCache(redisClient, cacheTtl);
<#else>
            this.responseCache = new CaffeineResponseCache(cacheTtl, cacheMaxSize);
</#if>
        } else {
            this.responseCache = new CaffeineResponseCache(cacheTtl, cacheMaxSize);
        }
</#if>
<#if (flags.enableRateLimiter)!false>
        RateLimiterConfig rlConfig = RateLimiterConfig.custom()
                .limitForPeriod(Integer.parseInt(System.getenv().getOrDefault("RATE_LIMIT_PERMITS", "10")))
                .limitRefreshPeriod(Duration.ofSeconds(Long.parseLong(System.getenv().getOrDefault("RATE_LIMIT_PERIOD_SECONDS", "1"))))
                .timeoutDuration(Duration.ofMillis(Long.parseLong(System.getenv().getOrDefault("RATE_LIMIT_TIMEOUT_MILLIS", "5000"))))
                .build();
        this.rateLimiter = RateLimiterRegistry.of(rlConfig).rateLimiter("proxy");
</#if>
    }

    @PreDestroy
    void destroy() {
        if (client != null) {
            client.close();
        }
    }

<#if (flags.enableTransform)!false>
    private static final ObjectMapper MAPPER = new ObjectMapper();

    static MultivaluedMap<String, String> applyHeaderTransforms(
            MultivaluedMap<String, String> headers,
            Map<String, String> add,
            List<String> remove,
            Map<String, String> rename) {
        if (add != null) add.forEach((k, v) -> headers.putSingle(k, v));
        if (remove != null) remove.forEach(headers::remove);
        if (rename != null) {
            Map<String, String> copied = new HashMap<>();
            rename.forEach((oldName, newName) -> {
                String val = headers.getFirst(oldName);
                if (val != null) {
                    copied.put(newName, val);
                    headers.remove(oldName);
                }
            });
            copied.forEach((k, v) -> headers.putSingle(k, v));
        }
        return headers;
    }

    static String applyFieldTransforms(String body,
                                        Map<String, String> rename,
                                        List<String> remove) {
        if (body == null || body.isBlank()) return body;
        if ((rename == null || rename.isEmpty()) && (remove == null || remove.isEmpty())) return body;
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> map = MAPPER.readValue(body, Map.class);
            if (remove != null) remove.forEach(map::remove);
            if (rename != null) {
                Map<String, Object> renamed = new HashMap<>();
                rename.forEach((oldName, newName) -> {
                    Object val = map.remove(oldName);
                    if (val != null) renamed.put(newName, val);
                });
                map.putAll(renamed);
            }
            return MAPPER.writeValueAsString(map);
        } catch (Exception e) {
            return body;
        }
    }

</#if>
    public Response forward(String targetUrl, String method, String requestBody, HttpHeaders headers<#if (flags.enableTransform)!false>,
            Map<String, String> reqHeaderAdd,
            List<String> reqHeaderRemove,
            Map<String, String> reqHeaderRename,
            Map<String, String> reqFieldRename,
            List<String> reqFieldRemove,
            Map<String, String> resHeaderAdd,
            List<String> resHeaderRemove,
            Map<String, String> resHeaderRename,
            Map<String, String> resFieldRename,
            List<String> resFieldRemove</#if>) {
<#if (flags.enableResponseCache)!false>
        if ("GET".equalsIgnoreCase(method)) {
            String cached = responseCache.getIfPresent(targetUrl);
            if (cached != null) {
                return Response.ok(cached).type(MediaType.APPLICATION_JSON).build();
            }
        } else {
            responseCache.invalidateAll();
        }
</#if>
<#if (flags.enableAuditLog)!false>
        String correlationId = UUID.randomUUID().toString();
        sendEvent.fireAsync(new ProxySendEvent(correlationId, targetUrl, method, requestBody));
        long startMs = System.currentTimeMillis();
</#if>
        Response upstream = null;
        try {
            var target = client.target(targetUrl).request();

            MultivaluedMap<String, String> requestHeaders = headers.getRequestHeaders();
            for (var entry : requestHeaders.entrySet()) {
                String name = entry.getKey().toLowerCase();
                if (!HOP_BY_HOP.contains(name)) {
                    for (String value : entry.getValue()) {
                        target = target.header(entry.getKey(), value);
                    }
                }
            }
<#if (flags.enableTransform)!false>
            applyHeaderTransforms(requestHeaders, reqHeaderAdd, reqHeaderRemove, reqHeaderRename);
            requestBody = applyFieldTransforms(requestBody, reqFieldRename, reqFieldRemove);
            var transformTarget = client.target(targetUrl).request();
            for (var entry : requestHeaders.entrySet()) {
                for (String value : entry.getValue()) {
                    transformTarget = transformTarget.header(entry.getKey(), value);
                }
            }
            target = transformTarget;
</#if>

            String contentType = headers.getHeaderString(HttpHeaders.CONTENT_TYPE);
            if (contentType == null) {
                contentType = MediaType.APPLICATION_JSON;
            }

<#if (flags.enableRateLimiter)!false && (flags.enableCircuitBreaker)!false>
            final var targetFinal = target;
            final String methodUpper = method.toUpperCase();
            final String bodyFinal = requestBody;
            final String ctFinal = contentType;
            Supplier<Response> innerCall = CircuitBreaker.decorateSupplier(circuitBreaker,
                    Retry.decorateSupplier(retry, () -> {
                        if (bodyFinal != null && !bodyFinal.isBlank()) {
                            return targetFinal.method(methodUpper, Entity.entity(bodyFinal, ctFinal));
                        } else {
                            return targetFinal.method(methodUpper);
                        }
                    }));
            Supplier<Response> call = RateLimiter.decorateSupplier(rateLimiter, innerCall);
            upstream = call.get();
<#elseif (flags.enableCircuitBreaker)!false>
            final var targetFinal = target;
            final String methodUpper = method.toUpperCase();
            final String bodyFinal = requestBody;
            final String ctFinal = contentType;
            Supplier<Response> call = CircuitBreaker.decorateSupplier(circuitBreaker,
                    Retry.decorateSupplier(retry, () -> {
                        if (bodyFinal != null && !bodyFinal.isBlank()) {
                            return targetFinal.method(methodUpper, Entity.entity(bodyFinal, ctFinal));
                        } else {
                            return targetFinal.method(methodUpper);
                        }
                    }));
            upstream = call.get();
<#elseif (flags.enableRateLimiter)!false>
            final var targetFinal = target;
            final String methodUpper = method.toUpperCase();
            final String bodyFinal = requestBody;
            final String ctFinal = contentType;
            Supplier<Response> call = RateLimiter.decorateSupplier(rateLimiter, () -> {
                if (bodyFinal != null && !bodyFinal.isBlank()) {
                    return targetFinal.method(methodUpper, Entity.entity(bodyFinal, ctFinal));
                } else {
                    return targetFinal.method(methodUpper);
                }
            });
            upstream = call.get();
<#else>
            if (requestBody != null && !requestBody.isBlank()) {
                upstream = target.method(method.toUpperCase(), Entity.entity(requestBody, contentType));
            } else {
                upstream = target.method(method.toUpperCase());
            }
</#if>

            String body = upstream.readEntity(String.class);
<#if (flags.enableTransform)!false>
            body = applyFieldTransforms(body, resFieldRename, resFieldRemove);
</#if>
<#if (flags.enableResponseCache)!false>
            if ("GET".equalsIgnoreCase(method) && body != null) {
                responseCache.put(targetUrl, body);
            }
</#if>

            Response.ResponseBuilder builder = Response.status(upstream.getStatus()).entity(body);

            MultivaluedMap<String, Object> upstreamHeaders = upstream.getHeaders();
            for (var entry : upstreamHeaders.entrySet()) {
                String name = entry.getKey().toLowerCase();
                if (!HOP_BY_HOP.contains(name)) {
                    for (Object value : entry.getValue()) {
                        builder.header(entry.getKey(), value);
                    }
                }
            }
<#if (flags.enableTransform)!false>
            if (resHeaderAdd != null) resHeaderAdd.forEach((k, v) -> builder.header(k, v));
            if (resHeaderRemove != null) {
                MultivaluedMap<String, Object> filtered = new jakarta.ws.rs.core.MultivaluedHashMap<>();
                upstreamHeaders.forEach((name, values) -> {
                    if (!resHeaderRemove.contains(name)) {
                        filtered.put(name, values);
                    }
                });
            }
            if (resHeaderRename != null) {
                resHeaderRename.forEach((oldName, newName) -> {
                    var values = upstreamHeaders.get(oldName);
                    if (values != null) {
                        builder.getHeaders().remove(oldName);
                        values.forEach(v -> builder.header(newName, v.toString()));
                    }
                });
            }
</#if>
<#if (flags.enableAuditLog)!false>

            successEvent.fireAsync(new ProxySuccessEvent(
                    correlationId,
                    upstream.getStatus(),
                    body,
                    System.currentTimeMillis() - startMs));
</#if>

            return builder.build();

<#if (flags.enableRateLimiter)!false>
        } catch (RequestNotPermitted e) {
            return Response.status(429)
                    .entity("{\"error\":\"Too Many Requests\",\"rateLimit\":\"exceeded\"}")
                    .type(MediaType.APPLICATION_JSON)
                    .build();
</#if>
<#if (flags.enableCircuitBreaker)!false>
        } catch (CallNotPermittedException e) {
            return Response.status(503)
                    .entity("{\"error\":\"Service Unavailable\",\"circuit\":\"open\"}")
                    .type(MediaType.APPLICATION_JSON)
                    .build();
</#if>
        } catch (Exception e) {
<#if (flags.enableAuditLog)!false>
            failEvent.fireAsync(new ProxyFailEvent(
                    correlationId,
                    e.getMessage(),
                    System.currentTimeMillis() - startMs));
</#if>
            return Response.status(502)
                    .entity("{\"error\":\"Bad Gateway\"}")
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        } finally {
            if (upstream != null) {
                upstream.close();
            }
        }
    }
}
