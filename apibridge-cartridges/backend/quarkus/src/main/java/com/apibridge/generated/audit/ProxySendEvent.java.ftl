<#if (flags.enableAuditLog)!false>
package com.apibridge.generated.audit;

import java.time.Instant;

public class ProxySendEvent {

    private final String correlationId;
    private final String endpoint;
    private final String method;
    private final String requestBody;
    private final Instant sentAt;

    public ProxySendEvent(String correlationId, String endpoint, String method, String requestBody) {
        this.correlationId = correlationId;
        this.endpoint = endpoint;
        this.method = method;
        this.requestBody = requestBody;
        this.sentAt = Instant.now();
    }

    public String getCorrelationId() { return correlationId; }
    public String getEndpoint() { return endpoint; }
    public String getMethod() { return method; }
    public String getRequestBody() { return requestBody; }
    public Instant getSentAt() { return sentAt; }
}
</#if>
