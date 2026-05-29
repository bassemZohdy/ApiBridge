package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class DistributedCacheEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testSpringBootPomContainsRedisDepWhenCacheEnabled(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("spring-boot-starter-data-redis"), "pom must contain redis dep when cache enabled");
    }

    @Test
    public void testSpringBootPomContainsRedisDepWhenAuditEnabled(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableAuditLog(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("spring-boot-starter-data-redis"), "pom must contain redis dep when audit enabled");
    }

    @Test
    public void testSpringBootProxyServiceContainsRedisCacheCode(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("ResponseCache"), "must contain ResponseCache interface");
        assertTrue(content.contains("CaffeineResponseCache"), "must contain CaffeineResponseCache");
        assertTrue(content.contains("CACHE_REDIS_URL"), "must check CACHE_REDIS_URL env var");
    }

    @Test
    public void testSpringBootRedisCacheRequiresAuditForRedisImpl(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableAuditLog(false);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("CaffeineResponseCache"), "must contain CaffeineResponseCache fallback");
        assertFalse(content.contains("RedisResponseCache"), "must not contain RedisResponseCache without audit");
    }

    @Test
    public void testSpringBootRedisCacheWithAudit(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableAuditLog(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("RedisResponseCache"), "must contain RedisResponseCache when audit enabled");
        assertTrue(content.contains("RedisConnectionFactory"), "must contain RedisConnectionFactory");
    }

    @Test
    public void testQuarkusPomContainsRedisDepWhenCacheEnabled(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("quarkus-redis-client"), "pom must contain redis dep when cache enabled");
    }

    @Test
    public void testQuarkusProxyServiceContainsDualCacheCode(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("ResponseCache"), "must contain ResponseCache interface");
        assertTrue(content.contains("CaffeineResponseCache"), "must contain CaffeineResponseCache");
        assertTrue(content.contains("CACHE_REDIS_URL"), "must check CACHE_REDIS_URL env var");
    }

    @Test
    public void testDockerComposeContainsCacheRedisUrl(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("CACHE_REDIS_URL"), "docker-compose must have CACHE_REDIS_URL");
    }

    @Test
    public void testDockerComposeContainsRedisServiceWhenCacheOnly(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        model.getFlags().setEnableAuditLog(false);
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("redis:7-alpine"), "docker-compose must have redis service");
        assertFalse(content.contains("mongo:7"), "docker-compose must not have mongo when audit disabled");
    }

    @Test
    public void testK8sConfigmapContainsCacheRedisUrl(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableResponseCache(true);
        engine.generate(model, findCartridgeDir("devops/k8s/kubernetes"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/k8s/configmap.yaml"));
        assertTrue(content.contains("CACHE_REDIS_URL"), "configmap must have CACHE_REDIS_URL");
    }
}
