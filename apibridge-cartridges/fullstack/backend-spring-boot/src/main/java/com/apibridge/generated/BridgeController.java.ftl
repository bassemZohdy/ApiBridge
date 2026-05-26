package com.apibridge.generated;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("${basePath}")
public class BridgeController {

    @Value("${r"${BLOCK_TRAFFIC:false}"}")
    private boolean blockTraffic;

    @Value("${r"${MOCK_MODE:false}"}")
    private boolean mockMode;

    private final ProxyService proxyService;

    public BridgeController(ProxyService proxyService) {
        this.proxyService = proxyService;
    }

<#list endpoints as endpoint>
<#-- Derive a camelCase method name from the endpoint path -->
<#assign methodName = endpoint.path?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "")>
<#assign methodName = methodName?uncap_first>
    /**
     * Proxies ${endpoint.method?upper_case} ${endpoint.path} → ${endpoint.backendUrl}
     */
<#if endpoint.method?upper_case == "GET">
    @GetMapping("${endpoint.path}")
<#elseif endpoint.method?upper_case == "POST">
    @PostMapping("${endpoint.path}")
<#elseif endpoint.method?upper_case == "PUT">
    @PutMapping("${endpoint.path}")
<#elseif endpoint.method?upper_case == "DELETE">
    @DeleteMapping("${endpoint.path}")
<#elseif endpoint.method?upper_case == "PATCH">
    @PatchMapping("${endpoint.path}")
<#else>
    @RequestMapping(value = "${endpoint.path}", method = RequestMethod.${endpoint.method?upper_case})
</#if>
    public ResponseEntity<String> ${methodName}(
            @RequestBody(required = false) String body,
            HttpServletRequest request) {
<#if flags.enableTelemetry>
        // OTel span: ${endpoint.telemetryName}
</#if>
        if (blockTraffic) return ResponseEntity.status(503).body("{\"error\":\"Service temporarily unavailable\"}");
        if (mockMode) return ResponseEntity.ok("{\"status\":\"mock\",\"endpoint\":\"${endpoint.path}\",\"method\":\"${endpoint.method}\"}");
        return proxyService.forward("${endpoint.backendUrl}", "${endpoint.method}", body, request);
    }

</#list>
}
