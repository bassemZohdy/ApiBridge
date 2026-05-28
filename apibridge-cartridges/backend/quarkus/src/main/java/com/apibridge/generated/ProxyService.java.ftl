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
<#if (flags.enableResponseCache)!false>
import com.github.ben-manes.caffeine.cache.Cache;
import com.github.ben-manes.caffeine.cache.Caffeine;
import java.util.concurrent.TimeUnit;
</#if>

import java.util.Set;
import java.util.concurrent.TimeUnit;

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
    private Cache<String, String> responseCache;
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
        this.responseCache = Caffeine.newBuilder()
                .maximumSize(Long.parseLong(System.getenv().getOrDefault("CACHE_MAX_SIZE", "1000")))
                .expireAfterWrite(Long.parseLong(System.getenv().getOrDefault("CACHE_TTL_SECONDS", "60")), TimeUnit.SECONDS)
                .build();
</#if>
    }

    @PreDestroy
    void destroy() {
        if (client != null) {
            client.close();
        }
    }

    public Response forward(String targetUrl, String method, String requestBody, HttpHeaders headers) {
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

            String contentType = headers.getHeaderString(HttpHeaders.CONTENT_TYPE);
            if (contentType == null) {
                contentType = MediaType.APPLICATION_JSON;
            }

<#if (flags.enableCircuitBreaker)!false>
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
<#else>
            if (requestBody != null && !requestBody.isBlank()) {
                upstream = target.method(method.toUpperCase(), Entity.entity(requestBody, contentType));
            } else {
                upstream = target.method(method.toUpperCase());
            }
</#if>

            String body = upstream.readEntity(String.class);
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
<#if (flags.enableAuditLog)!false>

            successEvent.fireAsync(new ProxySuccessEvent(
                    correlationId,
                    upstream.getStatus(),
                    body,
                    System.currentTimeMillis() - startMs));
</#if>

            return builder.build();

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
