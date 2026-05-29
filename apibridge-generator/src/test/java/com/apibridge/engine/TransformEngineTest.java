package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class TransformEngineTest extends ApiBridgeCartridgeEngineTestBase {

    private BridgeSchemaModel createTransformTestModel() {
        BridgeSchemaModel model = new BridgeSchemaModel();
        model.setId("transform-service");
        model.setBasePath("/api/transform");

        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        flags.setEnableTelemetry(false);
        flags.setEnableTransform(true);
        model.setFlags(flags);

        BridgeSchemaModel.Endpoint endpoint = new BridgeSchemaModel.Endpoint();
        endpoint.setPath("/data");
        endpoint.setMethod("GET");
        endpoint.setBackendUrl("https://upstream.example.com/data");

        BridgeSchemaModel.Transforms transforms = new BridgeSchemaModel.Transforms();
        BridgeSchemaModel.HeaderTransform reqHeaders = new BridgeSchemaModel.HeaderTransform();
        reqHeaders.setAdd(java.util.Map.of("X-Source", "apibridge"));
        reqHeaders.setRemove(java.util.List.of("X-Internal-Only"));
        reqHeaders.setRename(java.util.Map.of("X-Old-Name", "X-New-Name"));
        transforms.setRequestHeaders(reqHeaders);

        BridgeSchemaModel.FieldTransform resFields = new BridgeSchemaModel.FieldTransform();
        resFields.setRename(java.util.Map.of("upstream_name", "displayName"));
        resFields.setRemove(java.util.List.of("secret_field"));
        transforms.setResponseFields(resFields);

        endpoint.setTransforms(transforms);
        model.setEndpoints(java.util.List.of(endpoint));
        return model;
    }

    @Test
    public void testSpringBootProxyServiceContainsTransformMethods(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("applyHeaderTransforms"), "must contain applyHeaderTransforms");
        assertTrue(content.contains("applyFieldTransforms"), "must contain applyFieldTransforms");
        assertTrue(content.contains("ObjectMapper"), "must use ObjectMapper for field transforms");
    }

    @Test
    public void testSpringBootControllerPassesTransformArgs(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeController.java"));
        assertTrue(content.contains("Map.of("), "controller must pass transform maps");
        assertTrue(content.contains("List.of("), "controller must pass transform lists");
        assertTrue(content.contains("X-Source"), "controller must contain header add data");
    }

    @Test
    public void testSpringBootNoTransformCodeWhenFlagOff(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableTransform(false);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String proxy = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertFalse(proxy.contains("applyHeaderTransforms"), "no transform code when flag off");
        assertFalse(proxy.contains("ObjectMapper"), "no ObjectMapper when flag off");
    }

    @Test
    public void testQuarkusProxyServiceContainsTransformMethods(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("applyHeaderTransforms"), "must contain applyHeaderTransforms");
        assertTrue(content.contains("applyFieldTransforms"), "must contain applyFieldTransforms");
    }

    @Test
    public void testQuarkusResourcePassesTransformArgs(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeResource.java"));
        assertTrue(content.contains("Map.of("), "resource must pass transform maps");
        assertTrue(content.contains("List.of("), "resource must pass transform lists");
        assertTrue(content.contains("X-Source"), "resource must contain header add data");
    }

    @Test
    public void testQuarkusNoTransformCodeWhenFlagOff(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableTransform(false);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String proxy = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertFalse(proxy.contains("applyHeaderTransforms"), "no transform code when flag off");
        assertFalse(proxy.contains("ObjectMapper"), "no ObjectMapper when flag off");
    }

    @Test
    public void testSpringBootTransformHeaderAddGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeController.java"));
        assertTrue(content.contains("X-Source"), "controller must contain X-Source from header add");
        assertTrue(content.contains("apibridge"), "controller must contain apibridge value from header add");
    }

    @Test
    public void testQuarkusTransformHeaderAddGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeResource.java"));
        assertTrue(content.contains("X-Source"), "resource must contain X-Source from header add");
        assertTrue(content.contains("apibridge"), "resource must contain apibridge value from header add");
    }

    @Test
    public void testSpringBootEndpointWithoutTransformsPassesNull(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableTransform(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeController.java"));
        String normalized = content.replace("\n", "").replace("\r", "");
        assertTrue(normalized.contains("null, null, null"), "no-transform endpoint must pass null args");
        assertFalse(content.contains("Map.of"), "no-transform endpoint must not have Map.of");
    }

    @Test
    public void testSpringBootTransformForwardSignatureHasExtraParams(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String proxy = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(proxy.contains("Map<String, String> reqHeaderAdd"), "forward must accept reqHeaderAdd");
        assertTrue(proxy.contains("List<String> reqHeaderRemove"), "forward must accept reqHeaderRemove");
        assertTrue(proxy.contains("Map<String, String> resFieldRename"), "forward must accept resFieldRename");
    }
}
