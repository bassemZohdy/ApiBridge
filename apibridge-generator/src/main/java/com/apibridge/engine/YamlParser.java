package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

public class YamlParser {

    private final ObjectMapper mapper;

    public YamlParser() {
        this.mapper = new ObjectMapper(new YAMLFactory());
    }

    public BridgeSchemaModel parse(File schemaFile) throws IOException {
        if (schemaFile == null) {
            throw new IllegalArgumentException("Schema file reference cannot be null.");
        }
        if (!schemaFile.exists()) {
            throw new FileNotFoundException("Schema file not found at: " + schemaFile.getAbsolutePath());
        }
        if (!schemaFile.isFile()) {
            throw new IllegalArgumentException("Path does not point to a valid file: " + schemaFile.getAbsolutePath());
        }

        BridgeSchemaModel model;
        try {
            model = mapper.readValue(schemaFile, BridgeSchemaModel.class);
        } catch (IOException e) {
            throw new IOException("Failed to parse YAML file. The configuration is syntactically malformed: " + e.getMessage(), e);
        }

        if (model == null) {
            throw new IllegalArgumentException("The parsed YAML schema is empty.");
        }

        validate(model);
        return model;
    }

    public void validate(BridgeSchemaModel model) {
        if (model.getId() == null || model.getId().isBlank()) {
            throw new IllegalArgumentException("Schema validation error: Missing or empty 'id' parameter.");
        }
        if (model.getBasePath() == null || model.getBasePath().isBlank()) {
            throw new IllegalArgumentException("Schema validation error: Missing or empty 'basePath' parameter.");
        }
        if (model.getEndpoints() == null || model.getEndpoints().isEmpty()) {
            throw new IllegalArgumentException("Schema validation error: Configuration must define at least one endpoint under 'endpoints'.");
        }

        if (model.getFlags() != null) {
            if (model.getFlags().getBackendFlavor() != null) {
                String flavor = model.getFlags().getBackendFlavor().toLowerCase();
                if (!flavor.equals("spring-boot") && !flavor.equals("quarkus")) {
                    throw new IllegalArgumentException("Schema validation error: Invalid flags.backendFlavor value '" + flavor + "'. Must be 'spring-boot' or 'quarkus'.");
                }
            }
        }

        if (model.getFlags() != null && model.getFlags().getFeFlavor() != null) {
            String flavor = model.getFlags().getFeFlavor().toLowerCase();
            if (!flavor.equals("angular") && !flavor.equals("react") && !flavor.equals("vue")) {
                throw new IllegalArgumentException("Schema validation error: Invalid flags.feFlavor value '" + flavor + "'. Must be 'angular', 'react', or 'vue'.");
            }
        }

        if (model.getFlags() != null && model.getFlags().getDeployTarget() != null) {
            String target = model.getFlags().getDeployTarget().toLowerCase();
            if (!target.equals("docker-compose") && !target.equals("kubernetes") && !target.equals("openshift")) {
                throw new IllegalArgumentException("Schema validation error: Invalid flags.deployTarget value '" + target + "'. Must be 'docker-compose', 'kubernetes', or 'openshift'.");
            }
        }

        if (model.getFlags() != null && model.getFlags().getSecurityLevel() != null) {
            String level = model.getFlags().getSecurityLevel().toLowerCase();
            if (!level.equals("bearer-token") && !level.equals("apikey")) {
                throw new IllegalArgumentException("Schema validation error: Invalid flags.securityLevel value '" + level + "'. Must be 'bearer-token' or 'apiKey'.");
            }
        }

        if (model.getFlags() != null && model.getFlags().getPagination() != null) {
            BridgeSchemaModel.Pagination p = model.getFlags().getPagination();
            if (p.getDefaultPageSize() <= 0) {
                throw new IllegalArgumentException("Schema validation error: flags.pagination.defaultPageSize must be a positive integer.");
            }
        }

        Set<String> seenEndpoints = new HashSet<>();
        for (int i = 0; i < model.getEndpoints().size(); i++) {
            BridgeSchemaModel.Endpoint endpoint = model.getEndpoints().get(i);
            String location = "endpoints[" + i + "]";

            if (endpoint.getPath() == null || endpoint.getPath().isBlank()) {
                throw new IllegalArgumentException("Schema validation error at " + location + ": Missing or empty 'path'.");
            }
            if (endpoint.getMethod() == null || endpoint.getMethod().isBlank()) {
                throw new IllegalArgumentException("Schema validation error at " + location + ": Missing or empty HTTP 'method'.");
            }
            String methodUpper = endpoint.getMethod().toUpperCase();
            if (!methodUpper.equals("GET") && !methodUpper.equals("POST") && !methodUpper.equals("PUT")
                    && !methodUpper.equals("DELETE") && !methodUpper.equals("PATCH")) {
                throw new IllegalArgumentException("Schema validation error at " + location + ": Invalid HTTP method '" + endpoint.getMethod() + "'. Must be GET, POST, PUT, DELETE, or PATCH.");
            }
            String endpointKey = endpoint.getMethod().toUpperCase() + " " + endpoint.getPath();
            if (!seenEndpoints.add(endpointKey)) {
                throw new IllegalArgumentException("Schema validation error at " + location + ": Duplicate endpoint " + endpointKey + ".");
            }
            if (endpoint.getBackendUrl() == null || endpoint.getBackendUrl().isBlank()) {
                throw new IllegalArgumentException("Schema validation error at " + location + ": Missing or empty 'backendUrl'.");
            }

            if (model.getFlags() != null && model.getFlags().isEnableTelemetry()) {
                if (endpoint.getTelemetryName() == null || endpoint.getTelemetryName().isBlank()) {
                    throw new IllegalArgumentException("Schema validation error at " + location + ": 'telemetryName' is mandatory when flags.enableTelemetry is active.");
                }
            }

            if (endpoint.getUiLayout() != null) {
                BridgeSchemaModel.UiLayout layout = endpoint.getUiLayout();
                if (layout.getComponent() == null || layout.getComponent().isBlank()) {
                    throw new IllegalArgumentException("Schema validation error at " + location + ".uiLayout: Missing or empty layout 'component' type.");
                }
                String comp = layout.getComponent().toLowerCase();
                if (!comp.equals("form") && !comp.equals("list") && !comp.equals("view")) {
                    throw new IllegalArgumentException("Schema validation error at " + location + ".uiLayout.component: Must be 'Form', 'List', or 'View'.");
                }
                if (layout.getFields() != null) {
                    for (int j = 0; j < layout.getFields().size(); j++) {
                        BridgeSchemaModel.Field field = layout.getFields().get(j);
                        String fieldLocation = location + ".uiLayout.fields[" + j + "]";
                        if (field.getName() == null || field.getName().isBlank()) {
                            throw new IllegalArgumentException("Schema validation error at " + fieldLocation + ": Missing or empty field 'name'.");
                        }
                        if (comp.equals("form") && (field.getType() == null || field.getType().isBlank())) {
                            throw new IllegalArgumentException("Schema validation error at " + fieldLocation + ": Missing or empty field 'type'.");
                        }
                    }
                }
                if (layout.getColumns() != null) {
                    for (int j = 0; j < layout.getColumns().size(); j++) {
                        BridgeSchemaModel.Column col = layout.getColumns().get(j);
                        String colLocation = location + ".uiLayout.columns[" + j + "]";
                        if (col.getField() == null || col.getField().isBlank()) {
                            throw new IllegalArgumentException("Schema validation error at " + colLocation + ": Missing or empty column 'field'.");
                        }
                    }
                }
            }
        }
    }
}
