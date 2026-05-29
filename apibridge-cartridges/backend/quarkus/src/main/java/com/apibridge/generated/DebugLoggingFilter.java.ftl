package com.apibridge.generated;

import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.ext.Provider;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@Provider
@Priority(100)
public class DebugLoggingFilter implements ContainerRequestFilter, ContainerResponseFilter {

    private static final Logger log = Logger.getLogger(DebugLoggingFilter.class);

    @Inject
    @ConfigProperty(name = "debug.mode", defaultValue = "false")
    boolean debugMode;

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException {
        if (!debugMode) return;

        String method = requestContext.getMethod();
        String uri = requestContext.getUriInfo().getRequestUri().toString();
        log.debugf(">>> %s %s", method, uri);
        for (Map.Entry<String, List<String>> entry : requestContext.getHeaders().entrySet()) {
            String value = entry.getKey().equalsIgnoreCase("authorization") ? "***" : String.join(", ", entry.getValue());
            log.debugf(">>>   %s: %s", entry.getKey(), value);
        }
    }

    @Override
    public void filter(ContainerRequestContext requestContext, ContainerResponseContext responseContext)
            throws IOException {
        if (!debugMode) return;

        String method = requestContext.getMethod();
        String uri = requestContext.getUriInfo().getRequestUri().toString();
        log.debugf("<<< %s %s -> %d", method, uri, responseContext.getStatus());
        for (Map.Entry<String, List<Object>> entry : responseContext.getHeaders().entrySet()) {
            log.debugf("<<<   %s: %s", entry.getKey(), entry.getValue());
        }
    }
}
