package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserUiFieldTest extends YamlParserTestBase {

    @Test
    public void testUiLayoutFieldRequiresName(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      component: "Form"
                      fields:
                        - type: "string"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("fields[0]"));
        assertTrue(ex.getMessage().contains("name"));
    }

    @Test
    public void testBlankUiLayoutFieldNameThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      component: "Form"
                      fields:
                        - name: "   "
                          type: "string"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("name"));
    }

    @Test
    public void testUiLayoutFieldRequiresType(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      component: "Form"
                      fields:
                        - name: "email"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("fields[0]"));
        assertTrue(ex.getMessage().contains("type"));
    }

    @Test
    public void testBlankUiLayoutFieldTypeThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      component: "Form"
                      fields:
                        - name: "email"
                          type: "   "
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("type"));
    }

    @Test
    public void testViewComponentDoesNotRequireFieldType(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items/{id}"
                    method: "GET"
                    backendUrl: "https://example.com/items/1"
                    uiLayout:
                      component: "View"
                      fields:
                        - name: "name"
                          label: "Full Name"
                """);
        BridgeSchemaModel model = parser.parse(file);
        BridgeSchemaModel.Field f = model.getEndpoints().get(0).getUiLayout().getFields().get(0);
        assertEquals("name", f.getName());
        assertEquals("Full Name", f.getLabel());
        assertNull(f.getType());
    }

    @Test
    public void testFieldLabelOptional(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/submit"
                    method: "POST"
                    backendUrl: "https://example.com/submit"
                    uiLayout:
                      component: "Form"
                      fields:
                        - name: "email"
                          type: "string"
                          label: "Email Address"
                        - name: "age"
                          type: "number"
                """);
        BridgeSchemaModel model = parser.parse(file);
        var fields = model.getEndpoints().get(0).getUiLayout().getFields();
        assertEquals("Email Address", fields.get(0).getLabel());
        assertNull(fields.get(1).getLabel());
    }

    @Test
    public void testFormWithEmptyFieldsArrayIsValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/submit"
                    method: "POST"
                    backendUrl: "https://example.com/submit"
                    uiLayout:
                      component: "Form"
                      fields: []
                """);
        BridgeSchemaModel model = parser.parse(file);
        List<BridgeSchemaModel.Field> fields = model.getEndpoints().get(0).getUiLayout().getFields();
        assertNotNull(fields);
        assertTrue(fields.isEmpty());
    }

    // --- T.25: Second field error includes fields[1] in message ---

    @Test
    public void testSecondFieldErrorIncludesIndex(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/submit"
                    method: "POST"
                    backendUrl: "https://example.com/submit"
                    uiLayout:
                      component: "Form"
                      fields:
                        - name: "valid"
                          type: "string"
                        - type: "number"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("fields[1]"));
    }
}
