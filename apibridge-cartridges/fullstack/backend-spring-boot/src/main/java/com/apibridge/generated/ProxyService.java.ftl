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

@Service
public class ProxyService {

    private final RestTemplate restTemplate;

    public ProxyService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    public ResponseEntity<String> forward(
            String targetUrl,
            String method,
            String requestBody,
            HttpServletRequest request) {

        HttpHeaders outboundHeaders = new HttpHeaders();

        Enumeration<String> headerNames = request.getHeaderNames();
        if (headerNames != null) {
            while (headerNames.hasMoreElements()) {
                String name = headerNames.nextElement();
                String lower = name.toLowerCase();
                if (lower.equals("authorization")
                        || lower.equals("content-type")
                        || lower.startsWith("x-")) {
                    outboundHeaders.set(name, request.getHeader(name));
                }
            }
        }

        HttpEntity<String> entity = new HttpEntity<>(requestBody, outboundHeaders);
        HttpMethod httpMethod = HttpMethod.valueOf(method.toUpperCase());

        try {
            ResponseEntity<String> upstream = restTemplate.exchange(
                    targetUrl, httpMethod, entity, String.class);

            HttpHeaders responseHeaders = new HttpHeaders();
            String contentType = upstream.getHeaders().getFirst(HttpHeaders.CONTENT_TYPE);
            if (contentType != null) {
                responseHeaders.set(HttpHeaders.CONTENT_TYPE, contentType);
            }

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
                    .body("{\"error\":\"Bad Gateway\",\"message\":\"" + ex.getMessage() + "\"}");
        }
    }
}
