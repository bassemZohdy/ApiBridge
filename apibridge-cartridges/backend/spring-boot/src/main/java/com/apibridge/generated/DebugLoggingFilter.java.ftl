package com.apibridge.generated;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Enumeration;

@Component
public class DebugLoggingFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(DebugLoggingFilter.class);
    private static final int MAX_BODY_PREVIEW = 1024;

    @Value("${r"${debug.mode:false}"}")
    private boolean debugMode;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        if (!debugMode) {
            filterChain.doFilter(request, response);
            return;
        }

        long startMs = System.currentTimeMillis();
        String method = request.getMethod();
        String uri = request.getRequestURI();
        String query = request.getQueryString();
        String fullUrl = query != null ? uri + "?" + query : uri;

        log.debug(">>> {} {}", method, fullUrl);
        Enumeration<String> headerNames = request.getHeaderNames();
        if (headerNames != null) {
            while (headerNames.hasMoreElements()) {
                String name = headerNames.nextElement();
                String value = name.equalsIgnoreCase("authorization") ? "***" : request.getHeader(name);
                log.debug(">>>   {}: {}", name, value);
            }
        }

        filterChain.doFilter(request, response);

        long durationMs = System.currentTimeMillis() - startMs;
        log.debug("<<< {} {} -> {} ({}ms)", method, fullUrl, response.getStatus(), durationMs);
        for (String name : response.getHeaderNames()) {
            String value = name.equalsIgnoreCase("authorization") ? "***" : response.getHeader(name);
            log.debug("<<<   {}: {}", name, value);
        }
    }
}
