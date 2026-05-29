package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class DevOpsCartridgeEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testDockerfileCartridgeSpringBoot(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        engine.generate(model, findCartridgeDir("devops/dockerfile"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/Dockerfile"));
        assertTrue(content.contains("FROM maven:3.9-amazoncorretto-21-alpine"), "Backend build stage");
        assertTrue(content.contains("FROM amazoncorretto:21-alpine"), "Runtime stage");
        assertTrue(content.contains("SERVER_PORT=8080"), "Spring Boot port env var");
        assertTrue(content.contains("BACKEND_URL_LOGIN="), "Per-endpoint URL env var");
        assertTrue(content.contains("AUTH_SERVER_URL="), "Bearer token env var");
        assertTrue(content.contains("USER 1001"), "Non-root user");
        assertTrue(content.contains("actuator/health/liveness"), "Spring Boot health check");
    }

    @Test
    public void testDockerfileCartridgeQuarkus(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("quarkus");
        engine.generate(model, findCartridgeDir("devops/dockerfile"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/Dockerfile"));
        assertTrue(content.contains("QUARKUS_HTTP_PORT=8080"), "Quarkus port env var");
        assertTrue(content.contains("q/health/live"), "Quarkus health check");
        assertFalse(content.contains("actuator/health"), "No Spring Boot health check in Quarkus build");
    }

    @Test
    public void testDockerfileCartridgeWithFrontend(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("react");
        engine.generate(model, findCartridgeDir("devops/dockerfile"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/Dockerfile"));
        assertTrue(content.contains("FROM node:20-alpine AS frontend-build"),
                "Frontend build stage must be present when feFlavor is set");
        assertTrue(content.contains("npm run build"), "npm build step");
        assertTrue(content.contains("static"), "Static assets copy");
    }

    @Test
    public void testDockerfileCartridgeNoFrontend(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        engine.generate(model, findCartridgeDir("devops/dockerfile"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/Dockerfile"));
        assertFalse(content.contains("frontend-build"), "No frontend stage when feFlavor is empty");
    }

    @Test
    public void testDockerComposeCartridgeSpringBoot(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("services:"), "Must have services section");
        assertTrue(content.contains("user-auth-service:"), "Service named after id");
        assertTrue(content.contains("SERVER_PORT: \"8080\""), "Spring Boot port");
        assertTrue(content.contains("BACKEND_URL_LOGIN:"), "Per-endpoint URL");
        assertTrue(content.contains("user-auth-service-net"), "Network definition");
        assertTrue(content.contains("cpus: \"1.0\""), "Resource limits");
        assertTrue(content.contains("restart: unless-stopped"), "Restart policy");
    }

    @Test
    public void testDockerComposeCartridgeQuarkus(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("quarkus");
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("QUARKUS_HTTP_PORT: \"8080\""), "Quarkus port");
        assertFalse(content.contains("SERVER_PORT"), "No Spring Boot port in Quarkus build");
    }

    @Test
    public void testDockerComposeCartridgeWithApiKey(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setSecurityLevel("apiKey");
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("API_KEY:"), "API key env var");
        assertFalse(content.contains("AUTH_SERVER_URL"), "No bearer-token env in apiKey build");
    }

    // --- k8s ConfigMap tests ---

    @Test
    public void testK8sConfigmapSpringBoot(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        engine.generate(model, findCartridgeDir("devops/k8s/kubernetes"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/k8s/configmap.yaml"));
        assertTrue(content.contains("SERVER_PORT: \"8080\""), "Spring Boot port var");
        assertFalse(content.contains("QUARKUS_HTTP_PORT"), "No Quarkus var in Spring Boot build");
    }

    @Test
    public void testK8sConfigmapQuarkus(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("quarkus");
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("devops/k8s/kubernetes"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/k8s/configmap.yaml"));
        assertTrue(content.contains("QUARKUS_HTTP_PORT: \"8080\""), "Quarkus port var");
        assertFalse(content.contains("SERVER_PORT"), "No Spring Boot var in Quarkus build");
    }

    @Test
    public void testK8sConfigmapTelemetrySpringBoot(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        engine.generate(model, findCartridgeDir("devops/k8s/kubernetes"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/k8s/configmap.yaml"));
        assertTrue(content.contains("MANAGEMENT_TRACING_ENABLED"), "Spring Boot tracing var");
        assertFalse(content.contains("QUARKUS_OTEL_ENABLED"), "No Quarkus OTel in Spring Boot build");
    }

    @Test
    public void testK8sConfigmapTelemetryQuarkus(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("quarkus");
        engine.generate(model, findCartridgeDir("devops/k8s/kubernetes"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/k8s/configmap.yaml"));
        assertTrue(content.contains("QUARKUS_OTEL_ENABLED"), "Quarkus OTel var");
        assertFalse(content.contains("MANAGEMENT_TRACING_ENABLED"), "No Spring Boot tracing in Quarkus build");
    }

    @Test
    public void testK8sConfigmapAuditLogSpringBoot(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableAuditLog(true);
        engine.generate(model, findCartridgeDir("devops/k8s/kubernetes"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/k8s/configmap.yaml"));
        assertTrue(content.contains("SPRING_DATA_REDIS_URL"), "Spring Redis URI");
        assertTrue(content.contains("SPRING_DATA_MONGODB_URI"), "Spring MongoDB URI");
        assertTrue(content.contains("AUDIT_LOG_TTL_DAYS"), "TTL env var");
        assertFalse(content.contains("QUARKUS_REDIS_HOSTS"), "No Quarkus Redis in Spring Boot build");
    }

    @Test
    public void testK8sConfigmapAuditLogQuarkus(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("quarkus");
        model.getFlags().setEnableAuditLog(true);
        engine.generate(model, findCartridgeDir("devops/k8s/kubernetes"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/k8s/configmap.yaml"));
        assertTrue(content.contains("QUARKUS_REDIS_HOSTS"), "Quarkus Redis URI");
        assertTrue(content.contains("QUARKUS_MONGODB_CONNECTION_STRING"), "Quarkus MongoDB URI");
        assertFalse(content.contains("SPRING_DATA_REDIS_URL"), "No Spring Redis in Quarkus build");
    }

    // --- docker-compose additional coverage ---

    @Test
    public void testDockerComposeWithoutAuditLogHasNoInfraServices(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertFalse(content.contains("image: redis:"), "No Redis service when audit log off");
        assertFalse(content.contains("image: mongo:"), "No MongoDB service when audit log off");
        assertFalse(content.contains("depends_on"), "No depends_on when audit log off");
    }

    @Test
    public void testDockerComposeAuditLogQuarkusUris(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("quarkus");
        model.getFlags().setEnableAuditLog(true);
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("QUARKUS_REDIS_HOSTS"), "Quarkus Redis URI in docker-compose");
        assertTrue(content.contains("QUARKUS_MONGODB_CONNECTION_STRING"), "Quarkus MongoDB URI in docker-compose");
        assertFalse(content.contains("SPRING_DATA_REDIS_URL"), "No Spring Redis in Quarkus build");
    }

    // --- Dockerfile additional coverage ---

    @Test
    public void testDockerfileQuarkusWithFrontendCopiesMetaInfResources(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("quarkus");
        model.getFlags().setFeFlavor("react");
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("devops/dockerfile"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/Dockerfile"));
        assertTrue(content.contains("META-INF/resources"), "Quarkus static resource path");
        assertFalse(content.contains("resources/static"), "No Spring Boot static path in Quarkus build");
    }

    @Test
    public void testDockerfileSpringBootWithFrontendCopiesStaticResources(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("react");
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("devops/dockerfile"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/Dockerfile"));
        assertTrue(content.contains("resources/static"), "Spring Boot static resource path");
        assertFalse(content.contains("META-INF/resources"), "No Quarkus path in Spring Boot build");
    }
}
