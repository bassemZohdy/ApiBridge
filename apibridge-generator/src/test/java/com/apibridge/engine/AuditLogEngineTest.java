package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class AuditLogEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testSpringBootCartridgeWithAuditLog(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableAuditLog(true);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        Path auditDir = tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/audit");
        assertTrue(Files.exists(auditDir), "audit/ package must be generated");
        assertTrue(Files.exists(auditDir.resolve("ProxySendEvent.java")), "ProxySendEvent.java");
        assertTrue(Files.exists(auditDir.resolve("ProxySuccessEvent.java")), "ProxySuccessEvent.java");
        assertTrue(Files.exists(auditDir.resolve("ProxyFailEvent.java")), "ProxyFailEvent.java");
        assertTrue(Files.exists(auditDir.resolve("AuditRecord.java")), "AuditRecord.java");
        assertTrue(Files.exists(auditDir.resolve("RedisAuditPublisher.java")), "RedisAuditPublisher.java");
        assertTrue(Files.exists(auditDir.resolve("AuditStreamConsumer.java")), "AuditStreamConsumer.java");

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("spring-boot-starter-data-redis"), "Redis dep in pom");
        assertTrue(pom.contains("spring-boot-starter-data-mongodb"), "MongoDB dep in pom");

        String proxy = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(proxy.contains("ApplicationEventPublisher"), "Event publisher injected");
        assertTrue(proxy.contains("ProxySendEvent"), "SEND event published");
        assertTrue(proxy.contains("ProxySuccessEvent"), "SUCCESS event published");
        assertTrue(proxy.contains("ProxyFailEvent"), "FAIL event published");

        String app = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/Application.java"));
        assertTrue(app.contains("@EnableAsync"), "@EnableAsync on Application");
    }

    @Test
    public void testSpringBootCartridgeAuditLogDisabledByDefault(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        Path auditDir = tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/audit");
        assertFalse(Files.exists(auditDir.resolve("ProxySendEvent.java")),
                "No audit files when enableAuditLog=false");

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertFalse(pom.contains("spring-boot-starter-data-redis"), "No Redis dep without audit");
    }

    @Test
    public void testQuarkusCartridgeWithAuditLog(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableAuditLog(true);
        model.getFlags().setBackendFlavor("quarkus");
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        Path auditDir = tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/audit");
        assertTrue(Files.exists(auditDir), "audit/ package must be generated");
        assertTrue(Files.exists(auditDir.resolve("RedisAuditPublisher.java")), "RedisAuditPublisher.java");
        assertTrue(Files.exists(auditDir.resolve("AuditStreamConsumer.java")), "AuditStreamConsumer.java");

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("quarkus-redis-client"), "Redis dep in pom");
        assertTrue(pom.contains("quarkus-mongodb-panache"), "MongoDB dep in pom");

        String proxy = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(proxy.contains("fireAsync"), "CDI async events fired");
        assertTrue(proxy.contains("ProxySendEvent"), "SEND event fired");
    }

    @Test
    public void testDockerComposeWithAuditLog(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableAuditLog(true);
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String compose = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(compose.contains("redis:"), "Redis service");
        assertTrue(compose.contains("mongo:"), "MongoDB service");
        assertTrue(compose.contains("SPRING_DATA_REDIS_URL"), "Redis URI env");
        assertTrue(compose.contains("SPRING_DATA_MONGODB_URI"), "MongoDB URI env");
        assertTrue(compose.contains("depends_on"), "App depends on redis and mongo");
    }
}
