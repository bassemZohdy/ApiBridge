package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserTransformsTest extends YamlParserTestBase {

    @Test
    public void testTransformsParsesCorrectly(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    transforms:
                      requestHeaders:
                        add: { "X-Source": "apibridge" }
                        remove: [ "X-Internal" ]
                        rename: { "X-Old": "X-New" }
                      responseFields:
                        rename: { "upstream_name": "displayName" }
                        remove: [ "secret" ]
                """);
        BridgeSchemaModel model = parser.parse(file);
        BridgeSchemaModel.Transforms t = model.getEndpoints().get(0).getTransforms();
        assertNotNull(t);
        assertEquals("apibridge", t.getRequestHeaders().getAdd().get("X-Source"));
        assertTrue(t.getRequestHeaders().getRemove().contains("X-Internal"));
        assertEquals("X-New", t.getRequestHeaders().getRename().get("X-Old"));
        assertEquals("displayName", t.getResponseFields().getRename().get("upstream_name"));
        assertTrue(t.getResponseFields().getRemove().contains("secret"));
    }

    @Test
    public void testTransformsWithoutFlagStillValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    transforms:
                      requestHeaders:
                        add: { "X-Source": "test" }
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model.getEndpoints().get(0).getTransforms());
    }

    // --- T.27: Transforms responseHeaders + requestFields sub-objects ---

    @Test
    public void testTransformsAllSubObjects(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    transforms:
                      requestHeaders:
                        add: { "X-Source": "apibridge" }
                      responseHeaders:
                        remove: [ "X-Internal" ]
                      requestFields:
                        rename: { "our_field": "upstream_field" }
                      responseFields:
                        remove: [ "secret" ]
                """);
        BridgeSchemaModel model = parser.parse(file);
        BridgeSchemaModel.Transforms t = model.getEndpoints().get(0).getTransforms();
        assertNotNull(t);
        assertEquals("apibridge", t.getRequestHeaders().getAdd().get("X-Source"));
        assertTrue(t.getResponseHeaders().getRemove().contains("X-Internal"));
        assertEquals("upstream_field", t.getRequestFields().getRename().get("our_field"));
        assertTrue(t.getResponseFields().getRemove().contains("secret"));
    }

    // --- T.28: Empty transforms: {} → null sub-objects ---

    @Test
    public void testEmptyTransformsObject(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    transforms: {}
                """);
        BridgeSchemaModel model = parser.parse(file);
        BridgeSchemaModel.Transforms t = model.getEndpoints().get(0).getTransforms();
        assertNotNull(t);
        assertNull(t.getRequestHeaders());
        assertNull(t.getResponseHeaders());
        assertNull(t.getRequestFields());
        assertNull(t.getResponseFields());
    }

    // --- T.29: Transforms absent → null on endpoint ---

    @Test
    public void testTransformsAbsentIsNull(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNull(model.getEndpoints().get(0).getTransforms());
    }
}
