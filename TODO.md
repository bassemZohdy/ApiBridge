# ApiBridge — Backlog

Pre-P7 code review findings. Ranked by severity. Fix before starting Phase 7 work.

---

## Bugs (must fix)

### B1 — React List: `${id}` unescaped in backtick string
**File:** `apibridge-cartridges/frontend/react/src/ApiBridgeList.tsx.ftl` ~line 149  
**Severity:** High — affects every React-generated List view  
FreeMarker substitutes the schema `id` field at generation time. Generated code becomes `onNavigate(\`view/customer-onboarding-bridge\`)` for every row, so every row click navigates to the same wrong URL. Vue and Angular both correctly use `${r"${id}"}`.  
**Fix:** Change `` `view/${id}` `` → `` `view/${r"${id}"}` ``

---

## Missing validation (should fix before P7 adds more flags)

### V1 — `searchMode` accepted without `enableSearch: true`
**File:** `apibridge-generator/src/main/java/com/apibridge/engine/YamlParser.java` ~line 162  
Schema reference documents that `searchMode` "requires `flags.enableSearch: true`", but `validate()` never checks this constraint. A schema with `searchMode: delegate` and `enableSearch` absent/false passes validation and reaches the engine, generating search UI with the feature disabled — inconsistent state with no error.  
**Fix:** Add guard: if `searchMode` is set and `flags.enableSearch != true`, throw `IllegalArgumentException`.

### V2 — `searchMode` validation order: value check fires before List-only check
**File:** `apibridge-generator/src/main/java/com/apibridge/engine/YamlParser.java` ~line 162–170  
An endpoint with `component: Form` and `searchMode: badValue` gets "Must be 'delegate' or 'local'" instead of "searchMode is only valid on List components." The List-only guard at line 167 is never reached for invalid values.  
**Fix:** Swap order — check `component == list` first, then validate the value.

### V3 — `transforms` internals not validated
**File:** `apibridge-generator/src/main/java/com/apibridge/engine/YamlParser.java`  
`validate()` never touches `endpoint.getTransforms()`. When `enableTransform: true`, a `rename` map with blank/null keys or a `remove` list with blank entries passes validation and is written verbatim into the generated `ProxyService`, producing silent no-ops or NPEs at code-generation time.  
**Fix:** When `enableTransform: true`, validate that rename map keys and values are non-blank, and remove list entries are non-blank.

### V4 — No warning when `transforms` present but `enableTransform: false`
**File:** `apibridge-generator/src/main/java/com/apibridge/engine/YamlParser.java`  
Schema reference states: "transforms is ignored at runtime if `flags.enableTransform` is not true (warning logged, not an error)." No warning code exists anywhere in `validate()` for this case. A developer who accidentally omits the flag loses all transforms silently.  
**Fix:** Add `System.err.println("Warning: transforms defined on endpoint '...' but flags.enableTransform is not true — transforms will be ignored.")` in the parser.

### V5 — `pagination` param names not validated for blank
**File:** `apibridge-generator/src/main/java/com/apibridge/engine/YamlParser.java` ~line 88–93  
Pagination validation only checks `defaultPageSize > 0`. The string fields `pageParam`, `sizeParam`, `sortParam`, and `directionParam` are never checked for blank. Setting `pageParam: ''` passes validation and generates query strings like `?=1&=20`.  
**Fix:** Add non-blank validation for all four pagination param name fields when their object is present.

---

## Code quality (clean up before P7 adds more flags)

### Q1 — `buildContext()` adds dead top-level boolean flags
**File:** `apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeCartridgeEngine.java` ~line 116–122  
`buildContext()` puts `enableRateLimiter`, `enableTransform`, `enableHealthCheck`, `enableSearch`, `enableOfflineSupport`, and `enableOpenApi` as top-level context keys, but all templates uniformly access flags via `flags.enableX` — none use the top-level form. Phase 5 flags (`enableCircuitBreaker`, `enableResponseCache`, `enableAuditLog`, `enableTelemetry`) are not unpacked at all, making the inconsistency visible. These 6 `context.put()` calls are dead code.  
**Fix:** Remove the 6 redundant `context.put()` lines. All templates already access `flags.*`. Add a note in `buildContext()` that templates access flags via the `flags` object.

### Q2 — FreeMarker `Configuration` rebuilt on every `generate()` call
**File:** `apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeCartridgeEngine.java` ~line 45  
`new Configuration(Configuration.VERSION_2_3_32)` is constructed inside `generate()`. When N `--cartridge=` args are passed, N separate `Configuration` objects are created and discarded, each with their own fresh template cache. This wastes allocation and initialization work on every multi-cartridge run.  
**Fix:** Extract `Configuration` construction into a private `buildConfiguration(File cartridgeDir)` factory method; consider caching by cartridge dir path as a `Map<String, Configuration>` field on the engine instance.

### Q3 — `ApiBridgeRunner` re-validation guard must be manually extended per new CLI override
**File:** `apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeRunner.java` ~line 100  
`parser.validate(model)` is only called when the condition `feFlavorOverride != null || beFlavorOverride != null || deployTargetOverride != null || securityLevelOverride != null` is true. Any P7 CLI override flag (e.g. `--api-version=`) that is not added to this condition will mutate the model and then silently skip re-validation, passing an invalid model to the engine with no error.  
**Fix:** Either always call `validate()` after applying overrides (unconditionally), or extract the override-then-validate block into a helper so it's impossible to add an override without triggering validation.

---

## Architecture notes for P7

### A1 — `YamlParser.validate()` is a flat 130-line method with no sub-structure
Adding P7 flags will push it past 150+ lines. The four enum-valued flags (`backendFlavor`, `feFlavor`, `deployTarget`, `securityLevel`) each have identical copy-paste `!equals()` chains that require finding the right block when adding a new allowed value. Consider extracting a private `validateEnum(String field, String value, String... allowed)` helper before adding new flag blocks.

### A2 — `searchMode`/`enableSearch` cross-field pattern is a precedent for P7
P7 features like OIDC (`enableOidc` + per-endpoint `oidcConfig`) will likely have the same cross-field dependency pattern. Establish the convention in the existing `searchMode` fix (V1 above) so P7 validators follow the same structure.
