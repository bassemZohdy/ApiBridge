<#function pathToEnvKey path>
  <#local s = path?replace("[{}]", "", "r")?replace("[^A-Za-z0-9]", "_", "r")?upper_case />
  <#local s = s?replace("_+", "_", "r")?remove_beginning("_")?remove_ending("_") />
  <#return s />
</#function>
package com.apibridge.generated;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
<#if flags.enableTelemetry>
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
</#if>

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("${basePath}")
public class BridgeController {

    @Value("${r"${BLOCK_TRAFFIC:false}"}")
    private boolean blockTraffic;

    @Value("${r"${MOCK_MODE:false}"}")
    private boolean mockMode;
<#if (flags.securityLevel!"") == "apiKey">
    @Value("${r"${API_KEY:}"}")
    private String expectedApiKey;
</#if>
<#if (flags.securityLevel!"") == "bearer-token">
    @Value("${r"${AUTH_SERVER_URL:}"}")
    private String authServerUrl;

    private final RestTemplate authRestTemplate = new RestTemplate();

    private boolean validateBearerToken(HttpServletRequest request) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return false;
        }
        String token = authHeader.substring(7);
        if (token.isBlank()) {
            return false;
        }
        if (authServerUrl != null && !authServerUrl.isBlank()) {
            try {
                HttpHeaders headers = new HttpHeaders();
                headers.set("Authorization", "Bearer " + token);
                ResponseEntity<Void> resp = authRestTemplate.exchange(
                    authServerUrl, HttpMethod.GET, new HttpEntity<>(headers), Void.class);
                return resp.getStatusCode().is2xxSuccessful();
            } catch (Exception e) {
                return false;
            }
        }
        return true;
    }
</#if>

    // Per-endpoint backend URLs — override at runtime via ENV VAR
<#list endpoints as endpoint>
<#assign envKey = pathToEnvKey(endpoint.path) />
<#assign urlFieldName = "backendUrl" + envKey?lower_case?replace("_", " ")?capitalize?replace(" ", "") />
    @Value("${r"${"}BACKEND_URL_${envKey}${r":"}${endpoint.backendUrl}${r"}"}")
    private String ${urlFieldName};
</#list>

    private final ProxyService proxyService;
<#if flags.enableTelemetry>
    private final Tracer otelTracer;
</#if>

    public BridgeController(ProxyService proxyService<#if flags.enableTelemetry>, OpenTelemetry openTelemetry</#if>) {
        this.proxyService = proxyService;
<#if flags.enableTelemetry>
        this.otelTracer = openTelemetry.getTracer("apibridge", "1.0.0");
</#if>
    }

<#list endpoints as endpoint>
<#assign cleanPath = endpoint.path?replace("[{][^}]*[}]", "", "r") />
<#assign baseName = cleanPath?replace("/", " ")?replace("-", " ")?trim?capitalize?replace(" ", "") />
<#assign methodName = endpoint.method?lower_case + baseName />
<#assign pathParams = [] />
<#list endpoint.path?split("{") as seg>
  <#if seg?contains("}")>
    <#assign pathParams = pathParams + [seg?split("}")?first] />
  </#if>
</#list>
<#assign envKey = pathToEnvKey(endpoint.path) />
<#assign urlFieldName = "backendUrl" + envKey?lower_case?replace("_", " ")?capitalize?replace(" ", "") />
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
<#list pathParams as param>
            @PathVariable String ${param},
</#list>
            @RequestBody(required = false) String body,
            HttpServletRequest request) {
        if (blockTraffic) return ResponseEntity.status(503).body("{\"error\":\"Service temporarily unavailable\"}");
        if (mockMode) return ResponseEntity.ok("{\"status\":\"mock\",\"endpoint\":\"${endpoint.path}\",\"method\":\"${endpoint.method}\"}");
<#if (flags.securityLevel!"") == "apiKey">
        if (expectedApiKey != null && !expectedApiKey.isBlank()) {
            String providedKey = request.getHeader("X-API-Key");
            if (!expectedApiKey.equals(providedKey)) {
                return ResponseEntity.status(401).body("{\"error\":\"Unauthorized\"}");
            }
        }
</#if>
<#if (flags.securityLevel!"") == "bearer-token">
        if (!validateBearerToken(request)) {
            return ResponseEntity.status(401).body("{\"error\":\"Unauthorized\"}");
        }
</#if>
        String resolvedUrl = ${urlFieldName}<#list pathParams as param>.replace("{${param}}", ${param})</#list>;
<#if flags.enableTelemetry>
        Span span${endpoint?index} = otelTracer.spanBuilder("${(endpoint.telemetryName!methodName)}")
                .setAttribute("http.method", "${endpoint.method?upper_case}")
                .setAttribute("http.url", resolvedUrl)
                .startSpan();
        try (Scope scope${endpoint?index} = span${endpoint?index}.makeCurrent()) {
            return proxyService.forward(resolvedUrl, "${endpoint.method}", body, request);
        } catch (Exception e${endpoint?index}) {
            span${endpoint?index}.recordException(e${endpoint?index});
            throw e${endpoint?index};
        } finally {
            span${endpoint?index}.end();
        }
<#else>
        return proxyService.forward(resolvedUrl, "${endpoint.method}", body, request);
</#if>
    }

</#list>
}
