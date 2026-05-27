package com.apibridge.generated;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.Set;
import java.util.concurrent.TimeUnit;

@ApplicationScoped
public class ProxyService {

    private static final Set<String> HOP_BY_HOP = Set.of(
            "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
            "te", "trailers", "transfer-encoding", "upgrade", "content-length", "host"
    );

    @ConfigProperty(name = "proxy.connect-timeout", defaultValue = "5000")
    int connectTimeout;

    @ConfigProperty(name = "proxy.read-timeout", defaultValue = "30000")
    int readTimeout;

    private Client client;

    @PostConstruct
    void init() {
        client = ClientBuilder.newBuilder()
                .connectTimeout(connectTimeout, TimeUnit.MILLISECONDS)
                .readTimeout(readTimeout, TimeUnit.MILLISECONDS)
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

            MultivaluedMap<String, String> requestHeaders = headers.getRequestHeaders();
            for (var entry : requestHeaders.entrySet()) {
                String name = entry.getKey().toLowerCase();
                if (!HOP_BY_HOP.contains(name)) {
                    for (String value : entry.getValue()) {
                        target = target.header(entry.getKey(), value);
                    }
                }
            }

            String contentType = headers.getHeaderString(HttpHeaders.CONTENT_TYPE);
            if (contentType == null) {
                contentType = MediaType.APPLICATION_JSON;
            }

            Response upstream;
            try {
                if (requestBody != null && !requestBody.isBlank()) {
                    upstream = target.method(method.toUpperCase(), Entity.entity(requestBody, contentType));
                } else {
                    upstream = target.method(method.toUpperCase());
                }

                String body = upstream.readEntity(String.class);

                Response.ResponseBuilder builder = Response.status(upstream.getStatus()).entity(body);

                MultivaluedMap<String, Object> upstreamHeaders = upstream.getHeaders();
                for (var entry : upstreamHeaders.entrySet()) {
                    String name = entry.getKey().toLowerCase();
                    if (!HOP_BY_HOP.contains(name)) {
                        for (Object value : entry.getValue()) {
                            builder.header(entry.getKey(), value);
                        }
                    }
                }

                return builder.build();
            } finally {
                upstream.close();
            }

        } catch (Exception e) {
            return Response.status(502)
                    .entity("{\"error\":\"Bad Gateway\"}")
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
}
