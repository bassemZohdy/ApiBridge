<#if (flags.enableAuditLog)!false>
package com.apibridge.generated.audit;

import io.quarkus.redis.datasource.ReactiveRedisDataSource;
import io.quarkus.redis.datasource.stream.XAddArgs;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.ObservesAsync;

import java.util.Map;

@ApplicationScoped
public class RedisAuditPublisher {

    static final String STREAM_KEY = "apibridge:audit";

    private final ReactiveRedisDataSource redis;

    public RedisAuditPublisher(ReactiveRedisDataSource redis) {
        this.redis = redis;
    }

    void onSend(@ObservesAsync ProxySendEvent e) {
        redis.stream(String.class).xadd(
                STREAM_KEY,
                new XAddArgs(),
                Map.of(
                        "eventType", "SEND",
                        "correlationId", e.getCorrelationId(),
                        "endpoint", e.getEndpoint(),
                        "method", e.getMethod(),
                        "requestBody", e.getRequestBody() != null ? e.getRequestBody() : "",
                        "sentAt", e.getSentAt().toString()))
                .subscribe().with(id -> {}, t -> {});
    }

    void onSuccess(@ObservesAsync ProxySuccessEvent e) {
        redis.stream(String.class).xadd(
                STREAM_KEY,
                new XAddArgs(),
                Map.of(
                        "eventType", "SUCCESS",
                        "correlationId", e.getCorrelationId(),
                        "responseStatus", String.valueOf(e.getResponseStatus()),
                        "responseBody", e.getResponseBody() != null ? e.getResponseBody() : "",
                        "durationMs", String.valueOf(e.getDurationMs()),
                        "completedAt", e.getCompletedAt().toString()))
                .subscribe().with(id -> {}, t -> {});
    }

    void onFail(@ObservesAsync ProxyFailEvent e) {
        redis.stream(String.class).xadd(
                STREAM_KEY,
                new XAddArgs(),
                Map.of(
                        "eventType", "FAIL",
                        "correlationId", e.getCorrelationId(),
                        "errorMessage", e.getErrorMessage() != null ? e.getErrorMessage() : "",
                        "durationMs", String.valueOf(e.getDurationMs()),
                        "completedAt", e.getCompletedAt().toString()))
                .subscribe().with(id -> {}, t -> {});
    }
}
</#if>
