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
import java.util.logging.Logger;

/**
 * Parses and validates ApiBridge YAML schema files into {@link BridgeSchemaModel} instances.
 *
 * <p>Usage: {@code new YamlParser().parse(schemaFile)} — parses the YAML, then runs
 * full structural validation (required fields, enum values, endpoint uniqueness,
 * UI layout rules, transform rules, etc.).</p>
 */
public class YamlParser {

    private static final Set<String> VALID_HTTP_METHODS = Set.of("GET", "POST", "PUT", "DELETE", "PATCH");
    private static final Set<String> VALID_COMPONENT_TYPES = Set.of("form", "list", "view");
    private static final Set<String> VALID_SEARCH_MODES = Set.of("delegate", "local");
    private static final Logger LOG = Logger.getLogger(YamlParser.class.getName());

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

    /**
     * Validates a fully-populated schema model. Called automatically by {@link #parse(File)},
     * but can also be called directly on a programmatically constructed model.
     *
     * @param model the schema model to validate (must not be null)
     * @throws IllegalArgumentException on any validation failure
     */
    public void validate(BridgeSchemaModel model) {
        if (model == null) {
            throw new IllegalArgumentException("Schema model cannot be null.");
        }
        validateTopLevel(model);
        validateFlagsSection(model);

        List<String> warnings = validateEndpoints(model);
        if (!warnings.isEmpty()) {
            LOG.warning("Transforms defined on endpoint(s) " + warnings
                    + " but flags.enableTransform is not true — transforms will be ignored.");
        }
    }

    private void validateTopLevel(BridgeSchemaModel model) {
        if (model.getId() == null || model.getId().isBlank()) {
            throw new IllegalArgumentException("Schema validation error: Missing or empty 'id' parameter.");
        }
        if (model.getBasePath() == null || model.getBasePath().isBlank()) {
            throw new IllegalArgumentException("Schema validation error: Missing or empty 'basePath' parameter.");
        }
        if (model.getEndpoints() == null || model.getEndpoints().isEmpty()) {
            throw new IllegalArgumentException("Schema validation error: Configuration must define at least one endpoint under 'endpoints'.");
        }
    }

    private void validateFlagsSection(BridgeSchemaModel model) {
        BridgeSchemaModel.Flags flags = model.getFlags();
        if (flags == null) {
            return;
        }

        validateEnum(flags.getBackendFlavor(), "flags.backendFlavor", "spring-boot", "quarkus");
        validateEnum(flags.getFeFlavor(), "flags.feFlavor", "angular", "react", "vue");
        validateEnum(flags.getDeployTarget(), "flags.deployTarget", "docker-compose", "kubernetes", "openshift");
        validateEnum(flags.getSecurityLevel(), "flags.securityLevel", "bearer-token", "apiKey");

        flags.setBackendFlavor(normalizeEnum(flags.getBackendFlavor(), "spring-boot", "quarkus"));
        flags.setFeFlavor(normalizeEnum(flags.getFeFlavor(), "angular", "react", "vue"));
        flags.setDeployTarget(normalizeEnum(flags.getDeployTarget(), "docker-compose", "kubernetes", "openshift"));
        flags.setSecurityLevel(normalizeEnum(flags.getSecurityLevel(), "bearer-token", "apiKey"));

        validatePagination(flags.getPagination());
        validateApiVersion(flags);

        requireNonBlankIf(flags.isEnableOidc(), flags.getOidcIssuerUri(),
                "flags.oidcIssuerUri must be non-blank when flags.enableOidc is true.");
    }

    private void validatePagination(BridgeSchemaModel.Pagination p) {
        if (p == null) {
            return;
        }
        if (p.getDefaultPageSize() <= 0) {
            throw new IllegalArgumentException("Schema validation error: flags.pagination.defaultPageSize must be a positive integer.");
        }
        validatePaginationParam(p.getPageParam(), "pageParam");
        validatePaginationParam(p.getSizeParam(), "sizeParam");
        validatePaginationParam(p.getSortParam(), "sortParam");
        validatePaginationParam(p.getDirectionParam(), "directionParam");
    }

    private void validateApiVersion(BridgeSchemaModel.Flags flags) {
        if (flags.getApiVersion() == null) {
            return;
        }
        String version = flags.getApiVersion().trim();
        if (!version.matches("v[0-9]+")) {
            throw new IllegalArgumentException("Schema validation error: flags.apiVersion must match pattern v[0-9]+ (e.g. 'v1', 'v2'). Got '" + version + "'.");
        }
    }

    private List<String> validateEndpoints(BridgeSchemaModel model) {
        BridgeSchemaModel.Flags flags = model.getFlags();
        Set<String> seenEndpoints = new HashSet<>();
        List<String> transformWarningEndpoints = new ArrayList<>();

        for (int i = 0; i < model.getEndpoints().size(); i++) {
            validateEndpoint(model.getEndpoints().get(i), i, flags, seenEndpoints, transformWarningEndpoints);
        }
        return transformWarningEndpoints;
    }

    private void validateEndpoint(BridgeSchemaModel.Endpoint endpoint, int index,
                                  BridgeSchemaModel.Flags flags, Set<String> seenEndpoints,
                                  List<String> transformWarnings) {
        String location = "endpoints[" + index + "]";

        if (endpoint.getPath() == null || endpoint.getPath().isBlank()) {
            throw new IllegalArgumentException("Schema validation error at " + location + ": Missing or empty 'path'.");
        }
        if (endpoint.getMethod() == null || endpoint.getMethod().isBlank()) {
            throw new IllegalArgumentException("Schema validation error at " + location + ": Missing or empty HTTP 'method'.");
        }
        String methodUpper = endpoint.getMethod().toUpperCase();
        if (!VALID_HTTP_METHODS.contains(methodUpper)) {
            throw new IllegalArgumentException("Schema validation error at " + location + ": Invalid HTTP method '" + endpoint.getMethod() + "'. Must be GET, POST, PUT, DELETE, or PATCH.");
        }
        String endpointKey = methodUpper + " " + normalizePathShape(endpoint.getPath());
        if (!seenEndpoints.add(endpointKey)) {
            throw new IllegalArgumentException("Schema validation error at " + location + ": Duplicate endpoint " + endpointKey + ".");
        }
        if (endpoint.getBackendUrl() == null || endpoint.getBackendUrl().isBlank()) {
            throw new IllegalArgumentException("Schema validation error at " + location + ": Missing or empty 'backendUrl'.");
        }

        requireNonBlankIf(flags != null && flags.isEnableTelemetry(), endpoint.getTelemetryName(),
                "Schema validation error at " + location + ": 'telemetryName' is mandatory when flags.enableTelemetry is active.");

        validateUiLayout(endpoint.getUiLayout(), location, flags);
        validateMockResponse(endpoint.getMockResponse(), location);
        validateTransforms(endpoint, location, flags, transformWarnings);
    }

    private void validateUiLayout(BridgeSchemaModel.UiLayout layout, String location,
                                  BridgeSchemaModel.Flags flags) {
        if (layout == null) {
            return;
        }
        if (layout.getComponent() == null || layout.getComponent().isBlank()) {
            throw new IllegalArgumentException("Schema validation error at " + location + ".uiLayout: Missing or empty layout 'component' type.");
        }
        String comp = layout.getComponent().toLowerCase();
        if (!VALID_COMPONENT_TYPES.contains(comp)) {
            throw new IllegalArgumentException("Schema validation error at " + location + ".uiLayout.component: Must be 'Form', 'List', or 'View'.");
        }
        validateFields(layout, comp, location);
        validateColumns(layout, location);
        validateSearchMode(layout, comp, location, flags);
    }

    private void validateFields(BridgeSchemaModel.UiLayout layout, String comp, String location) {
        if (layout.getFields() == null) {
            return;
        }
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

    private void validateColumns(BridgeSchemaModel.UiLayout layout, String location) {
        if (layout.getColumns() == null) {
            return;
        }
        for (int j = 0; j < layout.getColumns().size(); j++) {
            BridgeSchemaModel.Column col = layout.getColumns().get(j);
            String colLocation = location + ".uiLayout.columns[" + j + "]";
            if (col.getField() == null || col.getField().isBlank()) {
                throw new IllegalArgumentException("Schema validation error at " + colLocation + ": Missing or empty column 'field'.");
            }
        }
    }

    private void validateSearchMode(BridgeSchemaModel.UiLayout layout, String comp,
                                    String location, BridgeSchemaModel.Flags flags) {
        if (layout.getSearchMode() == null) {
            return;
        }
        if (!comp.equals("list")) {
            throw new IllegalArgumentException("Schema validation error at " + location + ".uiLayout.searchMode: searchMode is only valid on List components.");
        }
        requireFlagForField(layout.getSearchMode(),
                flags != null && flags.isEnableSearch(),
                location + ".uiLayout.searchMode", "flags.enableSearch");
        String sm = layout.getSearchMode().toLowerCase();
        if (!VALID_SEARCH_MODES.contains(sm)) {
            throw new IllegalArgumentException("Schema validation error at " + location + ".uiLayout.searchMode: Must be 'delegate' or 'local'. Got '" + layout.getSearchMode() + "'.");
        }
    }

    private void validateMockResponse(BridgeSchemaModel.MockResponse mock, String location) {
        if (mock == null) {
            return;
        }
        if (mock.getStatusCode() < 100 || mock.getStatusCode() > 599) {
            throw new IllegalArgumentException("Schema validation error at " + location + ".mockResponse.statusCode: Must be 100–599. Got " + mock.getStatusCode() + ".");
        }
        if (mock.getDelayMs() < 0) {
            throw new IllegalArgumentException("Schema validation error at " + location + ".mockResponse.delayMs: Must be >= 0. Got " + mock.getDelayMs() + ".");
        }
    }

    private void validateTransforms(BridgeSchemaModel.Endpoint endpoint, String location,
                                    BridgeSchemaModel.Flags flags, List<String> warnings) {
        if (endpoint.getTransforms() == null) {
            return;
        }
        boolean transformEnabled = flags != null && flags.isEnableTransform();
        if (!transformEnabled) {
            warnings.add(endpoint.getPath());
            return;
        }
        validateTransformSubObject(endpoint.getTransforms().getRequestHeaders(), location, "requestHeaders");
        validateTransformSubObject(endpoint.getTransforms().getResponseHeaders(), location, "responseHeaders");
        validateFieldTransform(endpoint.getTransforms().getRequestFields(), location, "requestFields");
        validateFieldTransform(endpoint.getTransforms().getResponseFields(), location, "responseFields");
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

    private static String normalizeEnum(String value, String... validValues) {
        if (value == null) {
            return null;
        }
        String lower = value.toLowerCase();
        for (String valid : validValues) {
            if (lower.equals(valid.toLowerCase())) {
                return valid;
            }
        }
        return value;
    }

    static String normalizePathShape(String path) {
        return path.replaceAll("\\{[^}]+}", "{*}");
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
