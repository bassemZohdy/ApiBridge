# ApiBridge — Backlog

Pre-P7 code review findings. All actionable items resolved. Architecture notes deferred to Phase 7.

---

## Checklist

| ID | Description | Status |
|----|-------------|--------|
| B1 | React List `${id}` unescaped in backtick string | [x] Done |
| V1 | `searchMode` accepted without `enableSearch: true` | [x] Done |
| V2 | `searchMode` validation order swap | [x] Done |
| V3 | `transforms` internals not validated | [x] Done |
| V4 | No warning when `transforms` present but `enableTransform: false` | [x] Done |
| V5 | `pagination` param names not validated for blank | [x] Done |
| Q1 | `buildContext()` top-level boolean flags — investigated, NOT dead code | [x] Done |
| Q2 | FreeMarker `Configuration` rebuilt on every `generate()` | [x] Done |
| Q3 | `ApiBridgeRunner` re-validation guard manual extension | [x] Done |
| V6 | Transform `add` map allows blank header values | [x] Done |
| V7 | Transform warning fires twice per endpoint | [x] Done |
| Q4 | `applyOverride` first param `flags` unused | [x] Done |
| Q5 | `pagination != null` guard is dead code — documented invariant | [x] Done |
| Q6 | `flags??` dead outer guard in templates | [x] Done |
| Q7 | `configurationCache` never gets cache hit — made static | [x] Done |
| A1 | `YamlParser.validate()` flat method — extract helpers | [ ] Deferred to P7 |
| A2 | `searchMode`/`enableSearch` cross-field pattern precedent | [ ] Deferred to P7 |

---

## Architecture notes for P7

### A1 — `YamlParser.validate()` is a flat method with no sub-structure
Adding P7 flags will push it past 150+ lines. The four enum-valued flags (`backendFlavor`, `feFlavor`, `deployTarget`, `securityLevel`) each have identical copy-paste `!equals()` chains. Consider extracting a private `validateEnum(String field, String value, String... allowed)` helper before adding new flag blocks.

### A2 — `searchMode`/`enableSearch` cross-field pattern is a precedent for P7
P7 features like OIDC (`enableOidc` + per-endpoint `oidcConfig`) will likely have the same cross-field dependency pattern. The V1 fix established the convention: check prerequisite flag first, then per-endpoint config.
