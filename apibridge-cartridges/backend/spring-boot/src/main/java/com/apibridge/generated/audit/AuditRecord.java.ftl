<#if (flags.enableAuditLog)!false>
package com.apibridge.generated.audit;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Document(collection = "audit_log")
public class AuditRecord {

    public enum Status { PENDING, SUCCESS, FAILED }

    @Id
    private String id;

    private String correlationId;
    private String endpoint;
    private String method;
    private String requestBody;
    private Status status;

    private Integer responseStatus;
    private String responseBody;
    private String errorMessage;
    private Long durationMs;

    @Indexed(expireAfterSeconds = 0)
    private Instant expiresAt;

    private Instant sentAt;
    private Instant completedAt;

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

    public String getId() { return id; }
    public String getCorrelationId() { return correlationId; }
    public String getEndpoint() { return endpoint; }
    public String getMethod() { return method; }
    public String getRequestBody() { return requestBody; }
    public Status getStatus() { return status; }
    public void setStatus(Status status) { this.status = status; }
    public Integer getResponseStatus() { return responseStatus; }
    public void setResponseStatus(Integer responseStatus) { this.responseStatus = responseStatus; }
    public String getResponseBody() { return responseBody; }
    public void setResponseBody(String responseBody) { this.responseBody = responseBody; }
    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }
    public Long getDurationMs() { return durationMs; }
    public void setDurationMs(Long durationMs) { this.durationMs = durationMs; }
    public Instant getSentAt() { return sentAt; }
    public Instant getCompletedAt() { return completedAt; }
    public void setCompletedAt(Instant completedAt) { this.completedAt = completedAt; }
    public Instant getExpiresAt() { return expiresAt; }
}
</#if>
