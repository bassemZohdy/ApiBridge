<#if (flags.enableAuditLog)!false>
package com.apibridge.generated.audit;

import java.time.Instant;

public class ProxyFailEvent {

    private final String correlationId;
    private final String errorMessage;
    private final long durationMs;
    private final Instant completedAt;

    public ProxyFailEvent(String correlationId, String errorMessage, long durationMs) {
        this.correlationId = correlationId;
        this.errorMessage = errorMessage;
        this.durationMs = durationMs;
        this.completedAt = Instant.now();
    }

    public String getCorrelationId() { return correlationId; }
    public String getErrorMessage() { return errorMessage; }
    public long getDurationMs() { return durationMs; }
    public Instant getCompletedAt() { return completedAt; }
}
</#if>
