package com.apibridge.generated;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.concurrent.TimeUnit;

@ApplicationScoped
public class ProxyService {

    private Client client;

    @PostConstruct
    void init() {
        client = ClientBuilder.newBuilder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                .build();
    }

    @PreDestroy
    void destroy() {
        if (client != null) {
            client.close();
        }
    }

    public Response forward(String targetUrl, String method, String requestBody, HttpHeaders headers) {
        try {
            var target = client.target(targetUrl).request();

            String authorization = headers.getHeaderString(HttpHeaders.AUTHORIZATION);
            if (authorization != null) {
                target = target.header(HttpHeaders.AUTHORIZATION, authorization);
            }

            String contentType = headers.getHeaderString(HttpHeaders.CONTENT_TYPE);
            if (contentType == null) {
                contentType = MediaType.APPLICATION_JSON;
            }

            Response upstream;
            if (requestBody != null && !requestBody.isBlank()) {
                upstream = target.method(method.toUpperCase(), Entity.entity(requestBody, contentType));
            } else {
                upstream = target.method(method.toUpperCase());
            }

            String body = upstream.readEntity(String.class);
            String upstreamContentType = upstream.getMediaType() != null
                    ? upstream.getMediaType().toString()
                    : MediaType.APPLICATION_JSON;

            return Response.status(upstream.getStatus())
                    .entity(body)
                    .type(upstreamContentType)
                    .build();

        } catch (Exception e) {
            return Response.status(502)
                    .entity("{\"error\":\"Bad Gateway\",\"detail\":\"" + e.getMessage() + "\"}")
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
}
