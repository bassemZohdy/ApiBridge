<#if (enableHealthCheck)!false>
package com.apibridge.generated;

import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URI;
import java.time.Duration;
import java.time.Instant;
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
public class HealthCheckService {

    @ConfigProperty(name = "HEALTH_CHECK_TIMEOUT_MS", defaultValue = "3000")
    int timeoutMs;

    private final Map<String, EndpointHealth> healthMap = new ConcurrentHashMap<>();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofMillis(3000))
            .build();

    public static class EndpointHealth {
        public final String path;
        public final String method;
        public final String backendUrl;
        public final String status;
        public final Instant lastCheck;
        public final long latencyMs;

        public EndpointHealth(String path, String method, String backendUrl,
                              String status, Instant lastCheck, long latencyMs) {
            this.path = path;
            this.method = method;
            this.backendUrl = backendUrl;
            this.status = status;
            this.lastCheck = lastCheck;
            this.latencyMs = latencyMs;
        }
    }

    @Scheduled(every = "${r"${health.check.interval:30s}"}")
    public void runHealthChecks() {
<#list endpoints as ep>
        probe("${ep.path}", "${ep.method?upper_case}", "${ep.backendUrl}");
</#list>
    }

    private void probe(String path, String method, String backendUrl) {
        long start = System.currentTimeMillis();
        String status;
        try {
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(backendUrl))
                    .method("HEAD", HttpRequest.BodyPublishers.noBody())
                    .timeout(Duration.ofMillis(timeoutMs))
                    .build();
            HttpResponse<Void> resp = httpClient.send(req, HttpResponse.BodyHandlers.discarding());
            status = resp.statusCode() < 500 ? "UP" : "DOWN";
        } catch (Exception e) {
            status = "DOWN";
        }
        long latency = System.currentTimeMillis() - start;
        healthMap.put(path, new EndpointHealth(path, method, backendUrl, status, Instant.now(), latency));
    }

    public Map<String, EndpointHealth> getHealthMap() {
        return Collections.unmodifiableMap(healthMap);
    }

    public String getAggregatedStatus() {
        if (healthMap.isEmpty()) return "DOWN";
        long upCount = healthMap.values().stream().filter(h -> "UP".equals(h.status)).count();
        if (upCount == healthMap.size()) return "UP";
        if (upCount == 0) return "DOWN";
        return "DEGRADED";
    }
}
</#if>
