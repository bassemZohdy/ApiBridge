<#if (flags.enableAuditLog)!false>
package com.apibridge.generated.audit;

import io.quarkus.mongodb.panache.PanacheMongoEntity;
import io.quarkus.mongodb.panache.common.MongoEntity;

import java.time.Instant;

@MongoEntity(collection = "audit_log")
public class AuditRecord extends PanacheMongoEntity {

    public enum Status { PENDING, SUCCESS, FAILED }

    public String correlationId;
    public String endpoint;
    public String method;
    public String requestBody;
    public Status status;

    public Integer responseStatus;
    public String responseBody;
    public String errorMessage;
    public Long durationMs;

    public Instant expiresAt;
    public Instant sentAt;
    public Instant completedAt;

    public static AuditRecord pending(ProxySendEvent e, int ttlDays) {
        AuditRecord r = new AuditRecord();
        r.correlationId = e.getCorrelationId();
        r.endpoint = e.getEndpoint();
        r.method = e.getMethod();
        r.requestBody = e.getRequestBody();
        r.status = Status.PENDING;
        r.sentAt = e.getSentAt();
        r.expiresAt = Instant.now().plusSeconds((long) ttlDays * 86400);
        return r;
    }
}
</#if>
