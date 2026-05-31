package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserUiLayoutTest extends YamlParserTestBase {

    // --- component ---

    @Test
    public void testUiLayoutRequiresComponent(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      fields: []
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("uiLayout"));
        assertTrue(ex.getMessage().contains("component"));
    }

    @Test
    public void testBlankUiLayoutComponentThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      component: "   "
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("component"));
    }

    // --- T.1: Invalid component value throws ---

    @Test
    public void testInvalidComponentValueThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                    uiLayout:
                      component: "Table"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("component"));
        assertTrue(ex.getMessage().contains("Form") || ex.getMessage().contains("List") || ex.getMessage().contains("View"));
    }

    // --- uiLayout general ---

    @Test
    public void testUiLayoutWithNullFieldsIsValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      component: "Form"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        BridgeSchemaModel.UiLayout layout = model.getEndpoints().get(0).getUiLayout();
        assertNotNull(layout);
        assertEquals("Form", layout.getComponent());
        assertNull(layout.getFields());
    }

    @Test
    public void testValidSchemaWithUiLayout(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test-service"
                basePath: "/api/test"
                endpoints:
                  - path: "/submit"
                    method: "POST"
                    backendUrl: "https://example.com/submit"
                    uiLayout:
                      component: "Form"
                      fields:
                        - name: "email"
                          type: "string"
                          required: true
                        - name: "age"
                          type: "number"
                          required: false
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals(1, model.getEndpoints().size());
        BridgeSchemaModel.UiLayout layout = model.getEndpoints().get(0).getUiLayout();
        assertNotNull(layout);
        assertEquals("Form", layout.getComponent());
        assertEquals(2, layout.getFields().size());
        assertEquals("email", layout.getFields().get(0).getName());
        assertTrue(layout.getFields().get(0).isRequired());
        assertFalse(layout.getFields().get(1).isRequired());
    }

    // --- columns ---

    @Test
    public void testUiLayoutColumnsForListComponent(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                    uiLayout:
                      component: "List"
                      columns:
                        - field: "name"
                          label: "Full Name"
                          sortable: true
                        - field: "email"
                          sortable: false
                          width: "200px"
                """);
        BridgeSchemaModel model = parser.parse(file);
        BridgeSchemaModel.UiLayout layout = model.getEndpoints().get(0).getUiLayout();
        assertEquals("List", layout.getComponent());
        assertEquals(2, layout.getColumns().size());
        BridgeSchemaModel.Column col0 = layout.getColumns().get(0);
        assertEquals("name", col0.getField());
        assertEquals("Full Name", col0.getLabel());
        assertTrue(col0.isSortable());
        assertNull(col0.getWidth());
        BridgeSchemaModel.Column col1 = layout.getColumns().get(1);
        assertEquals("email", col1.getField());
        assertFalse(col1.isSortable());
        assertEquals("200px", col1.getWidth());
    }

    @Test
    public void testColumnMissingFieldThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                    uiLayout:
                      component: "List"
                      columns:
                        - label: "Name"
                          sortable: true
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().toLowerCase().contains("column") ||
                   ex.getMessage().toLowerCase().contains("field"));
    }

    @Test
    public void testBlankColumnFieldThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                    uiLayout:
                      component: "List"
                      columns:
                        - field: "   "
                          label: "Name"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("field"));
    }

    // --- T.19: Column.sortable defaults false ---

    @Test
    public void testColumnSortableDefaultsFalse(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                    uiLayout:
                      component: "List"
                      columns:
                        - field: "name"
                          label: "Name"
                """);
        BridgeSchemaModel model = parser.parse(file);
        BridgeSchemaModel.Column col = model.getEndpoints().get(0).getUiLayout().getColumns().get(0);
        assertFalse(col.isSortable());
    }

    // --- T.20: Column.label null when absent ---

    @Test
    public void testColumnLabelNullWhenAbsent(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                    uiLayout:
                      component: "List"
                      columns:
                        - field: "name"
                          sortable: true
                """);
        BridgeSchemaModel model = parser.parse(file);
        BridgeSchemaModel.Column col = model.getEndpoints().get(0).getUiLayout().getColumns().get(0);
        assertNull(col.getLabel());
    }

    // --- T.26: Second column error includes columns[1] in message ---

    @Test
    public void testSecondColumnErrorIncludesIndex(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                    uiLayout:
                      component: "List"
                      columns:
                        - field: "name"
                        - label: "Email"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("columns[1]"));
    }
}
