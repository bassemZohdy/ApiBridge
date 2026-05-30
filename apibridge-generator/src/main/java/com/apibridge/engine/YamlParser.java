package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
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
        if (model == null) {
            throw new IllegalArgumentException("Schema model cannot be null.");
        }
        List<String> transformWarningEndpoints = new ArrayList<>();
        if (model.getId() == null || model.getId().isBlank()) {
            throw new IllegalArgumentException("Schema validation error: Missing or empty 'id' parameter.");
        }
        if (model.getBasePath() == null || model.getBasePath().isBlank()) {
            throw new IllegalArgumentException("Schema validation error: Missing or empty 'basePath' parameter.");
        }
        if (model.getEndpoints() == null || model.getEndpoints().isEmpty()) {
            throw new IllegalArgumentException("Schema validation error: Configuration must define at least one endpoint under 'endpoints'.");
        }

        BridgeSchemaModel.Flags flags = model.getFlags();

        if (flags != null) {
            validateEnum(flags.getBackendFlavor(), "flags.backendFlavor", "spring-boot", "quarkus");
            validateEnum(flags.getFeFlavor(), "flags.feFlavor", "angular", "react", "vue");
            validateEnum(flags.getDeployTarget(), "flags.deployTarget", "docker-compose", "kubernetes", "openshift");
            validateEnum(flags.getSecurityLevel(), "flags.securityLevel", "bearer-token", "apiKey");

            // Pagination is auto-initialized (never null when flags is non-null), so this guard
            // checks whether the user explicitly set pagination values. Defaults pass validation.
            if (flags.getPagination() != null) {
                BridgeSchemaModel.Pagination p = flags.getPagination();
                if (p.getDefaultPageSize() <= 0) {
                    throw new IllegalArgumentException("Schema validation error: flags.pagination.defaultPageSize must be a positive integer.");
                }
                validatePaginationParam(p.getPageParam(), "pageParam");
                validatePaginationParam(p.getSizeParam(), "sizeParam");
                validatePaginationParam(p.getSortParam(), "sortParam");
                validatePaginationParam(p.getDirectionParam(), "directionParam");
            }

            if (flags.getApiVersion() != null) {
                String version = flags.getApiVersion().trim();
                if (!version.matches("v[0-9]+")) {
                    throw new IllegalArgumentException("Schema validation error: flags.apiVersion must match pattern v[0-9]+ (e.g. 'v1', 'v2'). Got '" + version + "'.");
                }
            }

            requireNonBlankIf(flags.isEnableOidc(), flags.getOidcIssuerUri(),
                    "flags.oidcIssuerUri must be non-blank when flags.enableOidc is true.");
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

            requireNonBlankIf(flags != null && flags.isEnableTelemetry(), endpoint.getTelemetryName(),
                    "Schema validation error at " + location + ": 'telemetryName' is mandatory when flags.enableTelemetry is active.");

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
                if (layout.getSearchMode() != null) {
                    if (!comp.equals("list")) {
                        throw new IllegalArgumentException("Schema validation error at " + location + ".uiLayout.searchMode: searchMode is only valid on List components.");
                    }
                    requireFlagForField(layout.getSearchMode(),
                            flags != null && flags.isEnableSearch(),
                            location + ".uiLayout.searchMode", "flags.enableSearch");
                    String sm = layout.getSearchMode().toLowerCase();
                    if (!sm.equals("delegate") && !sm.equals("local")) {
                        throw new IllegalArgumentException("Schema validation error at " + location + ".uiLayout.searchMode: Must be 'delegate' or 'local'. Got '" + layout.getSearchMode() + "'.");
                    }
                }
            }

            if (endpoint.getMockResponse() != null) {
                BridgeSchemaModel.MockResponse mock = endpoint.getMockResponse();
                if (mock.getStatusCode() < 100 || mock.getStatusCode() > 599) {
                    throw new IllegalArgumentException("Schema validation error at " + location + ".mockResponse.statusCode: Must be 100–599. Got " + mock.getStatusCode() + ".");
                }
                if (mock.getDelayMs() < 0) {
                    throw new IllegalArgumentException("Schema validation error at " + location + ".mockResponse.delayMs: Must be >= 0. Got " + mock.getDelayMs() + ".");
                }
            }

            if (endpoint.getTransforms() != null) {
                boolean transformEnabled = flags != null && flags.isEnableTransform();
                if (!transformEnabled) {
                    transformWarningEndpoints.add(endpoint.getPath());
                } else {
                    validateTransformSubObject(endpoint.getTransforms().getRequestHeaders(), location, "requestHeaders");
                    validateTransformSubObject(endpoint.getTransforms().getResponseHeaders(), location, "responseHeaders");
                    validateFieldTransform(endpoint.getTransforms().getRequestFields(), location, "requestFields");
                    validateFieldTransform(endpoint.getTransforms().getResponseFields(), location, "responseFields");
                }
            }
        }

        if (!transformWarningEndpoints.isEmpty()) {
            System.err.println("Warning: transforms defined on endpoint(s) " + transformWarningEndpoints
                    + " but flags.enableTransform is not true — transforms will be ignored.");
        }
    }

    private static void validateEnum(String value, String fieldPath, String... validValues) {
        if (value == null) {
            return;
        }
        String lower = value.toLowerCase();
        for (String valid : validValues) {
            if (lower.equals(valid.toLowerCase())) {
                return;
            }
        }
        throw new IllegalArgumentException("Schema validation error: Invalid " + fieldPath
                + " value '" + value + "'. Must be " + formatEnumValues(validValues) + ".");
    }

    private static String formatEnumValues(String... values) {
        if (values.length == 1) {
            return "'" + values[0] + "'";
        }
        if (values.length == 2) {
            return "'" + values[0] + "' or '" + values[1] + "'";
        }
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < values.length; i++) {
            if (i > 0) {
                sb.append(i == values.length - 1 ? ", or " : ", ");
            }
            sb.append("'").append(values[i]).append("'");
        }
        return sb.toString();
    }

    private void requireNonBlankIf(boolean condition, String value, String message) {
        if (condition && (value == null || value.isBlank())) {
            throw new IllegalArgumentException(message);
        }
    }

    private void requireFlagForField(String fieldValue, boolean flagEnabled, String fieldPath, String flagPath) {
        if (fieldValue != null && !flagEnabled) {
            throw new IllegalArgumentException("Schema validation error at " + fieldPath + " requires " + flagPath + " to be true.");
        }
    }

    private void validatePaginationParam(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Schema validation error: flags.pagination." + fieldName + " must not be blank.");
        }
    }

    private void validateTransformSubObject(BridgeSchemaModel.HeaderTransform ht, String location, String subName) {
        if (ht == null) {
            return;
        }
        String base = location + ".transforms." + subName;
        validateRenameMap(ht.getRename(), base);
        validateRemoveList(ht.getRemove(), base);
        if (ht.getAdd() != null) {
            for (Map.Entry<String, String> entry : ht.getAdd().entrySet()) {
                if (entry.getKey() == null || entry.getKey().isBlank()) {
                    throw new IllegalArgumentException("Schema validation error at " + base + ".add: blank header name.");
                }
                if (entry.getValue() == null || entry.getValue().isBlank()) {
                    throw new IllegalArgumentException("Schema validation error at " + base + ".add: blank value for header '" + entry.getKey() + "'.");
                }
            }
        }
    }

    private void validateFieldTransform(BridgeSchemaModel.FieldTransform ft, String location, String subName) {
        if (ft == null) {
            return;
        }
        String base = location + ".transforms." + subName;
        validateRenameMap(ft.getRename(), base);
        validateRemoveList(ft.getRemove(), base);
    }

    private void validateRenameMap(java.util.Map<String, String> rename, String base) {
        if (rename == null) {
            return;
        }
        for (Map.Entry<String, String> entry : rename.entrySet()) {
            if (entry.getKey() == null || entry.getKey().isBlank()) {
                throw new IllegalArgumentException("Schema validation error at " + base + ".rename: blank key.");
            }
            if (entry.getValue() == null || entry.getValue().isBlank()) {
                throw new IllegalArgumentException("Schema validation error at " + base + ".rename: blank value for key '" + entry.getKey() + "'.");
            }
        }
    }

    private void validateRemoveList(java.util.List<String> remove, String base) {
        if (remove == null) {
            return;
        }
        for (String entry : remove) {
            if (entry == null || entry.isBlank()) {
                throw new IllegalArgumentException("Schema validation error at " + base + ".remove: blank entry.");
            }
        }
    }
}
