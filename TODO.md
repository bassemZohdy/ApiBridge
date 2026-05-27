# ApiBridge — Backlog

Previous items (GAP-6, GAP-7, CLOUD-1–CLOUD-5, C1–C4, H1–H6, M5, M6) are complete.
See CHANGELOG.md for details.

---

## Phase 2 — Remove Dead Flags + Address Stubs/Gaps

- [ ] **M1/M2** Remove `navigationMode` and `uiPattern` from entire codebase
  - `apibridge-generator/src/main/java/com/apibridge/engine/model/BridgeSchemaModel.java`
  - `apibridge-generator/src/main/java/com/apibridge/engine/YamlParser.java`
  - All 3 frontend App/Form/List/View templates (remove conditionals, remove web-component branches)
  - Both backend BridgeConfig controllers/resources
  - `apibridge-cartridges/devops/k8s/kubernetes/configmap.yaml.ftl`
  - `apibridge-generator/src/test/java/com/apibridge/engine/YamlParserTest.java`
  - `apibridge-generator/src/test/java/com/apibridge/engine/ApiBridgeCartridgeEngineTest.java`
  - `sample-schema.yaml`
  - `e2e-tests/json-server-test/schema-spring-react.yaml`
  - `e2e-tests/json-server-test/schema-quarkus-vue.yaml`

- [ ] **M3** Enrich `/api/bridge-config` endpoint with `securityLevel`, `basePath`, `enableTelemetry`
  - `apibridge-cartridges/backend/spring-boot/src/main/java/com/apibridge/generated/BridgeConfigController.java.ftl`
  - `apibridge-cartridges/backend/quarkus/src/main/java/com/apibridge/generated/BridgeConfigResource.java.ftl`

- [ ] **M4** Align CORS configuration (add `allowCredentials`, `maxAge`)
  - `apibridge-cartridges/backend/spring-boot/src/main/java/com/apibridge/generated/CorsConfig.java.ftl`
  - `apibridge-cartridges/backend/quarkus/src/main/resources/application.properties.ftl`

---

## Phase 3 — Testing & Quality

- [ ] **L1** Add Kubernetes manifest validation E2E suite
- [ ] **L2** Create richer multi-method test schema for E2E
- [ ] **L3** Fix CI wiring (json-server-test job, contract symmetry run order)
- [ ] **L4** Add frontend production build test (at least React)
- [ ] **L5** Fix Vue E2E to use `vue-tsc`
- [ ] **L6** Fix `run-all-e2e.sh` step numbering
- [ ] **L7** Add basic form field validation from schema metadata
