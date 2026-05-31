package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class OpenApiEngineTest extends ApiBridgeCartridgeEngineTestBase {

    private BridgeSchemaModel createOpenApiModel() {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableOpenApi(true);
        return model;
    }

    @Test
    public void testOpenApiYamlGeneratedWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOpenApiModel(), findCartridgeDir("docs/openapi"), tempDir.resolve("out").toFile());

        assertTrue(Files.exists(tempDir.resolve("out/openapi.yaml")),
                "openapi.yaml must be generated when enableOpenApi is true");
    }

    @Test
    public void testOpenApiYamlValidStructure(@TempDir Path tempDir) throws Exception {
        engine.generate(createOpenApiModel(), findCartridgeDir("docs/openapi"), tempDir.resolve("out").toFile());

        String yaml = Files.readString(tempDir.resolve("out/openapi.yaml"));
        assertTrue(yaml.contains("openapi: \"3.0.3\""), "Must declare OpenAPI 3.0.3");
        assertTrue(yaml.contains("info:"), "Must have info section");
        assertTrue(yaml.contains("title: \"user-auth-service\""), "Title must match service id");
        assertTrue(yaml.contains("paths:"), "Must have paths section");
    }

    @Test
    public void testOpenApiYamlContainsAllEndpoints(@TempDir Path tempDir) throws Exception {
        engine.generate(createOpenApiModel(), findCartridgeDir("docs/openapi"), tempDir.resolve("out").toFile());

        String yaml = Files.readString(tempDir.resolve("out/openapi.yaml"));
        assertTrue(yaml.contains("post:"), "Must contain POST method from test model");
        assertTrue(yaml.contains("/login"), "Must contain /login path");
        assertTrue(yaml.contains("operationId:"), "Must have operationId for each endpoint");
    }

    @Test
    public void testOpenApiYamlNotGeneratedWhenFlagOff(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        engine.generate(model, findCartridgeDir("docs/openapi"), tempDir.resolve("out").toFile());

        assertFalse(Files.exists(tempDir.resolve("out/openapi.yaml")),
                "openapi.yaml must NOT be generated when enableOpenApi is false");
    }

    @Test
    public void testSpringBootPomHasSpringdocWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOpenApiModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("springdoc-openapi-starter-webmvc-ui"),
                "Spring Boot pom must include springdoc dep when enableOpenApi is true");
    }

    @Test
    public void testQuarkusPomHasSmallryeWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOpenApiModel(), findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("quarkus-smallrye-openapi"),
                "Quarkus pom must include smallrye dep when enableOpenApi is true");
    }

    @Test
    public void testOpenApiMultiEndpointPaths(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createMultiEndpointModel();
        model.getFlags().setEnableOpenApi(true);
        engine.generate(model, findCartridgeDir("docs/openapi"), tempDir.resolve("out").toFile());

        String yaml = Files.readString(tempDir.resolve("out/openapi.yaml"));
        assertTrue(yaml.contains("/submissions"), "Must contain /submissions path");
        assertTrue(yaml.contains("/submissions/{id}"), "Must contain /submissions/{id} path");
        assertTrue(yaml.contains("get:"), "Must contain GET method");
        assertTrue(yaml.contains("post:"), "Must contain POST method");
        assertTrue(yaml.contains("put:"), "Must contain PUT method");
        assertTrue(yaml.contains("delete:"), "Must contain DELETE method");
    }

    @Test
    public void testOpenApiSecuritySchemeWhenBearerToken(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createOpenApiModel();
        model.getFlags().setSecurityLevel("bearer-token");
        engine.generate(model, findCartridgeDir("docs/openapi"), tempDir.resolve("out").toFile());

        String yaml = Files.readString(tempDir.resolve("out/openapi.yaml"));
        assertTrue(yaml.contains("securitySchemes:"), "Must define security schemes");
        assertTrue(yaml.contains("bearerAuth:"), "Must define bearerAuth scheme");
    }

    @Test
    public void testOpenApiOutputIsValidYaml(@TempDir Path tempDir) throws Exception {
        engine.generate(createOpenApiModel(), findCartridgeDir("docs/openapi"), tempDir.resolve("out").toFile());

        String yaml = Files.readString(tempDir.resolve("out/openapi.yaml"));
        assertTrue(yaml.contains("openapi:"), "Must start with openapi version");
        assertTrue(yaml.contains("paths:"), "Must have paths section");
        assertFalse(yaml.contains("${"), "Must not contain unresolved FreeMarker expressions");
    }
}
