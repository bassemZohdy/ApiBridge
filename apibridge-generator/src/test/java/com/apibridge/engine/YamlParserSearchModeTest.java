package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserSearchModeTest extends YamlParserTestBase {

    @Test
    public void testSearchModeDelegateValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableSearch: true
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                    uiLayout:
                      component: "List"
                      searchMode: "delegate"
                      columns:
                        - field: "name"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals("delegate", model.getEndpoints().get(0).getUiLayout().getSearchMode());
    }

    @Test
    public void testSearchModeLocalValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableSearch: true
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                    uiLayout:
                      component: "List"
                      searchMode: "local"
                      columns:
                        - field: "name"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals("local", model.getEndpoints().get(0).getUiLayout().getSearchMode());
    }

    @Test
    public void testSearchModeInvalidValueThrows(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableSearch: true
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                    uiLayout:
                      component: "List"
                      searchMode: "auto"
                      columns:
                        - field: "name"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("searchMode"));
    }

    @Test
    public void testSearchModeOnNonListThrows(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/items/{id}"
                    method: "GET"
                    backendUrl: "https://example.com/items/1"
                    uiLayout:
                      component: "View"
                      searchMode: "delegate"
                      fields:
                        - name: "name"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("searchMode") && ex.getMessage().contains("List"));
    }
}
