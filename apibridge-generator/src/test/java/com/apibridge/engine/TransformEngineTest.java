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
        assertTrue(content.contains("reqHeaderAdd"), "ProxyService must accept reqHeaderAdd param");
        assertTrue(content.contains("resFieldRename"), "ProxyService must accept resFieldRename param");
        assertTrue(content.length() > 2000, "ProxyService must have substantial transform method bodies");
    }

    @Test
    public void testSpringBootControllerPassesTransformArgs(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeController.java"));
        assertTrue(content.contains("X-Source"), "controller must contain header add key");
        assertTrue(content.contains("apibridge"), "controller must contain header add value");
        assertTrue(content.contains("X-Internal-Only"), "controller must contain header remove entry");
    }

    @Test
    public void testSpringBootNoTransformCodeWhenFlagOff(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableTransform(false);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String proxy = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertFalse(proxy.contains("reqHeaderAdd"), "no transform param when flag off");
        assertTrue(proxy.length() < 5000, "ProxyService smaller without transform code");
    }

    @Test
    public void testQuarkusProxyServiceContainsTransformMethods(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("reqHeaderAdd"), "ProxyService must accept reqHeaderAdd param");
        assertTrue(content.contains("resFieldRename"), "ProxyService must accept resFieldRename param");
    }

    @Test
    public void testQuarkusResourcePassesTransformArgs(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeResource.java"));
        assertTrue(content.contains("X-Source"), "resource must contain header add key");
        assertTrue(content.contains("apibridge"), "resource must contain header add value");
        assertTrue(content.contains("X-Internal-Only"), "resource must contain header remove entry");
    }

    @Test
    public void testQuarkusNoTransformCodeWhenFlagOff(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableTransform(false);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String proxy = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertFalse(proxy.contains("reqHeaderAdd"), "no transform param when flag off");
        assertTrue(proxy.length() < 5000, "ProxyService smaller without transform code");
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
        assertTrue(content.contains("null"), "no-transform endpoint must have null placeholders");
        assertFalse(content.contains("X-Source"), "no-transform endpoint must not contain transform data");
    }

    @Test
    public void testSpringBootTransformForwardSignatureHasExtraParams(@TempDir Path tempDir) throws Exception {
        engine.generate(createTransformTestModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String proxy = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(proxy.contains("reqHeaderAdd"), "forward must accept reqHeaderAdd param");
        assertTrue(proxy.contains("reqHeaderRemove"), "forward must accept reqHeaderRemove param");
        assertTrue(proxy.contains("resFieldRename"), "forward must accept resFieldRename param");
    }
}
