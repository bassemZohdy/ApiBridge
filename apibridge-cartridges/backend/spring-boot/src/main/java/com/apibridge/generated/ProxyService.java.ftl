package com.apibridge.generated;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestTemplate;
<#if (flags.enableAuditLog)!false>
import org.springframework.context.ApplicationEventPublisher;
import com.apibridge.generated.audit.ProxySendEvent;
import com.apibridge.generated.audit.ProxySuccessEvent;
import com.apibridge.generated.audit.ProxyFailEvent;
import java.util.UUID;
</#if>

import jakarta.servlet.http.HttpServletRequest;
import java.util.Enumeration;
import java.util.Set;

@Service
public class ProxyService {

    private static final Set<String> HOP_BY_HOP = Set.of(
            "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
            "te", "trailers", "transfer-encoding", "upgrade", "content-length", "host"
    );

    @Value("${r"${proxy.connect-timeout:5000}"}")
    private int connectTimeout;

    @Value("${r"${proxy.read-timeout:30000}"}")
    private int readTimeout;

    private final RestTemplate restTemplate;
<#if (flags.enableAuditLog)!false>
    private final ApplicationEventPublisher events;

    public ProxyService(ApplicationEventPublisher events) {
        this.restTemplate = new RestTemplate();
        this.events = events;
    }
<#else>
    public ProxyService() {
        this.restTemplate = new RestTemplate();
    }
</#if>

    public ResponseEntity<String> forward(
            String targetUrl,
            String method,
            String requestBody,
            HttpServletRequest request) {

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(connectTimeout);
        factory.setReadTimeout(readTimeout);
        restTemplate.setRequestFactory(factory);

        String urlWithQuery = targetUrl;
        String queryString = request.getQueryString();
        if (queryString != null && !queryString.isBlank()) {
            urlWithQuery = targetUrl + (targetUrl.contains("?") ? "&" : "?") + queryString;
        }

        HttpHeaders outboundHeaders = new HttpHeaders();
        Enumeration<String> headerNames = request.getHeaderNames();
        if (headerNames != null) {
            while (headerNames.hasMoreElements()) {
                String name = headerNames.nextElement();
                if (!HOP_BY_HOP.contains(name.toLowerCase())) {
                    outboundHeaders.set(name, request.getHeader(name));
                }
            }
        }

        HttpEntity<String> entity = new HttpEntity<>(requestBody, outboundHeaders);
        HttpMethod httpMethod = HttpMethod.valueOf(method.toUpperCase());
<#if (flags.enableAuditLog)!false>

        String correlationId = UUID.randomUUID().toString();
        events.publishEvent(new ProxySendEvent(correlationId, urlWithQuery, method, requestBody));
        long startMs = System.currentTimeMillis();
</#if>

        try {
            ResponseEntity<String> upstream = restTemplate.exchange(
                    urlWithQuery, httpMethod, entity, String.class);

            HttpHeaders responseHeaders = new HttpHeaders();
            upstream.getHeaders().forEach((name, values) -> {
                if (!HOP_BY_HOP.contains(name.toLowerCase())) {
                    values.forEach(v -> responseHeaders.add(name, v));
                }
            });
<#if (flags.enableAuditLog)!false>

            events.publishEvent(new ProxySuccessEvent(
                    correlationId,
                    upstream.getStatusCode().value(),
                    upstream.getBody(),
                    System.currentTimeMillis() - startMs));
</#if>

            return ResponseEntity.status(upstream.getStatusCode())
                    .headers(responseHeaders)
                    .body(upstream.getBody());

        } catch (RestClientResponseException ex) {
<#if (flags.enableAuditLog)!false>
            events.publishEvent(new ProxyFailEvent(
                    correlationId,
                    ex.getStatusCode().value() + " " + ex.getStatusText(),
                    System.currentTimeMillis() - startMs));
</#if>
            return ResponseEntity
                    .status(ex.getStatusCode())
                    .body(ex.getResponseBodyAsString());
        } catch (Exception ex) {
<#if (flags.enableAuditLog)!false>
            events.publishEvent(new ProxyFailEvent(
                    correlationId,
                    ex.getMessage(),
                    System.currentTimeMillis() - startMs));
</#if>
            return ResponseEntity
                    .status(502)
                    .body("{\"error\":\"Bad Gateway\"}");
        }
    }
}
