<#if (enableHealthCheck)!false>
package com.apibridge.generated;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class HealthCheckService {

    @Value("${r"${HEALTH_CHECK_TIMEOUT_MS:3000}"}")
    private int timeoutMs;

    private final Map<String, EndpointHealth> healthMap = new ConcurrentHashMap<>();
    private final RestTemplate restTemplate = new RestTemplate();

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

    @Scheduled(fixedDelayString = "${r"${HEALTH_CHECK_INTERVAL_SECONDS:30}"}000")
    public void runHealthChecks() {
<#list endpoints as ep>
        probe("${ep.path}", "${ep.method?upper_case}", "${ep.backendUrl}");
</#list>
    }

    private void probe(String path, String method, String backendUrl) {
        long start = System.currentTimeMillis();
        String status;
        try {
            restTemplate.headForHeaders(backendUrl);
            status = "UP";
        } catch (Exception e) {
            try {
                restTemplate.getForEntity(backendUrl, String.class);
                status = "UP";
            } catch (Exception e2) {
                status = "DOWN";
            }
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
