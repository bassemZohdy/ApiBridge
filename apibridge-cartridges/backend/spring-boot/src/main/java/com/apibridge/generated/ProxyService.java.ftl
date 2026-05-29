package com.apibridge.generated;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestTemplate;
<#if (flags.enableAuditLog)!false>
import org.springframework.context.ApplicationEventPublisher;
import com.apibridge.generated.audit.ProxySendEvent;
import com.apibridge.generated.audit.ProxySuccessEvent;
import com.apibridge.generated.audit.ProxyFailEvent;
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
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
</#if>
</#if>

import jakarta.servlet.http.HttpServletRequest;
import java.util.Enumeration;
import java.util.Set;
<#if (flags.enableTransform)!false>
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
</#if>

@Service
public class ProxyService {

    private static final Set<String> HOP_BY_HOP = Set.of(
            "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
            "te", "trailers", "transfer-encoding", "upgrade", "content-length", "host"
    );

    @Value("${r"${proxy.connect-timeout:5000}"}")
    private int connectTimeout;

    @Value("${r"${proxy.read-timeout:30000}"}")
    private int readTimeout;

    private final RestTemplate restTemplate;
<#if (flags.enableAuditLog)!false>
    private final ApplicationEventPublisher events;
</#if>
<#if (flags.enableCircuitBreaker)!false>
    private final CircuitBreaker circuitBreaker;
    private final Retry retry;
</#if>
<#if (flags.enableResponseCache)!false>
    private final ResponseCache responseCache;

    interface ResponseCache {
        String getIfPresent(String key);
        void put(String key, String value);
        void invalidateAll();
    }

    private static ResponseCache buildResponseCache() {
        String redisUrl = System.getenv().getOrDefault("CACHE_REDIS_URL", "");
        long ttlSeconds = Long.parseLong(System.getenv().getOrDefault("CACHE_TTL_SECONDS", "60"));
        long maxSize = Long.parseLong(System.getenv().getOrDefault("CACHE_MAX_SIZE", "1000"));
        if (!redisUrl.isBlank()) {
<#if (flags.enableAuditLog)!false>
            var config = new RedisStandaloneConfiguration(redisUrl);
            var factory = new LettuceConnectionFactory(config);
            factory.afterPropertiesSet();
            var template = new StringRedisTemplate(factory);
            return new RedisResponseCache(template, ttlSeconds);
<#else>
            return new CaffeineResponseCache(ttlSeconds, maxSize);
</#if>
        }
        return new CaffeineResponseCache(ttlSeconds, maxSize);
    }

    private static class CaffeineResponseCache implements ResponseCache {
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

    private static class RedisResponseCache implements ResponseCache {
        private final StringRedisTemplate template;
        private final long ttlSeconds;
        RedisResponseCache(StringRedisTemplate template, long ttlSeconds) {
            this.template = template;
            this.ttlSeconds = ttlSeconds;
        }
        @Override public String getIfPresent(String key) { return template.opsForValue().get(key); }
        @Override public void put(String key, String value) {
            template.opsForValue().set(key, value, java.time.Duration.ofSeconds(ttlSeconds));
        }
        @Override public void invalidateAll() { template.getConnectionFactory().getConnection().flushDb(); }
    }
</#if>
</#if>
<#if (flags.enableRateLimiter)!false>
    private final RateLimiter rateLimiter;
</#if>

<#if (flags.enableAuditLog)!false>
    public ProxyService(ApplicationEventPublisher events) {
        this.restTemplate = new RestTemplate();
        this.events = events;
<#if (flags.enableCircuitBreaker)!false>
        this.circuitBreaker = buildCircuitBreaker();
        this.retry = buildRetry();
</#if>
<#if (flags.enableResponseCache)!false>
        this.responseCache = buildResponseCache();
</#if>
<#if (flags.enableRateLimiter)!false>
        this.rateLimiter = buildRateLimiter();
</#if>
    }
<#else>
    public ProxyService() {
        this.restTemplate = new RestTemplate();
<#if (flags.enableCircuitBreaker)!false>
        this.circuitBreaker = buildCircuitBreaker();
        this.retry = buildRetry();
</#if>
<#if (flags.enableResponseCache)!false>
        this.responseCache = buildResponseCache();
</#if>
<#if (flags.enableRateLimiter)!false>
        this.rateLimiter = buildRateLimiter();
</#if>
    }
</#if>
<#if (flags.enableCircuitBreaker)!false>

    private static CircuitBreaker buildCircuitBreaker() {
        CircuitBreakerConfig config = CircuitBreakerConfig.custom()
                .failureRateThreshold(Float.parseFloat(System.getenv().getOrDefault("CB_FAILURE_RATE_THRESHOLD", "50")))
                .waitDurationInOpenState(Duration.ofSeconds(Long.parseLong(System.getenv().getOrDefault("CB_WAIT_DURATION_SECONDS", "30"))))
                .slidingWindowSize(Integer.parseInt(System.getenv().getOrDefault("CB_SLIDING_WINDOW_SIZE", "10")))
                .build();
        return CircuitBreakerRegistry.of(config).circuitBreaker("proxy");
    }

    private static Retry buildRetry() {
        RetryConfig config = RetryConfig.custom()
                .maxAttempts(Integer.parseInt(System.getenv().getOrDefault("CB_RETRY_MAX_ATTEMPTS", "3")))
                .waitDuration(Duration.ofMillis(Long.parseLong(System.getenv().getOrDefault("CB_RETRY_WAIT_MS", "500"))))
                .build();
        return RetryRegistry.of(config).retry("proxy");
    }
</#if>
<#if (flags.enableRateLimiter)!false>

    private static RateLimiter buildRateLimiter() {
        RateLimiterConfig config = RateLimiterConfig.custom()
                .limitForPeriod(Integer.parseInt(System.getenv().getOrDefault("RATE_LIMIT_PERMITS", "10")))
                .limitRefreshPeriod(Duration.ofSeconds(Long.parseLong(System.getenv().getOrDefault("RATE_LIMIT_PERIOD_SECONDS", "1"))))
                .timeoutDuration(Duration.ofMillis(Long.parseLong(System.getenv().getOrDefault("RATE_LIMIT_TIMEOUT_MILLIS", "5000"))))
                .build();
        return RateLimiterRegistry.of(config).rateLimiter("proxy");
    }
</#if>

<#if (flags.enableTransform)!false>
    private static final ObjectMapper MAPPER = new ObjectMapper();

    static void applyHeaderTransforms(HttpHeaders headers,
                                       Map<String, String> add,
                                       List<String> remove,
                                       Map<String, String> rename) {
        if (add != null) add.forEach(headers::set);
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
            copied.forEach(headers::set);
        }
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
    public ResponseEntity<String> forward(
            String targetUrl,
            String method,
            String requestBody,
            HttpServletRequest request<#if (flags.enableTransform)!false>,
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

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(connectTimeout);
        factory.setReadTimeout(readTimeout);
        restTemplate.setRequestFactory(factory);

        String urlWithQuery = targetUrl;
        String queryString = request.getQueryString();
        if (queryString != null && !queryString.isBlank()) {
            urlWithQuery = targetUrl + (targetUrl.contains("?") ? "&" : "?") + queryString;
        }

        HttpHeaders outboundHeaders = new HttpHeaders();
        Enumeration<String> headerNames = request.getHeaderNames();
        if (headerNames != null) {
            while (headerNames.hasMoreElements()) {
                String name = headerNames.nextElement();
                if (!HOP_BY_HOP.contains(name.toLowerCase())) {
                    outboundHeaders.set(name, request.getHeader(name));
                }
            }
        }

        HttpEntity<String> entity = new HttpEntity<>(requestBody, outboundHeaders);
<#if (flags.enableTransform)!false>
        applyHeaderTransforms(outboundHeaders, reqHeaderAdd, reqHeaderRemove, reqHeaderRename);
        String transformedBody = applyFieldTransforms(requestBody, reqFieldRename, reqFieldRemove);
        entity = new HttpEntity<>(transformedBody, outboundHeaders);
</#if>
        HttpMethod httpMethod = HttpMethod.valueOf(method.toUpperCase());
<#if (flags.enableResponseCache)!false>

        if ("GET".equalsIgnoreCase(method)) {
            String cached = responseCache.getIfPresent(urlWithQuery);
            if (cached != null) {
                return ResponseEntity.ok().body(cached);
            }
        } else {
            responseCache.invalidateAll();
        }
</#if>
<#if (flags.enableAuditLog)!false>

        String correlationId = UUID.randomUUID().toString();
        events.publishEvent(new ProxySendEvent(correlationId, urlWithQuery, method, requestBody));
        long startMs = System.currentTimeMillis();
</#if>

        try {
<#if (flags.enableRateLimiter)!false && (flags.enableCircuitBreaker)!false>
            Supplier<ResponseEntity<String>> innerCall = CircuitBreaker.decorateSupplier(circuitBreaker,
                    Retry.decorateSupplier(retry,
                            () -> restTemplate.exchange(urlWithQuery, httpMethod, entity, String.class)));
            Supplier<ResponseEntity<String>> call = RateLimiter.decorateSupplier(rateLimiter, innerCall);
            ResponseEntity<String> upstream = call.get();
<#elseif (flags.enableCircuitBreaker)!false>
            Supplier<ResponseEntity<String>> call = CircuitBreaker.decorateSupplier(circuitBreaker,
                    Retry.decorateSupplier(retry,
                            () -> restTemplate.exchange(urlWithQuery, httpMethod, entity, String.class)));
            ResponseEntity<String> upstream = call.get();
<#elseif (flags.enableRateLimiter)!false>
            Supplier<ResponseEntity<String>> call = RateLimiter.decorateSupplier(rateLimiter,
                    () -> restTemplate.exchange(urlWithQuery, httpMethod, entity, String.class));
            ResponseEntity<String> upstream = call.get();
<#else>
            ResponseEntity<String> upstream = restTemplate.exchange(
                    urlWithQuery, httpMethod, entity, String.class);
</#if>

            HttpHeaders responseHeaders = new HttpHeaders();
            upstream.getHeaders().forEach((name, values) -> {
                if (!HOP_BY_HOP.contains(name.toLowerCase())) {
                    values.forEach(v -> responseHeaders.add(name, v));
                }
            });
<#if (flags.enableTransform)!false>
            applyHeaderTransforms(responseHeaders, resHeaderAdd, resHeaderRemove, resHeaderRename);
            String transformedResponseBody = applyFieldTransforms(upstream.getBody(), resFieldRename, resFieldRemove);
</#if>
<#if (flags.enableResponseCache)!false>
            if ("GET".equalsIgnoreCase(method) && upstream.getBody() != null) {
                responseCache.put(urlWithQuery, upstream.getBody());
            }
</#if>
<#if (flags.enableAuditLog)!false>

            events.publishEvent(new ProxySuccessEvent(
                    correlationId,
                    upstream.getStatusCode().value(),
                    upstream.getBody(),
                    System.currentTimeMillis() - startMs));
</#if>

            return ResponseEntity.status(upstream.getStatusCode())
                    .headers(responseHeaders)
                    .body(<#if (flags.enableTransform)!false>transformedResponseBody<#else>upstream.getBody()</#if>);

<#if (flags.enableRateLimiter)!false>
        } catch (RequestNotPermitted e) {
            return ResponseEntity
                    .status(429)
                    .body("{\"error\":\"Too Many Requests\",\"rateLimit\":\"exceeded\"}");
</#if>
<#if (flags.enableCircuitBreaker)!false>
        } catch (CallNotPermittedException e) {
            return ResponseEntity
                    .status(503)
                    .body("{\"error\":\"Service Unavailable\",\"circuit\":\"open\"}");
</#if>
        } catch (RestClientResponseException ex) {
<#if (flags.enableAuditLog)!false>
            events.publishEvent(new ProxyFailEvent(
                    correlationId,
                    ex.getStatusCode().value() + " " + ex.getStatusText(),
                    System.currentTimeMillis() - startMs));
</#if>
            return ResponseEntity
                    .status(ex.getStatusCode())
                    .body(ex.getResponseBodyAsString());
        } catch (Exception ex) {
<#if (flags.enableAuditLog)!false>
            events.publishEvent(new ProxyFailEvent(
                    correlationId,
                    ex.getMessage(),
                    System.currentTimeMillis() - startMs));
</#if>
            return ResponseEntity
                    .status(502)
                    .body("{\"error\":\"Bad Gateway\"}");
        }
    }
}
