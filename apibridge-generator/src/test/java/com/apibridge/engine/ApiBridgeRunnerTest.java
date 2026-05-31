package com.apibridge.engine;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import com.apibridge.engine.model.BridgeSchemaModel;

import static org.junit.jupiter.api.Assertions.*;

public class ApiBridgeRunnerTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testGetVersionReturnsNonEmpty() {
        String version = ApiBridgeRunner.getVersion();
        assertNotNull(version);
        assertFalse(version.isBlank());
    }

    @Test
    public void testMultiSchemaMergesEndpoints(@TempDir Path tempDir) throws Exception {
        Path schemaA = tempDir.resolve("a.yaml");
        Files.writeString(schemaA, """
                id: svc-a
                basePath: /api
                endpoints:
                  - path: /users
                    method: GET
                    backendUrl: https://users.example.com/users
                flags:
                  backendFlavor: spring-boot
                """);

        Path schemaB = tempDir.resolve("b.yaml");
        Files.writeString(schemaB, """
                id: svc-b
                basePath: /api
                endpoints:
                  - path: /orders
                    method: GET
                    backendUrl: https://orders.example.com/orders
                """);

        Path cartridgeDir = findCartridgeDir("backend/spring-boot").toPath();
        Path outDir = tempDir.resolve("out");

        YamlParser parser = new YamlParser();
        SchemaComposer composer = new SchemaComposer();
        BridgeSchemaModel merged = composer.compose(List.of(
                parser.parse(schemaA.toFile()),
                parser.parse(schemaB.toFile())
        ));

        assertEquals("svc-a", merged.getId());
        assertEquals(2, merged.getEndpoints().size());
        new ApiBridgeCartridgeEngine().generate(
                merged,
                cartridgeDir.toFile(),
                outDir.toFile()
        );
        assertTrue(Files.exists(outDir.resolve("backend/src/main/java/com/apibridge/generated/BridgeController.java")));
    }

    @Test
    public void testResolveLocalCartridgeRef() throws Exception {
        CartridgeResolver resolver = new CartridgeResolver();
        java.io.File result = resolver.resolve("./apibridge-cartridges/backend/spring-boot");
        assertEquals(new java.io.File("./apibridge-cartridges/backend/spring-boot").getPath(),
                result.getPath());
    }
}
