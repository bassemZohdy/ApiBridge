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
<#if (flags.enableResponseCache)!false>
import com.github.ben-manes.caffeine.cache.Cache;
import com.github.ben-manes.caffeine.cache.Caffeine;
import java.util.concurrent.TimeUnit;
</#if>

import jakarta.servlet.http.HttpServletRequest;
import java.util.Enumeration;
import java.util.Set;

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
    private final Cache<String, String> responseCache;
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
<#if (flags.enableResponseCache)!false>

    private static Cache<String, String> buildResponseCache() {
        return Caffeine.newBuilder()
                .maximumSize(Long.parseLong(System.getenv().getOrDefault("CACHE_MAX_SIZE", "1000")))
                .expireAfterWrite(Long.parseLong(System.getenv().getOrDefault("CACHE_TTL_SECONDS", "60")), TimeUnit.SECONDS)
                .build();
    }
</#if>

    public ResponseEntity<String> forward(
            String targetUrl,
            String method,
            String requestBody,
            HttpServletRequest request) {

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
<#if (flags.enableCircuitBreaker)!false>
            Supplier<ResponseEntity<String>> call = CircuitBreaker.decorateSupplier(circuitBreaker,
                    Retry.decorateSupplier(retry,
                            () -> restTemplate.exchange(urlWithQuery, httpMethod, entity, String.class)));
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
                    .body(upstream.getBody());

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
