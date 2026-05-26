package com.apibridge.core;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * Mock implementation of the pre-compiled apibridge-enterprise-core library dependency.
 * Provides the required endpoint execution signature.
 */
public class IntegrationProxy {
    private final ObjectMapper mapper = new ObjectMapper();

    public JsonNode execute(String url, String method, JsonNode body) {
        ObjectNode response = mapper.createObjectNode();
        response.put("status", "success");
        response.put("proxiedUrl", url);
        response.put("proxiedMethod", method);
        response.set("originalBody", body);
        return response;
    }
}
