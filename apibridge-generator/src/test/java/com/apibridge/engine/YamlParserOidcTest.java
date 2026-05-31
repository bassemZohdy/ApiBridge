package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserOidcTest extends YamlParserTestBase {

    @Test
    public void testEnableOidcDefaultsFalse(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags: {}
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertFalse(model.getFlags().isEnableOidc(), "enableOidc must default to false");
    }

    @Test
    public void testEnableOidcWithIssuerUriParsesCorrectly(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableOidc: true
                  oidcIssuerUri: "https://keycloak.example.com/realms/myrealm"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertTrue(model.getFlags().isEnableOidc());
        assertEquals("https://keycloak.example.com/realms/myrealm", model.getFlags().getOidcIssuerUri());
    }

    @Test
    public void testEnableOidcWithoutIssuerUriThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableOidc: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("oidcIssuerUri"),
                "Error must mention oidcIssuerUri");
    }

    @Test
    public void testEnableOidcWithBlankIssuerUriThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableOidc: true
                  oidcIssuerUri: "   "
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("oidcIssuerUri"));
    }
}
