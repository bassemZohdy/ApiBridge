# Helm Chart Cartridge — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `devops/k8s/helm` cartridge that generates a production-ready Helm 3 chart from the schema, complementing the existing raw-Kubernetes (`devops/k8s/kubernetes`) cartridge.

**Architecture:** A new self-contained cartridge directory `apibridge-cartridges/devops/k8s/helm/` that produces a standard Helm chart layout (`Chart.yaml`, `values.yaml`, `templates/*.yaml`). Helm templates use `{{ .Values.x }}` syntax which conflicts with FreeMarker's `${...}` interpolation — all Helm expressions must be wrapped in FreeMarker's `<#noparse>...</#noparse>` blocks OR stored as raw strings using `${r"{{ .Values.x }}"}`. The cartridge follows the exact same composability pattern as the existing `kubernetes` cartridge — just `--cartridge=apibridge-cartridges/devops/k8s/helm` added to the command.

**Tech Stack:** FreeMarker 2.3.32 (already present), Helm 3 chart format, YAML.

---

## File Map

| Action | Path | Purpose |
|---|---|---|
| Create | `apibridge-cartridges/devops/k8s/helm/Chart.yaml.ftl` | Chart metadata |
| Create | `apibridge-cartridges/devops/k8s/helm/values.yaml.ftl` | Default values with env vars, image config |
| Create | `apibridge-cartridges/devops/k8s/helm/templates/deployment.yaml.ftl` | Deployment with `{{ .Values.x }}` references |
| Create | `apibridge-cartridges/devops/k8s/helm/templates/service.yaml.ftl` | ClusterIP service |
| Create | `apibridge-cartridges/devops/k8s/helm/templates/configmap.yaml.ftl` | ENV VARs as ConfigMap |
| Create | `apibridge-cartridges/devops/k8s/helm/templates/ingress.yaml.ftl` | Optional ingress, disabled by default in values |
| Create | `apibridge-cartridges/devops/k8s/helm/templates/_helpers.tpl.ftl` | `app.name` and `app.labels` named templates |
| Create | `apibridge-generator/src/test/java/com/apibridge/engine/HelmCartridgeEngineTest.java` | Unit tests |

---

## Task 1: Chart.yaml + values.yaml

**Files:**
- Create: `apibridge-cartridges/devops/k8s/helm/Chart.yaml.ftl`
- Create: `apibridge-cartridges/devops/k8s/helm/values.yaml.ftl`

- [ ] **Step 1: Create `Chart.yaml.ftl`**

```
apiVersion: v2
name: ${id}
description: ApiBridge-generated Helm chart for ${id}
type: application
version: 0.1.0
appVersion: "1.0.0"
```

(No FreeMarker/Helm expression conflict here — just simple FreeMarker interpolation.)

- [ ] **Step 2: Create `values.yaml.ftl`**

```
replicaCount: 1

image:
  repository: ${id}
  pullPolicy: IfNotPresent
  tag: "latest"

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: false
  className: ""
  annotations: {}
  host: ${id}.local
  path: /
  pathType: Prefix
  tls: []

resources: {}

env:
  MOCK_MODE: "false"
  DEBUG_MODE: "false"
<#if (flags.enableRateLimiter)!false>
  RATE_LIMIT_PERMITS: "10"
  RATE_LIMIT_PERIOD_SECONDS: "1"
  RATE_LIMIT_TIMEOUT_MILLIS: "5000"
</#if>
<#if (flags.enableResponseCache)!false>
  CACHE_TTL_SECONDS: "60"
  CACHE_MAX_SIZE: "1000"
  CACHE_REDIS_URL: ""
</#if>
<#if (flags.enableCircuitBreaker)!false>
  CB_FAILURE_RATE_THRESHOLD: "50"
  CB_SLIDING_WINDOW_SIZE: "10"
  CB_WAIT_DURATION_SECONDS: "30"
  CB_RETRY_MAX_ATTEMPTS: "3"
  CB_RETRY_WAIT_MS: "500"
</#if>
<#if (flags.enableHealthCheck)!false>
  HEALTH_CHECK_INTERVAL_SECONDS: "30"
  HEALTH_CHECK_TIMEOUT_MS: "3000"
</#if>
<#if (flags.enableSearch)!false>
  SEARCH_PARAM: "q"
</#if>
```

---

## Task 2: Helm helpers template

The `_helpers.tpl` file provides named templates used in Deployment, Service, etc. Because `{{` is Helm syntax and `${` is FreeMarker syntax, use `${r"{{ ... }}"}` pattern for Helm expressions inside FreeMarker templates.

**Files:**
- Create: `apibridge-cartridges/devops/k8s/helm/templates/_helpers.tpl.ftl`

- [ ] **Step 1: Create `_helpers.tpl.ftl`**

Note: In FreeMarker, `${r"..."}` treats the content as a raw string, passing it through untouched. Every Helm `{{ }}` expression MUST use this pattern.

```
${r"{{/*"}
Expand the name of the chart.
${r"*/}}"}
${r"{{-"} define "${id}.name" ${r"-}}"}
${r"{{-"} .Chart.Name | trunc 63 | trimSuffix "-" ${r"}}"}
${r"{{-"} end ${r"}}"}

${r"{{/*"}
Common labels
${r"*/}}"}
${r"{{-"} define "${id}.labels" ${r"-}}"}
helm.sh/chart: ${r"{{- include"} "${id}.name" . ${r"}} -"} ${r"{{ .Chart.Version | replace"} "+" "_" ${r"}}"}
app.kubernetes.io/name: ${r"{{-"} include "${id}.name" . ${r"}}"}
app.kubernetes.io/instance: ${r"{{ .Release.Name }}"}
app.kubernetes.io/managed-by: ${r"{{ .Release.Service }}"}
${r"{{-"} end ${r"}}"}
```

---

## Task 3: Deployment template

**Files:**
- Create: `apibridge-cartridges/devops/k8s/helm/templates/deployment.yaml.ftl`

- [ ] **Step 1: Create `deployment.yaml.ftl`**

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${r"{{ include"} "${id}.name" . ${r"}}"}
  labels:
    ${r"{{- include"} "${id}.labels" . | nindent 4 ${r"}}"}
spec:
  replicas: ${r"{{ .Values.replicaCount }}"}
  selector:
    matchLabels:
      app.kubernetes.io/name: ${r"{{ include"} "${id}.name" . ${r"}}"}
      app.kubernetes.io/instance: ${r"{{ .Release.Name }}"}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ${r"{{ include"} "${id}.name" . ${r"}}"}
        app.kubernetes.io/instance: ${r"{{ .Release.Name }}"}
    spec:
      containers:
        - name: ${id}
          image: ${r"{{ .Values.image.repository }}:{{ .Values.image.tag }}"}
          imagePullPolicy: ${r"{{ .Values.image.pullPolicy }}"}
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          envFrom:
            - configMapRef:
                name: ${r"{{ include"} "${id}.name" . ${r"}} -config"}
          resources:
            ${r"{{- toYaml .Values.resources | nindent 12 }}"}
```

---

## Task 4: Service template

**Files:**
- Create: `apibridge-cartridges/devops/k8s/helm/templates/service.yaml.ftl`

- [ ] **Step 1: Create `service.yaml.ftl`**

```
apiVersion: v1
kind: Service
metadata:
  name: ${r"{{ include"} "${id}.name" . ${r"}}"}
  labels:
    ${r"{{- include"} "${id}.labels" . | nindent 4 ${r"}}"}
spec:
  type: ${r"{{ .Values.service.type }}"}
  ports:
    - port: ${r"{{ .Values.service.port }}"}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: ${r"{{ include"} "${id}.name" . ${r"}}"}
    app.kubernetes.io/instance: ${r"{{ .Release.Name }}"}
```

---

## Task 5: ConfigMap template

**Files:**
- Create: `apibridge-cartridges/devops/k8s/helm/templates/configmap.yaml.ftl`

- [ ] **Step 1: Create `configmap.yaml.ftl`**

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${r"{{ include"} "${id}.name" . ${r"}} -config"}
  labels:
    ${r"{{- include"} "${id}.labels" . | nindent 4 ${r"}}"}
data:
  ${r"{{- toYaml .Values.env | nindent 2 }}"}
```

---

## Task 6: Ingress template

**Files:**
- Create: `apibridge-cartridges/devops/k8s/helm/templates/ingress.yaml.ftl`

- [ ] **Step 1: Create `ingress.yaml.ftl`**

```
${r"{{- if .Values.ingress.enabled }}"}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${r"{{ include"} "${id}.name" . ${r"}}"}
  labels:
    ${r"{{- include"} "${id}.labels" . | nindent 4 ${r"}}"}
  ${r"{{- with .Values.ingress.annotations }}"}
  annotations:
    ${r"{{- toYaml . | nindent 4 }}"}
  ${r"{{- end }}"}
spec:
  ${r"{{- if .Values.ingress.className }}"}
  ingressClassName: ${r"{{ .Values.ingress.className }}"}
  ${r"{{- end }}"}
  rules:
    - host: ${r"{{ .Values.ingress.host }}"}
      http:
        paths:
          - path: ${r"{{ .Values.ingress.path }}"}
            pathType: ${r"{{ .Values.ingress.pathType }}"}
            backend:
              service:
                name: ${r"{{ include"} "${id}.name" . ${r"}}"}
                port:
                  number: ${r"{{ .Values.service.port }}"}
  ${r"{{- if .Values.ingress.tls }}"}
  tls:
    ${r"{{- toYaml .Values.ingress.tls | nindent 4 }}"}
  ${r"{{- end }}"}
${r"{{- end }}"}
```

---

## Task 7: Unit tests

**Files:**
- Create: `apibridge-generator/src/test/java/com/apibridge/engine/HelmCartridgeEngineTest.java`

- [ ] **Step 1: Write the tests**

```java
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

        String chart = Files.readString(tempDir.resolve("out/Chart.yaml"));
        assertTrue(chart.contains("apiVersion: v2"), "Chart.yaml must declare apiVersion v2");
        assertTrue(chart.contains("name: user-auth-service"), "Chart.yaml name must match schema id");
    }

    @Test
    public void testValuesYamlGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String values = Files.readString(tempDir.resolve("out/values.yaml"));
        assertTrue(values.contains("replicaCount"), "values.yaml must define replicaCount");
        assertTrue(values.contains("image:"), "values.yaml must have image section");
        assertTrue(values.contains("service:"), "values.yaml must have service section");
    }

    @Test
    public void testDeploymentTemplateGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String deployment = Files.readString(tempDir.resolve("out/templates/deployment.yaml"));
        assertTrue(deployment.contains("kind: Deployment"), "must be Deployment kind");
        assertTrue(deployment.contains("containerPort: 8080"), "must expose port 8080");
        assertTrue(deployment.contains("configMapRef"), "must use configMapRef for env");
    }

    @Test
    public void testServiceTemplateGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String service = Files.readString(tempDir.resolve("out/templates/service.yaml"));
        assertTrue(service.contains("kind: Service"), "must be Service kind");
        assertTrue(service.contains("ClusterIP"), "default service type must be ClusterIP");
    }

    @Test
    public void testConfigMapTemplateGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String configmap = Files.readString(tempDir.resolve("out/templates/configmap.yaml"));
        assertTrue(configmap.contains("kind: ConfigMap"), "must be ConfigMap kind");
        assertTrue(configmap.contains("toYaml .Values.env"), "must reference env values");
    }

    @Test
    public void testIngressTemplateGenerated(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String ingress = Files.readString(tempDir.resolve("out/templates/ingress.yaml"));
        assertTrue(ingress.contains("kind: Ingress"), "must be Ingress kind");
        assertTrue(ingress.contains("ingress.enabled"), "ingress must be gated on values flag");
    }

    @Test
    public void testValuesContainsRateLimiterEnvWhenFlagOn(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableRateLimiter(true);
        engine.generate(model, findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String values = Files.readString(tempDir.resolve("out/values.yaml"));
        assertTrue(values.contains("RATE_LIMIT_PERMITS"), "values.yaml must include RATE_LIMIT_PERMITS when flag on");
    }

    @Test
    public void testHelmExpressionsNotMangled(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("devops/k8s/helm"), tempDir.resolve("out").toFile());

        String deployment = Files.readString(tempDir.resolve("out/templates/deployment.yaml"));
        assertTrue(deployment.contains("{{ .Values.replicaCount }}"),
                "Helm expressions must survive FreeMarker processing intact");
        assertTrue(deployment.contains("{{ .Release.Name }}"),
                "Helm Release.Name must survive FreeMarker processing intact");
    }
}
```

- [ ] **Step 2: Run tests (expect failures — templates not yet written correctly)**

```bash
mvn test -pl apibridge-generator -Dtest=HelmCartridgeEngineTest --no-transfer-progress
```

Fix any issues with `${r"..."}` escaping in the templates until all 8 tests PASS.

- [ ] **Step 3: Run full suite**

```bash
mvn verify --no-transfer-progress
```

Expected: BUILD SUCCESS.

- [ ] **Step 4: Commit**

```bash
git add apibridge-cartridges/devops/k8s/helm/
git add apibridge-generator/src/test/java/com/apibridge/engine/HelmCartridgeEngineTest.java
git commit -m "feat: add devops/k8s/helm cartridge — Helm 3 chart with values, deployment, service, configmap, ingress"
```

---

## Task 8: Update schema-reference.md

**Files:**
- Modify: `docs/schema-reference.md`

- [ ] **Step 1: Add Helm to the cartridge inventory section**

In the cartridge inventory section, add:

```markdown
- `devops/k8s/helm` — Full Helm 3 chart under `helm/` (`Chart.yaml`, `values.yaml`, `templates/deployment.yaml`, `templates/service.yaml`, `templates/configmap.yaml`, `templates/ingress.yaml`). All ENV VARs exposed in `values.yaml`; ConfigMap populated from `values.env`.
```

- [ ] **Step 2: Commit**

```bash
git add docs/schema-reference.md
git commit -m "docs: add devops/k8s/helm cartridge to schema reference"
```

---

## Self-Review

**Spec coverage:**
- `Chart.yaml` ✓ (Task 1)
- `values.yaml` with ENV VARs per flags ✓ (Task 1)
- `templates/deployment.yaml` ✓ (Task 3)
- `templates/service.yaml` ✓ (Task 4)
- `templates/configmap.yaml` ✓ (Task 5)
- `templates/ingress.yaml` (disabled by default) ✓ (Task 6)
- `_helpers.tpl` named templates ✓ (Task 2)
- Helm `{{ }}` expressions survive FreeMarker ✓ (`${r"..."}` pattern, verified by test in Task 7)
- 8 unit tests ✓ (Task 7)
- Docs ✓ (Task 8)

**No placeholders found.**

**Type consistency:** All tests use `createTestModel()` from `ApiBridgeCartridgeEngineTestBase` — consistent with all other engine tests in the project.
