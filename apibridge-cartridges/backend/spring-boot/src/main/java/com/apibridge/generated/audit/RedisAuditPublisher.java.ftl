<#if (flags.enableAuditLog)!false>
package com.apibridge.generated.audit;

import org.springframework.context.event.EventListener;
import org.springframework.data.redis.connection.stream.StreamRecords;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

@Component
public class RedisAuditPublisher {

    static final String STREAM_KEY = "apibridge:audit";

    private final StringRedisTemplate redis;

    public RedisAuditPublisher(StringRedisTemplate redis) {
        this.redis = redis;
    }

    @EventListener
    @Async
    public void onSend(ProxySendEvent e) {
        Map<String, String> fields = new HashMap<>();
        fields.put("eventType", "SEND");
        fields.put("correlationId", e.getCorrelationId());
        fields.put("endpoint", e.getEndpoint());
        fields.put("method", e.getMethod());
        fields.put("requestBody", e.getRequestBody() != null ? e.getRequestBody() : "");
        fields.put("sentAt", e.getSentAt().toString());
        redis.opsForStream().add(StreamRecords.newRecord().ofMap(fields).withStreamKey(STREAM_KEY));
    }

    @EventListener
    @Async
    public void onSuccess(ProxySuccessEvent e) {
        Map<String, String> fields = new HashMap<>();
        fields.put("eventType", "SUCCESS");
        fields.put("correlationId", e.getCorrelationId());
        fields.put("responseStatus", String.valueOf(e.getResponseStatus()));
        fields.put("responseBody", e.getResponseBody() != null ? e.getResponseBody() : "");
        fields.put("durationMs", String.valueOf(e.getDurationMs()));
        fields.put("completedAt", e.getCompletedAt().toString());
        redis.opsForStream().add(StreamRecords.newRecord().ofMap(fields).withStreamKey(STREAM_KEY));
    }

    @EventListener
    @Async
    public void onFail(ProxyFailEvent e) {
        Map<String, String> fields = new HashMap<>();
        fields.put("eventType", "FAIL");
        fields.put("correlationId", e.getCorrelationId());
        fields.put("errorMessage", e.getErrorMessage() != null ? e.getErrorMessage() : "");
        fields.put("durationMs", String.valueOf(e.getDurationMs()));
        fields.put("completedAt", e.getCompletedAt().toString());
        redis.opsForStream().add(StreamRecords.newRecord().ofMap(fields).withStreamKey(STREAM_KEY));
    }
}
</#if>
