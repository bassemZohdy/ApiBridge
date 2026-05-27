package com.apibridge.generated;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestTemplate;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Enumeration;
import java.util.Set;

@Service
public class ProxyService {

    private static final Set<String> HOP_BY_HOP = Set.of(
            "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
            "te", "trailers", "transfer-encoding", "upgrade", "content-length", "host"
    );

    private final RestTemplate restTemplate;

    public ProxyService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    public ResponseEntity<String> forward(
            String targetUrl,
            String method,
            String requestBody,
            HttpServletRequest request) {

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

        try {
            ResponseEntity<String> upstream = restTemplate.exchange(
                    urlWithQuery, httpMethod, entity, String.class);

            HttpHeaders responseHeaders = new HttpHeaders();
            upstream.getHeaders().forEach((name, values) -> {
                if (!HOP_BY_HOP.contains(name.toLowerCase())) {
                    values.forEach(v -> responseHeaders.add(name, v));
                }
            });

            return ResponseEntity.status(upstream.getStatusCode())
                    .headers(responseHeaders)
                    .body(upstream.getBody());

        } catch (RestClientResponseException ex) {
            return ResponseEntity
                    .status(ex.getStatusCode())
                    .body(ex.getResponseBodyAsString());
        } catch (Exception ex) {
            return ResponseEntity
                    .status(502)
                    .body("{\"error\":\"Bad Gateway\"}");
        }
    }
}
