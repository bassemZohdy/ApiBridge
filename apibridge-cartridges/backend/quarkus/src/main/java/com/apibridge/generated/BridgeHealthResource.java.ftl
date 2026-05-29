<#if (enableHealthCheck)!false>
package com.apibridge.generated;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Path("/api")
public class BridgeHealthResource {

    @Inject
    HealthCheckService healthCheckService;

    @GET
    @Path("/bridge-health")
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, Object> health() {
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
        return result;
    }
}
</#if>
