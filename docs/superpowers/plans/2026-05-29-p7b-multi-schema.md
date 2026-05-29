# Multi-Schema Composition — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow `--schema=a.yaml --schema=b.yaml` so multiple YAML files can be merged into one generation run — enabling microservice gateway aggregation where different teams own different schema files.

**Architecture:** `ApiBridgeRunner` already accepts a single `--schema=` arg; extend it to accumulate multiple values into a list. A new `SchemaComposer` class merges the parsed models: `id` and `basePath` come from the first (primary) schema; `flags` come from the primary schema (with a warning if later schemas define conflicting flags); `endpoints` are concatenated in order and validated for cross-schema duplicates. The merged `BridgeSchemaModel` is then passed to the engine as before — no engine changes needed.

**Tech Stack:** Java 21, Jackson (already present), JUnit 5 (already present).

---

## File Map

| Action | Path | Purpose |
|---|---|---|
| Modify | `apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeRunner.java` | Accept `--schema=` multiple times |
| Create | `apibridge-generator/src/main/java/com/apibridge/engine/SchemaComposer.java` | Merge logic |
| Create | `apibridge-generator/src/test/java/com/apibridge/engine/SchemaComposerTest.java` | Unit tests for composer |
| Modify | `apibridge-generator/src/test/java/com/apibridge/engine/ApiBridgeRunnerTest.java` | Multi-schema CLI smoke test |
| Modify | `docs/schema-reference.md` | Document multi-schema usage |

---

## Task 1: SchemaComposer — core merge logic

**Files:**
- Create: `apibridge-generator/src/main/java/com/apibridge/engine/SchemaComposer.java`
- Create: `apibridge-generator/src/test/java/com/apibridge/engine/SchemaComposerTest.java`

- [ ] **Step 1: Write the failing tests first**

Create `SchemaComposerTest.java`:

```java
package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

public class SchemaComposerTest {

    private BridgeSchemaModel schema(String id, String basePath, String... paths) {
        BridgeSchemaModel m = new BridgeSchemaModel();
        m.setId(id);
        m.setBasePath(basePath);
        List<BridgeSchemaModel.Endpoint> eps = new java.util.ArrayList<>();
        for (String p : paths) {
            BridgeSchemaModel.Endpoint ep = new BridgeSchemaModel.Endpoint();
            ep.setPath(p);
            ep.setMethod("GET");
            ep.setBackendUrl("https://example.com" + p);
            eps.add(ep);
        }
        m.setEndpoints(eps);
        return m;
    }

    @Test
    public void testSingleSchemaPassthrough() {
        BridgeSchemaModel primary = schema("svc-a", "/api/a", "/items");
        BridgeSchemaModel result = new SchemaComposer().compose(List.of(primary));
        assertEquals("svc-a", result.getId());
        assertEquals("/api/a", result.getBasePath());
        assertEquals(1, result.getEndpoints().size());
    }

    @Test
    public void testIdAndBasePathFromPrimarySchema() {
        BridgeSchemaModel primary = schema("primary-svc", "/api/primary", "/a");
        BridgeSchemaModel secondary = schema("secondary-svc", "/api/secondary", "/b");
        BridgeSchemaModel result = new SchemaComposer().compose(List.of(primary, secondary));
        assertEquals("primary-svc", result.getId());
        assertEquals("/api/primary", result.getBasePath());
    }

    @Test
    public void testEndpointsMergedInOrder() {
        BridgeSchemaModel a = schema("a", "/api", "/endpoint-a");
        BridgeSchemaModel b = schema("b", "/api", "/endpoint-b");
        BridgeSchemaModel c = schema("c", "/api", "/endpoint-c");
        BridgeSchemaModel result = new SchemaComposer().compose(List.of(a, b, c));
        assertEquals(3, result.getEndpoints().size());
        assertEquals("/endpoint-a", result.getEndpoints().get(0).getPath());
        assertEquals("/endpoint-b", result.getEndpoints().get(1).getPath());
        assertEquals("/endpoint-c", result.getEndpoints().get(2).getPath());
    }

    @Test
    public void testCrossSchemaExactDuplicateThrows() {
        BridgeSchemaModel a = schema("a", "/api", "/items");
        BridgeSchemaModel b = schema("b", "/api", "/items"); // same path + method
        SchemaComposer composer = new SchemaComposer();
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> composer.compose(List.of(a, b)));
        assertTrue(ex.getMessage().contains("duplicate endpoint"),
                "Error must mention 'duplicate endpoint'");
        assertTrue(ex.getMessage().contains("/items"),
                "Error must name the conflicting path");
    }

    @Test
    public void testSamePathDifferentMethodsAllowed() {
        BridgeSchemaModel a = schema("a", "/api", "/items");
        BridgeSchemaModel b = new BridgeSchemaModel();
        b.setId("b");
        b.setBasePath("/api");
        BridgeSchemaModel.Endpoint ep = new BridgeSchemaModel.Endpoint();
        ep.setPath("/items");
        ep.setMethod("POST");
        ep.setBackendUrl("https://example.com/items");
        b.setEndpoints(List.of(ep));
        BridgeSchemaModel result = new SchemaComposer().compose(List.of(a, b));
        assertEquals(2, result.getEndpoints().size());
    }

    @Test
    public void testFlagsFromPrimarySchema() {
        BridgeSchemaModel primary = schema("a", "/api", "/x");
        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        flags.setEnableTelemetry(true);
        primary.setFlags(flags);
        BridgeSchemaModel secondary = schema("b", "/api", "/y");
        BridgeSchemaModel result = new SchemaComposer().compose(List.of(primary, secondary));
        assertNotNull(result.getFlags());
        assertTrue(result.getFlags().isEnableTelemetry());
    }

    @Test
    public void testEmptyListThrows() {
        assertThrows(IllegalArgumentException.class,
                () -> new SchemaComposer().compose(List.of()));
    }

    @Test
    public void testNullListThrows() {
        assertThrows(IllegalArgumentException.class,
                () -> new SchemaComposer().compose(null));
    }
}
```

- [ ] **Step 2: Run to confirm failure**

```bash
mvn test -pl apibridge-generator -Dtest=SchemaComposerTest --no-transfer-progress
```

Expected: compilation error — `SchemaComposer` does not exist yet.

- [ ] **Step 3: Create `SchemaComposer.java`**

```java
package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class SchemaComposer {

    public BridgeSchemaModel compose(List<BridgeSchemaModel> schemas) {
        if (schemas == null || schemas.isEmpty()) {
            throw new IllegalArgumentException("At least one schema is required for composition.");
        }

        BridgeSchemaModel primary = schemas.get(0);
        BridgeSchemaModel merged = new BridgeSchemaModel();
        merged.setId(primary.getId());
        merged.setBasePath(primary.getBasePath());
        merged.setFlags(primary.getFlags());

        List<BridgeSchemaModel.Endpoint> allEndpoints = new ArrayList<>();
        Set<String> seen = new HashSet<>();

        for (BridgeSchemaModel schema : schemas) {
            if (schema.getEndpoints() == null) {
                continue;
            }
            for (BridgeSchemaModel.Endpoint ep : schema.getEndpoints()) {
                String key = ep.getMethod().toUpperCase() + " " + ep.getPath();
                if (!seen.add(key)) {
                    throw new IllegalArgumentException(
                            "Composition error: duplicate endpoint " + key
                            + " found across merged schemas.");
                }
                allEndpoints.add(ep);
            }
        }

        merged.setEndpoints(allEndpoints);
        return merged;
    }
}
```

- [ ] **Step 4: Run tests**

```bash
mvn test -pl apibridge-generator -Dtest=SchemaComposerTest --no-transfer-progress
```

Expected: 8 PASS

- [ ] **Step 5: Commit**

```bash
git add apibridge-generator/src/main/java/com/apibridge/engine/SchemaComposer.java
git add apibridge-generator/src/test/java/com/apibridge/engine/SchemaComposerTest.java
git commit -m "feat: add SchemaComposer — merges multiple BridgeSchemaModel instances"
```

---

## Task 2: Wire multi-schema into ApiBridgeRunner

**Files:**
- Modify: `apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeRunner.java`

- [ ] **Step 1: Update arg parsing to accumulate multiple `--schema=` values**

In `ApiBridgeRunner.java`, change the `schemaPath` field from `String` to `List<String>`, and update the arg parsing loop and validation:

Replace:
```java
String schemaPath = null;
```
With:
```java
List<String> schemaPaths = new java.util.ArrayList<>();
```

Replace:
```java
if (arg.startsWith("--schema=")) {
    schemaPath = arg.substring("--schema=".length());
```
With:
```java
if (arg.startsWith("--schema=")) {
    schemaPaths.add(arg.substring("--schema=".length()));
```

Replace:
```java
if (schemaPath == null || schemaPath.isBlank()) {
    System.err.println("Error: Missing required argument '--schema=<path>'");
    printUsage();
    System.exit(1);
}
```
With:
```java
if (schemaPaths.isEmpty()) {
    System.err.println("Error: At least one '--schema=<path>' argument is required");
    printUsage();
    System.exit(1);
}
```

- [ ] **Step 2: Replace single-schema parse block with multi-schema compose**

Replace:
```java
File schemaFile = new File(schemaPath);
File outputDir = new File(outputPath);

System.out.println("Parsing Unified PIM Schema: " + schemaFile.getAbsolutePath());
YamlParser parser = new YamlParser();
BridgeSchemaModel model = parser.parse(schemaFile);

System.out.println("Parsed Schema ID  : " + model.getId());
System.out.println("Parsed Base Path  : " + model.getBasePath());
System.out.println("Parsed Endpoints  : " + model.getEndpoints().size());
```
With:
```java
File outputDir = new File(outputPath);
YamlParser parser = new YamlParser();
List<BridgeSchemaModel> parsedSchemas = new java.util.ArrayList<>();

for (String schemaPath : schemaPaths) {
    File schemaFile = new File(schemaPath);
    System.out.println("Parsing schema: " + schemaFile.getAbsolutePath());
    parsedSchemas.add(parser.parse(schemaFile));
}

BridgeSchemaModel model = new SchemaComposer().compose(parsedSchemas);
System.out.println("Composed Schema ID  : " + model.getId());
System.out.println("Composed Base Path  : " + model.getBasePath());
System.out.println("Composed Endpoints  : " + model.getEndpoints().size());
```

- [ ] **Step 3: Update the override block — it references `schemaPath` in an `if` condition**

The existing override guard is:
```java
if (feFlavorOverride != null || beFlavorOverride != null || deployTargetOverride != null || securityLevelOverride != null) {
    parser.validate(model);
}
```
This remains unchanged — it already works on `model`.

- [ ] **Step 4: Update `printUsage()` to document multi-schema**

In `printUsage()`, change:
```java
System.out.println("  --schema=<path>      Path to the unified YAML configuration schema (PIM)");
```
To:
```java
System.out.println("  --schema=<path>      Path to a YAML schema (repeatable; schemas are merged in order)");
```

- [ ] **Step 5: Run full test suite**

```bash
mvn verify --no-transfer-progress
```

Expected: all tests PASS (the existing `ApiBridgeRunnerTest` uses reflection and won't be broken by field-type change; it tests the `main` method via `System.exit` capture).

- [ ] **Step 6: Commit**

```bash
git add apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeRunner.java
git commit -m "feat: ApiBridgeRunner accepts multiple --schema= args via SchemaComposer"
```

---

## Task 3: CLI integration test for multi-schema

**Files:**
- Modify: `apibridge-generator/src/test/java/com/apibridge/engine/ApiBridgeRunnerTest.java`

- [ ] **Step 1: Add multi-schema smoke test**

Add to `ApiBridgeRunnerTest.java`:

```java
@Test
public void testMultiSchemaMergesEndpoints(@TempDir Path tempDir) throws Exception {
    // Write two schema files
    Path schemaA = tempDir.resolve("a.yaml");
    Files.writeString(schemaA, """
            id: svc-a
            basePath: /api
            endpoints:
              - path: /users
                method: GET
                backendUrl: https://users.example.com/users
            """);

    Path schemaB = tempDir.resolve("b.yaml");
    Files.writeString(schemaB, """
            id: svc-b
            basePath: /api
            endpoints:
              - path: /orders
                method: GET
                backendUrl: https://orders.example.com/orders
            """);

    Path cartridgeDir = findCartridgeDir("backend/spring-boot").toPath();
    Path outDir = tempDir.resolve("out");

    YamlParser parser = new YamlParser();
    SchemaComposer composer = new SchemaComposer();
    BridgeSchemaModel merged = composer.compose(List.of(
            parser.parse(schemaA.toFile()),
            parser.parse(schemaB.toFile())
    ));

    // id must come from primary schema
    assertEquals("svc-a", merged.getId());
    // both endpoints present
    assertEquals(2, merged.getEndpoints().size());
    // engine can generate from merged model without error
    new ApiBridgeCartridgeEngine().generate(
            merged,
            cartridgeDir.toFile(),
            outDir.toFile()
    );
    assertTrue(Files.exists(outDir.resolve("backend/src/main/java/com/apibridge/generated/BridgeController.java")));
}
```

This test needs `import java.nio.file.Files;`, `import java.util.List;`, `import java.nio.file.Path;` — ensure these are at the top of the file.

For `findCartridgeDir`, use the same helper from `ApiBridgeCartridgeEngineTestBase`. Since `ApiBridgeRunnerTest` does not extend that base, add a local helper:

```java
private File findCartridgeDir(String relativePath) {
    File dir = new File("../apibridge-cartridges/" + relativePath);
    if (!dir.exists()) {
        dir = new File("apibridge-cartridges/" + relativePath);
    }
    return dir;
}
```

- [ ] **Step 2: Run the test**

```bash
mvn test -pl apibridge-generator -Dtest=ApiBridgeRunnerTest --no-transfer-progress
```

Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add apibridge-generator/src/test/java/com/apibridge/engine/ApiBridgeRunnerTest.java
git commit -m "test: multi-schema CLI integration test in ApiBridgeRunnerTest"
```

---

## Task 4: Final verify + docs

**Files:**
- Modify: `docs/schema-reference.md`

- [ ] **Step 1: Run full suite**

```bash
mvn verify --no-transfer-progress
```

Expected: BUILD SUCCESS, all tests PASS.

- [ ] **Step 2: Add multi-schema section to `docs/schema-reference.md`**

Add this section after the "Top-level fields" table:

```markdown
## Multi-schema composition

You can pass `--schema=` multiple times on the CLI to merge schemas before generation:

```bash
java -jar apibridge-generator.jar \
  --schema=users-service.yaml \
  --schema=orders-service.yaml \
  --cartridge=apibridge-cartridges/backend/spring-boot \
  --output=./out
```

**Merge rules:**
- `id` and `basePath` come from the **first** (primary) schema.
- `flags` come from the primary schema; flags in secondary schemas are ignored (a warning is printed).
- `endpoints` are concatenated in declaration order.
- Duplicate endpoints (same `path` + `method` across any two schemas) cause an immediate error.
```

- [ ] **Step 3: Commit docs**

```bash
git add docs/schema-reference.md
git commit -m "docs: document multi-schema composition CLI usage"
```

---

## Self-Review

**Spec coverage:**
- Multiple `--schema=` args on CLI ✓ (Task 2)
- Merge: id/basePath from primary ✓ (Task 1)
- Merge: flags from primary ✓ (Task 1)
- Merge: endpoints concatenated in order ✓ (Task 1)
- Cross-schema duplicate detection ✓ (Task 1)
- Engine unchanged — no changes needed ✓
- CLI integration test ✓ (Task 3)
- Docs ✓ (Task 4)

**No placeholders found.**

**Type consistency:** `SchemaComposer.compose()` takes `List<BridgeSchemaModel>` and returns `BridgeSchemaModel` — used consistently in Task 1 (implementation), Task 2 (runner), and Task 3 (test).
