package com.apibridge.engine.model;

import java.util.List;

public class BridgeSchemaModel {
    private String id;
    private String basePath;
    private Flags flags;
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

    public static class Flags {
        private boolean enableTelemetry;
        private String securityLevel;
        private String backendFlavor = "spring-boot";
        private String uiPattern = "form-engine";
        private String feFlavor;
        private String deployTarget;
        private String navigationMode = "spa";
        private Pagination pagination = new Pagination();

        public boolean isEnableTelemetry() { return enableTelemetry; }
        public void setEnableTelemetry(boolean enableTelemetry) { this.enableTelemetry = enableTelemetry; }

        public String getSecurityLevel() { return securityLevel; }
        public void setSecurityLevel(String securityLevel) { this.securityLevel = securityLevel; }

        public String getBackendFlavor() { return backendFlavor; }
        public void setBackendFlavor(String backendFlavor) { this.backendFlavor = backendFlavor; }

        public String getUiPattern() { return uiPattern; }
        public void setUiPattern(String uiPattern) { this.uiPattern = uiPattern; }

        public String getFeFlavor() { return feFlavor; }
        public void setFeFlavor(String feFlavor) { this.feFlavor = feFlavor; }

        public String getDeployTarget() { return deployTarget; }
        public void setDeployTarget(String deployTarget) { this.deployTarget = deployTarget; }

        public String getNavigationMode() { return navigationMode; }
        public void setNavigationMode(String navigationMode) { this.navigationMode = navigationMode; }

        public Pagination getPagination() { return pagination; }
        public void setPagination(Pagination pagination) { this.pagination = pagination; }

        @Override
        public String toString() {
            return "Flags{enableTelemetry=" + enableTelemetry + ", securityLevel='" + securityLevel
                    + "', backendFlavor='" + backendFlavor + "', uiPattern='" + uiPattern
                    + "', feFlavor='" + feFlavor + "', deployTarget='" + deployTarget
                    + "', navigationMode='" + navigationMode + "', pagination=" + pagination + '}';
        }
    }

    // -------------------------------------------------------------------------

    public static class Pagination {
        private String pageParam = "page";
        private String sizeParam = "size";
        private int defaultPageSize = 20;
        private String sortParam = "sort";
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

    public static class Endpoint {
        private String path;
        private String method;
        private String backendUrl;
        private String telemetryName;
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

    public static class UiLayout {
        private String component;
        private List<Field> fields;
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

    public static class Field {
        private String name;
        private String label;
        private String type;
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

    public static class Column {
        private String field;
        private String label;
        private boolean sortable;
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
