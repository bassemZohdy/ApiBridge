<#if (enableHealthCheck)!false>
package com.apibridge.generated;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class BridgeHealthController {

    private final HealthCheckService healthCheckService;

    public BridgeHealthController(HealthCheckService healthCheckService) {
        this.healthCheckService = healthCheckService;
    }

    @GetMapping("/bridge-health")
    public ResponseEntity<Map<String, Object>> health() {
        List<Map<String, Object>> endpoints = new ArrayList<>();
        for (HealthCheckService.EndpointHealth h : healthCheckService.getHealthMap().values()) {
            Map<String, Object> ep = new LinkedHashMap<>();
            ep.put("path", h.path);
            ep.put("method", h.method);
            ep.put("backendUrl", h.backendUrl);
            ep.put("status", h.status);
            ep.put("lastCheck", h.lastCheck != null ? h.lastCheck.toString() : null);
            ep.put("latencyMs", h.latencyMs);
            endpoints.add(ep);
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("status", healthCheckService.getAggregatedStatus());
        result.put("endpoints", endpoints);
        return ResponseEntity.ok(result);
    }
}
</#if>
