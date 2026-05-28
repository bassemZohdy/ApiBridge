<#if (flags.enableAuditLog)!false>
package com.apibridge.generated.audit;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.data.redis.connection.stream.Consumer;
import org.springframework.data.redis.connection.stream.MapRecord;
import org.springframework.data.redis.connection.stream.ReadOffset;
import org.springframework.data.redis.connection.stream.StreamOffset;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.stream.StreamMessageListenerContainer;
import org.springframework.data.redis.stream.Subscription;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.time.Duration;
import java.time.Instant;

@Component
public class AuditStreamConsumer {

    private static final String GROUP = "apibridge-audit-group";
    private static final String CONSUMER = "consumer-1";

    @Value("${r"${audit.log.ttl-days:30}"}")
    private int ttlDays;

    private final StringRedisTemplate redis;
    private final MongoTemplate mongo;
    private StreamMessageListenerContainer<String, MapRecord<String, String, String>> container;
    private Subscription subscription;

    public AuditStreamConsumer(StringRedisTemplate redis, MongoTemplate mongo) {
        this.redis = redis;
        this.mongo = mongo;
    }

    @PostConstruct
    void start() {
        ensureStreamAndGroup();

        StreamMessageListenerContainer.StreamMessageListenerContainerOptions<String, MapRecord<String, String, String>> options =
                StreamMessageListenerContainer.StreamMessageListenerContainerOptions.builder()
                        .pollTimeout(Duration.ofMillis(500))
                        .build();

        container = StreamMessageListenerContainer.create(
                redis.getConnectionFactory(), options);

        subscription = container.receive(
                Consumer.from(GROUP, CONSUMER),
                StreamOffset.create(RedisAuditPublisher.STREAM_KEY, ReadOffset.lastConsumed()),
                this::handleMessage);

        container.start();
    }

    @PreDestroy
    void stop() {
        if (container != null) {
            container.stop();
        }
    }

    private void ensureStreamAndGroup() {
        try {
            redis.opsForStream().createGroup(
                    RedisAuditPublisher.STREAM_KEY, ReadOffset.from("0"), GROUP);
        } catch (Exception ignored) {
            // Group already exists — normal on restart
        }
    }

    private void handleMessage(MapRecord<String, String, String> message) {
        try {
            var fields = message.getValue();
            String eventType = fields.get("eventType");
            String correlationId = fields.get("correlationId");

            if ("SEND".equals(eventType)) {
                AuditRecord record = AuditRecord.pending(
                        new ProxySendEvent(
                                correlationId,
                                fields.get("endpoint"),
                                fields.get("method"),
                                fields.get("requestBody")),
                        ttlDays);
                mongo.insert(record);

            } else if ("SUCCESS".equals(eventType)) {
                Query q = Query.query(Criteria.where("correlationId").is(correlationId));
                Update u = new Update()
                        .set("status", AuditRecord.Status.SUCCESS)
                        .set("responseStatus", Integer.parseInt(fields.get("responseStatus")))
                        .set("responseBody", fields.get("responseBody"))
                        .set("durationMs", Long.parseLong(fields.get("durationMs")))
                        .set("completedAt", Instant.parse(fields.get("completedAt")));
                mongo.updateFirst(q, u, AuditRecord.class);

            } else if ("FAIL".equals(eventType)) {
                Query q = Query.query(Criteria.where("correlationId").is(correlationId));
                Update u = new Update()
                        .set("status", AuditRecord.Status.FAILED)
                        .set("errorMessage", fields.get("errorMessage"))
                        .set("durationMs", Long.parseLong(fields.get("durationMs")))
                        .set("completedAt", Instant.parse(fields.get("completedAt")));
                mongo.updateFirst(q, u, AuditRecord.class);
            }

            redis.opsForStream().acknowledge(
                    RedisAuditPublisher.STREAM_KEY, GROUP, message.getId());

        } catch (Exception e) {
            // Leave unacknowledged — Redis will redeliver on next consumer restart
        }
    }
}
</#if>
