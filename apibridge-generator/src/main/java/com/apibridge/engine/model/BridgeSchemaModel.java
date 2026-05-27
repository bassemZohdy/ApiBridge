package com.apibridge.engine.model;

import java.util.List;

/**
 * Root model representing a parsed ApiBridge YAML schema.
 * Contains the service identity, base REST path, configuration flags, and endpoint definitions.
 */
public class BridgeSchemaModel {
    /** Unique service identifier used as the application name and for logging. */
    private String id;
    /** REST base path prepended to all endpoint paths (e.g. "/api/v1"). */
    private String basePath;
    /** Optional configuration flags controlling code generation and runtime behavior. */
    private Flags flags;
    /** Ordered list of endpoint definitions to generate proxy routes and UI components for. */
    private List<Endpoint> endpoints;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getBasePath() { return basePath; }
    public void setBasePath(String basePath) { this.basePath = basePath; }

    public Flags getFlags() { return flags; }
    public void setFlags(Flags flags) { this.flags = flags; }

    public List<Endpoint> getEndpoints() { return endpoints; }
    public void setEndpoints(List<Endpoint> endpoints) { this.endpoints = endpoints; }

    @Override
    public String toString() {
        return "BridgeSchemaModel{id='" + id + "', basePath='" + basePath + "', flags=" + flags + ", endpoints=" + endpoints + '}';
    }

    // -------------------------------------------------------------------------

    /**
     * Configuration flags controlling code generation and runtime behavior.
     * All fields have sensible defaults; only overrides need to be specified in the schema.
     */
    public static class Flags {
        /** Whether to emit OpenTelemetry tracing spans in generated backend code. */
        private boolean enableTelemetry;
        /** Security validation mode: "bearer-token", "apiKey", or null for no security. */
        private String securityLevel;
        /** Backend framework to generate: "spring-boot" (default) or "quarkus". */
        private String backendFlavor = "spring-boot";
        /** Frontend framework to generate: "angular", "react", "vue", or null if no frontend. */
        private String feFlavor;
        /** Deployment target to generate configs for: "docker-compose", "kubernetes", "openshift", or null. */
        private String deployTarget;
        /** Pagination defaults applied to List-type endpoints. */
        private Pagination pagination = new Pagination();

        public boolean isEnableTelemetry() { return enableTelemetry; }
        public void setEnableTelemetry(boolean enableTelemetry) { this.enableTelemetry = enableTelemetry; }

        public String getSecurityLevel() { return securityLevel; }
        public void setSecurityLevel(String securityLevel) { this.securityLevel = securityLevel; }

        public String getBackendFlavor() { return backendFlavor; }
        public void setBackendFlavor(String backendFlavor) { this.backendFlavor = backendFlavor; }

        public String getFeFlavor() { return feFlavor; }
        public void setFeFlavor(String feFlavor) { this.feFlavor = feFlavor; }

        public String getDeployTarget() { return deployTarget; }
        public void setDeployTarget(String deployTarget) { this.deployTarget = deployTarget; }

        public Pagination getPagination() { return pagination; }
        public void setPagination(Pagination pagination) { this.pagination = pagination; }

        @Override
        public String toString() {
            return "Flags{enableTelemetry=" + enableTelemetry + ", securityLevel='" + securityLevel
                    + "', backendFlavor='" + backendFlavor
                    + "', feFlavor='" + feFlavor + "', deployTarget='" + deployTarget
                    + "', pagination=" + pagination + '}';
        }
    }

    // -------------------------------------------------------------------------

    /**
     * Pagination configuration for list-style endpoints.
     * Controls query parameter names and default page sizing.
     */
    public static class Pagination {
        /** Query parameter name for the page number (default: "page"). */
        private String pageParam = "page";
        /** Query parameter name for the page size (default: "size"). */
        private String sizeParam = "size";
        /** Default number of items per page when no size parameter is provided (default: 20). */
        private int defaultPageSize = 20;
        /** Query parameter name for the sort field (default: "sort"). */
        private String sortParam = "sort";
        /** Query parameter name for the sort direction, e.g. "asc" or "desc" (default: "dir"). */
        private String directionParam = "dir";

        public String getPageParam() { return pageParam; }
        public void setPageParam(String pageParam) { this.pageParam = pageParam; }

        public String getSizeParam() { return sizeParam; }
        public void setSizeParam(String sizeParam) { this.sizeParam = sizeParam; }

        public int getDefaultPageSize() { return defaultPageSize; }
        public void setDefaultPageSize(int defaultPageSize) { this.defaultPageSize = defaultPageSize; }

        public String getSortParam() { return sortParam; }
        public void setSortParam(String sortParam) { this.sortParam = sortParam; }

        public String getDirectionParam() { return directionParam; }
        public void setDirectionParam(String directionParam) { this.directionParam = directionParam; }

        @Override
        public String toString() {
            return "Pagination{pageParam='" + pageParam + "', sizeParam='" + sizeParam
                    + "', defaultPageSize=" + defaultPageSize + ", sortParam='" + sortParam
                    + "', directionParam='" + directionParam + "'}";
        }
    }

    // -------------------------------------------------------------------------

    /**
     * Defines a single REST endpoint to proxy, including its upstream backend URL
     * and optional UI layout for rendering a form, list, or detail view.
     */
    public static class Endpoint {
        /** URL path relative to basePath (e.g. "/orders/{id}"). */
        private String path;
        /** HTTP method: GET, POST, PUT, DELETE, or PATCH. */
        private String method;
        /** Fully-qualified upstream backend URL to proxy requests to. */
        private String backendUrl;
        /** Custom span name used when enableTelemetry is active. */
        private String telemetryName;
        /** Optional UI layout describing how this endpoint should be rendered in the frontend. */
        private UiLayout uiLayout;

        public String getPath() { return path; }
        public void setPath(String path) { this.path = path; }

        public String getMethod() { return method; }
        public void setMethod(String method) { this.method = method; }

        public String getBackendUrl() { return backendUrl; }
        public void setBackendUrl(String backendUrl) { this.backendUrl = backendUrl; }

        public String getTelemetryName() { return telemetryName; }
        public void setTelemetryName(String telemetryName) { this.telemetryName = telemetryName; }

        public UiLayout getUiLayout() { return uiLayout; }
        public void setUiLayout(UiLayout uiLayout) { this.uiLayout = uiLayout; }

        @Override
        public String toString() {
            return "Endpoint{path='" + path + "', method='" + method + "', backendUrl='" + backendUrl
                    + "', telemetryName='" + telemetryName + "', uiLayout=" + uiLayout + '}';
        }
    }

    // -------------------------------------------------------------------------

    /**
     * Describes the frontend UI layout for an endpoint.
     * The component type determines whether a form, list, or detail view is rendered.
     */
    public static class UiLayout {
        /** Component type to render: "Form", "List", or "View" (case-insensitive). */
        private String component;
        /** Form fields for Form-type components. Each field defines a labeled input. */
        private List<Field> fields;
        /** Table columns for List-type components. Each column maps to a data field. */
        private List<Column> columns;

        public String getComponent() { return component; }
        public void setComponent(String component) { this.component = component; }

        public List<Field> getFields() { return fields; }
        public void setFields(List<Field> fields) { this.fields = fields; }

        public List<Column> getColumns() { return columns; }
        public void setColumns(List<Column> columns) { this.columns = columns; }

        @Override
        public String toString() {
            return "UiLayout{component='" + component + "', fields=" + fields + ", columns=" + columns + '}';
        }
    }

    // -------------------------------------------------------------------------

    /**
     * Represents a single form input field within a Form-type UI layout.
     * Defines the field name, display label, input type, and whether it is required.
     */
    public static class Field {
        /** Programmatic field name matching the JSON property key. */
        private String name;
        /** Human-readable label shown next to the input. */
        private String label;
        /** Input type for form rendering (e.g. "text", "number", "email", "date"). Required for Form components. */
        private String type;
        /** Whether the field must be filled in before submission. */
        private boolean required;

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public String getLabel() { return label; }
        public void setLabel(String label) { this.label = label; }

        public String getType() { return type; }
        public void setType(String type) { this.type = type; }

        public boolean isRequired() { return required; }
        public void setRequired(boolean required) { this.required = required; }

        @Override
        public String toString() {
            return "Field{name='" + name + "', label='" + label + "', type='" + type + "', required=" + required + '}';
        }
    }

    // -------------------------------------------------------------------------

    /**
     * Represents a single column in a List-type UI layout (data table).
     * Maps a data field to a sortable, optionally sized table column.
     */
    public static class Column {
        /** Data field name this column displays, matching a JSON property key. */
        private String field;
        /** Human-readable column header text. */
        private String label;
        /** Whether the user can sort the table by this column. */
        private boolean sortable;
        /** CSS width hint for the column (e.g. "200px", "20%"). */
        private String width;

        public String getField() { return field; }
        public void setField(String field) { this.field = field; }

        public String getLabel() { return label; }
        public void setLabel(String label) { this.label = label; }

        public boolean isSortable() { return sortable; }
        public void setSortable(boolean sortable) { this.sortable = sortable; }

        public String getWidth() { return width; }
        public void setWidth(String width) { this.width = width; }

        @Override
        public String toString() {
            return "Column{field='" + field + "', label='" + label + "', sortable=" + sortable + ", width='" + width + "'}";
        }
    }
}
