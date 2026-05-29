package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

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
                String key = ep.getMethod().toUpperCase() + " " + ep.getPath();
                if (!seen.add(key)) {
                    throw new IllegalArgumentException(
                            "Composition error: duplicate endpoint " + key
                            + " found across merged schemas.");
                }
                allEndpoints.add(ep);
            }
        }

        merged.setEndpoints(allEndpoints);
        return merged;
    }
}
