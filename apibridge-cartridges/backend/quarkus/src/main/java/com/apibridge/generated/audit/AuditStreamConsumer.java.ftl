<#if (flags.enableAuditLog)!false>
package com.apibridge.generated.audit;

import io.quarkus.redis.datasource.ReactiveRedisDataSource;
import io.quarkus.redis.datasource.stream.StreamMessage;
import io.quarkus.redis.datasource.stream.XGroupCreateArgs;
import io.quarkus.redis.datasource.stream.XReadGroupArgs;
import io.quarkus.runtime.Startup;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Startup
@ApplicationScoped
public class AuditStreamConsumer {

    private static final String GROUP = "apibridge-audit-group";
    private static final String CONSUMER = "consumer-1";

    @ConfigProperty(name = "audit.log.ttl-days", defaultValue = "30")
    int ttlDays;

    private final ReactiveRedisDataSource redis;
    private final ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();

    public AuditStreamConsumer(ReactiveRedisDataSource redis) {
        this.redis = redis;
    }

    @PostConstruct
    void start() {
        ensureGroup();
        scheduler.scheduleWithFixedDelay(this::poll, 500, 500, TimeUnit.MILLISECONDS);
    }

    @PreDestroy
    void stop() {
        scheduler.shutdownNow();
    }

    private void ensureGroup() {
        redis.stream(String.class)
                .xgroupCreate(RedisAuditPublisher.STREAM_KEY, GROUP, "0", new XGroupCreateArgs().mkstream())
                .onFailure().recoverWithNull()
                .subscribe().with(x -> {});
    }

    private void poll() {
        redis.stream(String.class)
                .xreadgroup(GROUP, CONSUMER,
                        new XReadGroupArgs().count(10),
                        RedisAuditPublisher.STREAM_KEY, ">")
                .subscribe().with(this::processMessages, t -> {});
    }

    private void processMessages(List<StreamMessage<String, String, String>> messages) {
        for (StreamMessage<String, String, String> msg : messages) {
            try {
                Map<String, String> fields = msg.payload();
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
                    record.persist();

                } else if ("SUCCESS".equals(eventType)) {
                    AuditRecord.update(
                            "status = ?1, responseStatus = ?2, responseBody = ?3, durationMs = ?4, completedAt = ?5",
                            AuditRecord.Status.SUCCESS,
                            Integer.parseInt(fields.get("responseStatus")),
                            fields.get("responseBody"),
                            Long.parseLong(fields.get("durationMs")),
                            Instant.parse(fields.get("completedAt")))
                            .where("correlationId", correlationId);

                } else if ("FAIL".equals(eventType)) {
                    AuditRecord.update(
                            "status = ?1, errorMessage = ?2, durationMs = ?3, completedAt = ?4",
                            AuditRecord.Status.FAILED,
                            fields.get("errorMessage"),
                            Long.parseLong(fields.get("durationMs")),
                            Instant.parse(fields.get("completedAt")))
                            .where("correlationId", correlationId);
                }

                redis.stream(String.class)
                        .xack(RedisAuditPublisher.STREAM_KEY, GROUP, msg.id())
                        .subscribe().with(x -> {});

            } catch (Exception ignored) {
                // Leave unacknowledged — Redis redelivers on next poll
            }
        }
    }
}
</#if>
