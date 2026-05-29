package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class ResponseCacheEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testSpringBootPomContainsCacheDep(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("caffeine"), "Spring Boot pom must include caffeine when cache enabled");
    }

    @Test
    public void testSpringBootPomNoCacheDepWhenDisabled(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(false);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertFalse(pom.contains("caffeine"), "No caffeine dep when cache disabled");
    }

    @Test
    public void testSpringBootProxyServiceContainsCacheCode(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("responseCache"), "ProxyService must have responseCache field");
        assertTrue(content.contains("getIfPresent"), "ProxyService must check cache on GET");
        assertTrue(content.contains("invalidateAll"), "ProxyService must evict cache on non-GET");
    }

    @Test
    public void testQuarkusPomContainsCacheDep(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("caffeine"), "Quarkus pom must include caffeine when cache enabled");
    }

    @Test
    public void testQuarkusProxyServiceContainsCacheCode(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("responseCache"), "Quarkus ProxyService must have responseCache field");
        assertTrue(content.contains("getIfPresent"), "Quarkus ProxyService must check cache on GET");
    }

    @Test
    public void testDockerComposeResponseCacheEnvVars(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("CACHE_TTL_SECONDS"), "docker-compose must have CACHE_TTL_SECONDS");
        assertTrue(content.contains("CACHE_MAX_SIZE"), "docker-compose must have CACHE_MAX_SIZE");
    }
}
