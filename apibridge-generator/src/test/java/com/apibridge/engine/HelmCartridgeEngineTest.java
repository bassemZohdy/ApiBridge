package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class HelmCartridgeEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testHelmChartYamlGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String chart = Files.readString(tempDir.resolve("out/k8s/Chart.yaml"));
        assertTrue(chart.contains("apiVersion: v2"), "Chart.yaml must declare apiVersion v2");
        assertTrue(chart.contains("name: user-auth-service"), "Chart.yaml name must match schema id");
    }

    @Test
    public void testValuesYamlGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String values = Files.readString(tempDir.resolve("out/k8s/values.yaml"));
        assertTrue(values.contains("replicaCount"), "values.yaml must define replicaCount");
        assertTrue(values.contains("image:"), "values.yaml must have image section");
        assertTrue(values.contains("service:"), "values.yaml must have service section");
    }

    @Test
    public void testDeploymentTemplateGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String deployment = Files.readString(tempDir.resolve("out/k8s/templates/deployment.yaml"));
        assertTrue(deployment.contains("kind: Deployment"), "must be Deployment kind");
        assertTrue(deployment.contains("containerPort: 8080"), "must expose port 8080");
        assertTrue(deployment.contains("configMapRef"), "must use configMapRef for env");
    }

    @Test
    public void testServiceTemplateGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String service = Files.readString(tempDir.resolve("out/k8s/templates/service.yaml"));
        assertTrue(service.contains("kind: Service"), "must be Service kind");
        assertTrue(service.contains(".Values.service.type"), "must reference service type from values");
    }

    @Test
    public void testConfigMapTemplateGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String configmap = Files.readString(tempDir.resolve("out/k8s/templates/configmap.yaml"));
        assertTrue(configmap.contains("kind: ConfigMap"), "must be ConfigMap kind");
        assertTrue(configmap.contains("toYaml .Values.env"), "must reference env values");
    }

    @Test
    public void testIngressTemplateGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String ingress = Files.readString(tempDir.resolve("out/k8s/templates/ingress.yaml"));
        assertTrue(ingress.contains("kind: Ingress"), "must be Ingress kind");
        assertTrue(ingress.contains("ingress.enabled"), "ingress must be gated on values flag");
    }

    @Test
    public void testValuesContainsRateLimiterEnvWhenFlagOn(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableRateLimiter(true);
        engine.generate(model, findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String values = Files.readString(tempDir.resolve("out/k8s/values.yaml"));
        assertTrue(values.contains("RATE_LIMIT_PERMITS"), "values.yaml must include RATE_LIMIT_PERMITS when flag on");
    }

    @Test
    public void testHelmExpressionsNotMangled(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String deployment = Files.readString(tempDir.resolve("out/k8s/templates/deployment.yaml"));
        assertTrue(deployment.contains("{{ .Values.replicaCount }}"),
                "Helm expressions must survive FreeMarker processing intact");
        assertTrue(deployment.contains("{{ .Release.Name }}"),
                "Helm Release.Name must survive FreeMarker processing intact");
    }
}
