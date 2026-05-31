package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Merges multiple {@link BridgeSchemaModel} instances into a single model for unified code
 * generation. The primary (first) schema provides {@code id}, {@code basePath}, and {@code flags};
 * endpoints are concatenated in order, with cross-schema duplicates rejected.
 */
public class SchemaComposer {

    public BridgeSchemaModel compose(List<BridgeSchemaModel> schemas) {
        if (schemas == null || schemas.isEmpty()) {
            throw new IllegalArgumentException("At least one schema is required for composition.");
        }

        BridgeSchemaModel primary = schemas.get(0);
        BridgeSchemaModel merged = new BridgeSchemaModel();
        merged.setId(primary.getId());
        merged.setBasePath(primary.getBasePath());
        merged.setFlags(primary.getFlags());

        List<BridgeSchemaModel.Endpoint> allEndpoints = new ArrayList<>();
        Set<String> seen = new HashSet<>();

        for (BridgeSchemaModel schema : schemas) {
            if (schema.getEndpoints() == null) {
                continue;
            }
            for (BridgeSchemaModel.Endpoint ep : schema.getEndpoints()) {
                String method = ep.getMethod();
                String path = ep.getPath();
                if (method == null || path == null) {
                    continue;
                }
                String key = method.toUpperCase() + " " + path;
                if (!seen.add(key)) {
                    throw new IllegalArgumentException(
                            "Schema composition error: duplicate endpoint " + key
                            + " found across merged schemas.");
                }
                allEndpoints.add(ep);
            }
        }

        merged.setEndpoints(allEndpoints);
        return merged;
    }
}
