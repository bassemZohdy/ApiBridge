<#if (flags.enableAuditLog)!false>
package com.apibridge.generated.audit;

import java.time.Instant;

public class ProxySuccessEvent {

    private final String correlationId;
    private final int responseStatus;
    private final String responseBody;
    private final long durationMs;
    private final Instant completedAt;

    public ProxySuccessEvent(String correlationId, int responseStatus, String responseBody, long durationMs) {
        this.correlationId = correlationId;
        this.responseStatus = responseStatus;
        this.responseBody = responseBody;
        this.durationMs = durationMs;
        this.completedAt = Instant.now();
    }

    public String getCorrelationId() { return correlationId; }
    public int getResponseStatus() { return responseStatus; }
    public String getResponseBody() { return responseBody; }
    public long getDurationMs() { return durationMs; }
    public Instant getCompletedAt() { return completedAt; }
}
</#if>
