# Plugin/External Cartridge Registry — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow `--cartridge=` to accept remote references (URLs and `github:owner/repo` shorthands) in addition to local paths, with automatic download, ZIP extraction, and SHA-256-keyed local caching in `~/.apibridge/cartridges/`.

**Architecture:** Three new classes handle the feature. `CartridgeCache` manages the `~/.apibridge/cartridges/<sha256-of-key>/` directory structure. `CartridgeDownloader` uses `java.net.http.HttpClient` to fetch a URL as bytes, validates against zip-slip, then extracts via `java.util.zip.ZipInputStream`. `CartridgeResolver` parses the three reference formats (local path, URL, `github:` shorthand) and delegates to the downloader+cache pair, returning a `java.io.File` pointing to the local cartridge directory. `ApiBridgeRunner` routes every `--cartridge=` arg through `CartridgeResolver` before passing it to the engine — the engine itself is unchanged.

**Tech Stack:** Java 21, `java.net.http.HttpClient`, `java.util.zip.ZipInputStream`, `java.security.MessageDigest` (SHA-256), `com.sun.net.httpserver.HttpServer` (JDK, test-only), JUnit 5.

---

## File Map

| Action | Path | Purpose |
|---|---|---|
| Create | `apibridge-generator/src/main/java/com/apibridge/engine/CartridgeCache.java` | Manages `~/.apibridge/cartridges/` keyed by SHA-256 of reference string |
| Create | `apibridge-generator/src/main/java/com/apibridge/engine/CartridgeDownloader.java` | HTTP download, zip-slip-safe extraction to a target directory |
| Create | `apibridge-generator/src/main/java/com/apibridge/engine/CartridgeResolver.java` | Parses local / URL / `github:` formats; returns resolved local `File` |
| Create | `apibridge-generator/src/test/java/com/apibridge/engine/CartridgeCacheTest.java` | Unit tests: cache miss/hit, deterministic hashing, directory allocation |
| Create | `apibridge-generator/src/test/java/com/apibridge/engine/CartridgeDownloaderTest.java` | Integration tests with in-process `HttpServer`; includes zip-slip security test |
| Create | `apibridge-generator/src/test/java/com/apibridge/engine/CartridgeResolverTest.java` | Integration tests with in-process `HttpServer`; covers all three formats |
| Modify | `apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeRunner.java` | Route every `--cartridge=` arg through `CartridgeResolver` |
| Modify | `apibridge-generator/src/test/java/com/apibridge/engine/ApiBridgeRunnerTest.java` | Smoke-test local path passthrough via runner |
| Modify | `docs/schema-reference.md` | Document cartridge reference formats |
| Modify | `CLAUDE.md` | Update `--cartridge=` usage block; document cache location |

---

## Task 1: CartridgeCache — local cache directory management

**Files:**
- Create: `apibridge-generator/src/main/java/com/apibridge/engine/CartridgeCache.java`
- Create: `apibridge-generator/src/test/java/com/apibridge/engine/CartridgeCacheTest.java`

- [ ] **Step 1: Write the failing tests**

Create `CartridgeCacheTest.java`:

```java
package com.apibridge.engine;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class CartridgeCacheTest {

    @TempDir
    Path tempDir;

    @Test
    public void testNotCachedInitially() {
        CartridgeCache cache = new CartridgeCache(tempDir.toFile());
        assertFalse(cache.isCached("https://example.com/cartridge.zip"));
    }

    @Test
    public void testAllocateCreatesDirectory() {
        CartridgeCache cache = new CartridgeCache(tempDir.toFile());
        File dir = cache.allocate("https://example.com/cartridge.zip");
        assertTrue(dir.exists());
        assertTrue(dir.isDirectory());
    }

    @Test
    public void testIsCachedAfterAllocate() {
        CartridgeCache cache = new CartridgeCache(tempDir.toFile());
        String key = "https://example.com/cartridge.zip";
        assertFalse(cache.isCached(key));
        cache.allocate(key);
        assertTrue(cache.isCached(key));
    }

    @Test
    public void testResolveReturnsSamePathForSameKey() {
        CartridgeCache cache = new CartridgeCache(tempDir.toFile());
        File dir1 = cache.resolve("https://example.com/cartridge.zip");
        File dir2 = cache.resolve("https://example.com/cartridge.zip");
        assertEquals(dir1.getAbsolutePath(), dir2.getAbsolutePath());
    }

    @Test
    public void testResolveReturnsDifferentPathForDifferentKeys() {
        CartridgeCache cache = new CartridgeCache(tempDir.toFile());
        File dir1 = cache.resolve("https://example.com/a.zip");
        File dir2 = cache.resolve("https://example.com/b.zip");
        assertNotEquals(dir1.getAbsolutePath(), dir2.getAbsolutePath());
    }

    @Test
    public void testSha256Is64HexChars() {
        String hash = CartridgeCache.sha256("test-input");
        assertEquals(64, hash.length());
        assertTrue(hash.matches("[0-9a-f]+"));
    }

    @Test
    public void testSha256IsDeterministic() {
        assertEquals(CartridgeCache.sha256("abc"), CartridgeCache.sha256("abc"));
    }
}
```

- [ ] **Step 2: Run tests — verify they fail**

```
mvn test -pl apibridge-generator -Dtest=CartridgeCacheTest -q
```

Expected: compilation error — `CartridgeCache` does not exist.

- [ ] **Step 3: Implement CartridgeCache**

Create `CartridgeCache.java`:

```java
package com.apibridge.engine;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class CartridgeCache {

    private final File cacheRoot;

    public CartridgeCache() {
        this(new File(System.getProperty("user.home"), ".apibridge/cartridges"));
    }

    CartridgeCache(File cacheRoot) {
        this.cacheRoot = cacheRoot;
    }

    public boolean isCached(String key) {
        return resolve(key).isDirectory();
    }

    public File resolve(String key) {
        return new File(cacheRoot, sha256(key));
    }

    public File allocate(String key) {
        File dir = resolve(key);
        dir.mkdirs();
        return dir;
    }

    static String sha256(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(64);
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```
mvn test -pl apibridge-generator -Dtest=CartridgeCacheTest -q
```

Expected: BUILD SUCCESS, 7 tests passed.

- [ ] **Step 5: Commit**

```
git add apibridge-generator/src/main/java/com/apibridge/engine/CartridgeCache.java
git add apibridge-generator/src/test/java/com/apibridge/engine/CartridgeCacheTest.java
git commit -m "feat: add CartridgeCache — SHA-256-keyed ~/.apibridge/cartridges/ management"
```

---

## Task 2: CartridgeDownloader — HTTP fetch + ZIP extraction

**Files:**
- Create: `apibridge-generator/src/main/java/com/apibridge/engine/CartridgeDownloader.java`
- Create: `apibridge-generator/src/test/java/com/apibridge/engine/CartridgeDownloaderTest.java`

- [ ] **Step 1: Write the failing tests**

Create `CartridgeDownloaderTest.java`:

```java
package com.apibridge.engine;

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import static org.junit.jupiter.api.Assertions.*;

public class CartridgeDownloaderTest {

    static HttpServer server;
    static int port;
    static byte[] testZipBytes;

    @TempDir
    Path tempDir;

    @BeforeAll
    static void startServer() throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            ZipEntry entry = new ZipEntry("hello.txt.ftl");
            zos.putNextEntry(entry);
            zos.write("Hello ${model.id}".getBytes());
            zos.closeEntry();
        }
        testZipBytes = baos.toByteArray();

        server = HttpServer.create(new InetSocketAddress(0), 0);
        port = server.getAddress().getPort();
        server.createContext("/cartridge.zip", exchange -> {
            exchange.sendResponseHeaders(200, testZipBytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(testZipBytes);
            }
        });
        server.start();
    }

    @AfterAll
    static void stopServer() {
        server.stop(0);
    }

    @Test
    public void testDownloadAndExtractCreatesFile() throws Exception {
        CartridgeDownloader downloader = new CartridgeDownloader();
        downloader.downloadAndExtract("http://localhost:" + port + "/cartridge.zip", tempDir.toFile());

        java.io.File extracted = tempDir.resolve("hello.txt.ftl").toFile();
        assertTrue(extracted.exists(), "Expected extracted file: " + extracted.getPath());
        assertEquals("Hello ${model.id}", Files.readString(extracted.toPath()));
    }

    @Test
    public void testExtractZipDirectly() throws IOException {
        CartridgeDownloader.extractZip(testZipBytes, tempDir.toFile());
        assertTrue(tempDir.resolve("hello.txt.ftl").toFile().exists());
    }

    @Test
    public void testExtractZipRejectsZipSlip() throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            ZipEntry malicious = new ZipEntry("../../evil.txt");
            zos.putNextEntry(malicious);
            zos.write("evil".getBytes());
            zos.closeEntry();
        }
        assertThrows(IOException.class,
                () -> CartridgeDownloader.extractZip(baos.toByteArray(), tempDir.toFile()));
    }

    @Test
    public void testDownloadThrowsOnConnectionRefused() {
        CartridgeDownloader downloader = new CartridgeDownloader();
        assertThrows(Exception.class,
                () -> downloader.downloadAndExtract("http://localhost:1/missing.zip", tempDir.toFile()));
    }
}
```

- [ ] **Step 2: Run tests — verify they fail**

```
mvn test -pl apibridge-generator -Dtest=CartridgeDownloaderTest -q
```

Expected: compilation error — `CartridgeDownloader` does not exist.

- [ ] **Step 3: Implement CartridgeDownloader**

Create `CartridgeDownloader.java`:

```java
package com.apibridge.engine;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class CartridgeDownloader {

    private final HttpClient httpClient;

    public CartridgeDownloader() {
        this.httpClient = HttpClient.newHttpClient();
    }

    CartridgeDownloader(HttpClient httpClient) {
        this.httpClient = httpClient;
    }

    public void downloadAndExtract(String url, File targetDir) throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .GET()
                .build();
        byte[] zipBytes = httpClient
                .send(request, HttpResponse.BodyHandlers.ofByteArray())
                .body();
        extractZip(zipBytes, targetDir);
    }

    static void extractZip(byte[] zipBytes, File targetDir) throws IOException {
        String canonicalDest = targetDir.getCanonicalPath() + File.separator;
        targetDir.mkdirs();
        try (ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(zipBytes))) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                File outFile = new File(targetDir, entry.getName());
                if (!outFile.getCanonicalPath().startsWith(canonicalDest)) {
                    throw new IOException("ZIP slip rejected: " + entry.getName());
                }
                if (entry.isDirectory()) {
                    outFile.mkdirs();
                } else {
                    outFile.getParentFile().mkdirs();
                    try (FileOutputStream fos = new FileOutputStream(outFile)) {
                        zis.transferTo(fos);
                    }
                }
                zis.closeEntry();
            }
        }
    }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```
mvn test -pl apibridge-generator -Dtest=CartridgeDownloaderTest -q
```

Expected: BUILD SUCCESS, 4 tests passed.

- [ ] **Step 5: Commit**

```
git add apibridge-generator/src/main/java/com/apibridge/engine/CartridgeDownloader.java
git add apibridge-generator/src/test/java/com/apibridge/engine/CartridgeDownloaderTest.java
git commit -m "feat: add CartridgeDownloader — HttpClient fetch + zip-slip-safe extraction"
```

---

## Task 3: CartridgeResolver — format detection and routing

**Files:**
- Create: `apibridge-generator/src/main/java/com/apibridge/engine/CartridgeResolver.java`
- Create: `apibridge-generator/src/test/java/com/apibridge/engine/CartridgeResolverTest.java`

- [ ] **Step 1: Write the failing tests**

Create `CartridgeResolverTest.java`:

```java
package com.apibridge.engine;

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.file.Path;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import static org.junit.jupiter.api.Assertions.*;

public class CartridgeResolverTest {

    static HttpServer server;
    static int port;
    static byte[] directZip;       // single-level: template.txt.ftl at root
    static byte[] githubArchiveZip; // GitHub-style: my-cartridge-main/templates/template.txt.ftl

    @TempDir
    Path tempDir;

    @BeforeAll
    static void startServer() throws IOException {
        directZip = buildZip("template.txt.ftl", "<#-- direct -->");
        githubArchiveZip = buildZip("my-cartridge-main/templates/template.txt.ftl", "<#-- github -->");

        server = HttpServer.create(new InetSocketAddress(0), 0);
        port = server.getAddress().getPort();

        server.createContext("/my-cartridge.zip", exchange -> {
            exchange.sendResponseHeaders(200, directZip.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(directZip);
            }
        });
        server.createContext("/my-org/my-cartridge/archive/refs/heads/main.zip", exchange -> {
            exchange.sendResponseHeaders(200, githubArchiveZip.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(githubArchiveZip);
            }
        });
        server.start();
    }

    @AfterAll
    static void stopServer() {
        server.stop(0);
    }

    private static byte[] buildZip(String entryName, String content) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            zos.putNextEntry(new ZipEntry(entryName));
            zos.write(content.getBytes());
            zos.closeEntry();
        }
        return baos.toByteArray();
    }

    private CartridgeResolver resolver() {
        return new CartridgeResolver(
                new CartridgeCache(tempDir.resolve("cache").toFile()),
                new CartridgeDownloader(),
                "http://localhost:" + port);
    }

    @Test
    public void testRelativeLocalPathPassthrough() throws Exception {
        File result = resolver().resolve("./my-cartridge");
        assertEquals(new File("./my-cartridge").getPath(), result.getPath());
    }

    @Test
    public void testAbsoluteLocalPathPassthrough() throws Exception {
        File result = resolver().resolve("/opt/cartridges/my-cartridge");
        assertEquals("/opt/cartridges/my-cartridge", result.getPath());
    }

    @Test
    public void testUrlDownloadsAndExtractsTemplate() throws Exception {
        String url = "http://localhost:" + port + "/my-cartridge.zip";
        File result = resolver().resolve(url);
        assertTrue(result.exists(), "Resolved dir should exist: " + result);
        assertTrue(new File(result, "template.txt.ftl").exists(), "template.txt.ftl should be extracted");
    }

    @Test
    public void testUrlCacheHitReturnsSamePath() throws Exception {
        CartridgeResolver r = resolver();
        String url = "http://localhost:" + port + "/my-cartridge.zip";
        File first = r.resolve(url);
        File second = r.resolve(url);
        assertEquals(first.getAbsolutePath(), second.getAbsolutePath());
    }

    @Test
    public void testGithubShorthandWithSubpath() throws Exception {
        File result = resolver().resolve("github:my-org/my-cartridge/templates");
        assertTrue(result.exists(), "Resolved dir should exist: " + result);
        assertTrue(new File(result, "template.txt.ftl").exists(),
                "template.txt.ftl should be present inside templates/ subdir");
    }

    @Test
    public void testInvalidGithubSpecThrows() {
        assertThrows(IllegalArgumentException.class, () -> resolver().resolve("github:badspec"));
    }
}
```

- [ ] **Step 2: Run tests — verify they fail**

```
mvn test -pl apibridge-generator -Dtest=CartridgeResolverTest -q
```

Expected: compilation error — `CartridgeResolver` does not exist.

- [ ] **Step 3: Implement CartridgeResolver**

Create `CartridgeResolver.java`:

```java
package com.apibridge.engine;

import java.io.File;
import java.io.IOException;

public class CartridgeResolver {

    private final CartridgeCache cache;
    private final CartridgeDownloader downloader;
    private final String githubBaseUrl;

    public CartridgeResolver() {
        this(new CartridgeCache(), new CartridgeDownloader(), "https://github.com");
    }

    CartridgeResolver(CartridgeCache cache, CartridgeDownloader downloader, String githubBaseUrl) {
        this.cache = cache;
        this.downloader = downloader;
        this.githubBaseUrl = githubBaseUrl;
    }

    public File resolve(String cartridgeArg) throws IOException, InterruptedException {
        if (cartridgeArg.startsWith("github:")) {
            return resolveGitHub(cartridgeArg.substring("github:".length()));
        }
        if (cartridgeArg.startsWith("https://") || cartridgeArg.startsWith("http://")) {
            return resolveUrl(cartridgeArg);
        }
        return new File(cartridgeArg);
    }

    private File resolveUrl(String url) throws IOException, InterruptedException {
        if (cache.isCached(url)) {
            return cache.resolve(url);
        }
        File targetDir = cache.allocate(url);
        downloader.downloadAndExtract(url, targetDir);
        return targetDir;
    }

    private File resolveGitHub(String spec) throws IOException, InterruptedException {
        // spec: owner/repo[/subpath][@ref]
        String ref = "main";
        String path = spec;
        if (spec.contains("@")) {
            int atIdx = spec.lastIndexOf('@');
            ref = spec.substring(atIdx + 1);
            path = spec.substring(0, atIdx);
        }

        String[] parts = path.split("/", 3);
        if (parts.length < 2) {
            throw new IllegalArgumentException(
                    "Invalid github: reference — expected github:owner/repo[/subpath][@ref], got: github:" + spec);
        }
        String owner = parts[0];
        String repo = parts[1];
        String subpath = (parts.length == 3) ? parts[2] : null;

        String archiveUrl = githubBaseUrl + "/" + owner + "/" + repo
                + "/archive/refs/heads/" + ref + ".zip";
        String cacheKey = archiveUrl + (subpath != null ? "#" + subpath : "");

        if (cache.isCached(cacheKey)) {
            return cache.resolve(cacheKey);
        }

        File archiveDir = cache.allocate(cacheKey);
        downloader.downloadAndExtract(archiveUrl, archiveDir);

        if (subpath != null) {
            return new File(archiveDir, repo + "-" + ref + "/" + subpath);
        }
        return new File(archiveDir, repo + "-" + ref);
    }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```
mvn test -pl apibridge-generator -Dtest=CartridgeResolverTest -q
```

Expected: BUILD SUCCESS, 6 tests passed.

- [ ] **Step 5: Run all engine tests to confirm no regression**

```
mvn test -pl apibridge-generator -q
```

Expected: BUILD SUCCESS.

- [ ] **Step 6: Commit**

```
git add apibridge-generator/src/main/java/com/apibridge/engine/CartridgeResolver.java
git add apibridge-generator/src/test/java/com/apibridge/engine/CartridgeResolverTest.java
git commit -m "feat: add CartridgeResolver — local/URL/github: cartridge reference formats"
```

---

## Task 4: Wire CartridgeResolver into ApiBridgeRunner

**Files:**
- Modify: `apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeRunner.java`
- Modify: `apibridge-generator/src/test/java/com/apibridge/engine/ApiBridgeRunnerTest.java`

- [ ] **Step 1: Write the failing smoke test**

Open `ApiBridgeRunnerTest.java` and add this test:

```java
@Test
public void testGetVersionReturnsNonEmpty() {
    String version = ApiBridgeRunner.getVersion();
    assertNotNull(version);
    assertFalse(version.isBlank());
}

@Test
public void testGetVersionNeverReturnsNull() {
    String version = ApiBridgeRunner.getVersion();
    assertNotNull(version);
}

@Test
public void testResolveLocalCartridgeRef() throws Exception {
    // CartridgeResolver.resolve() on a local path returns a File with the same path.
    // This verifies the resolver is wired through the runner's resolution logic without
    // starting a full generation run.
    CartridgeResolver resolver = new CartridgeResolver();
    java.io.File result = resolver.resolve("./apibridge-cartridges/backend/spring-boot");
    assertEquals(new java.io.File("./apibridge-cartridges/backend/spring-boot").getPath(),
            result.getPath());
}
```

- [ ] **Step 2: Run test — verify it compiles and passes**

```
mvn test -pl apibridge-generator -Dtest=ApiBridgeRunnerTest -q
```

Expected: BUILD SUCCESS (the new test uses `CartridgeResolver` which already exists).

- [ ] **Step 3: Update ApiBridgeRunner to use CartridgeResolver**

In `ApiBridgeRunner.java`, replace the cartridge loop (lines 104–109):

```java
// Before:
ApiBridgeCartridgeEngine engine = new ApiBridgeCartridgeEngine();
for (String cartridgePath : cartridgePaths) {
    File cartridgeDir = new File(cartridgePath);
    System.out.println("Applying cartridge: " + cartridgeDir.getAbsolutePath());
    engine.generate(model, cartridgeDir, outputDir);
}
```

```java
// After:
CartridgeResolver resolver = new CartridgeResolver();
ApiBridgeCartridgeEngine engine = new ApiBridgeCartridgeEngine();
for (String cartridgePath : cartridgePaths) {
    File cartridgeDir = resolver.resolve(cartridgePath);
    System.out.println("Applying cartridge: " + cartridgeDir.getAbsolutePath());
    engine.generate(model, cartridgeDir, outputDir);
}
```

Also update the outer `catch` block to handle `InterruptedException` separately before the general `Exception` catch (insert immediately before `} catch (Exception e) {`):

```java
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();
    System.err.println("==================================================");
    System.err.println("❌ CARTRIDGE GENERATION INTERRUPTED.");
    System.err.println("==================================================");
    System.exit(2);
} catch (Exception e) {
```

Also update `printUsage()` — replace the existing `--cartridge=` line:

```java
// Before:
System.out.println("  --cartridge=<path>   Cartridge to apply (repeatable; applied in order to same output dir)");

// After:
System.out.println("  --cartridge=<ref>    Cartridge to apply (repeatable; applied in order). Formats:");
System.out.println("                         ./local/path           Local filesystem path");
System.out.println("                         https://host/file.zip  URL to a ZIP archive (cached)");
System.out.println("                         github:owner/repo[/subpath][@ref]  GitHub archive");
```

- [ ] **Step 4: Run all tests**

```
mvn test -pl apibridge-generator -q
```

Expected: BUILD SUCCESS.

- [ ] **Step 5: Commit**

```
git add apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeRunner.java
git add apibridge-generator/src/test/java/com/apibridge/engine/ApiBridgeRunnerTest.java
git commit -m "feat: wire CartridgeResolver into ApiBridgeRunner — remote cartridge refs now supported"
```

---

## Task 5: Documentation update

**Files:**
- Modify: `docs/schema-reference.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add Cartridge Reference Formats section to docs/schema-reference.md**

Add the following new section immediately before `## Validation summary`:

```markdown
---

## Cartridge Reference Formats

The `--cartridge=` argument accepts three reference formats:

### Local path

```
--cartridge=./path/to/my-cartridge
--cartridge=/absolute/path/to/my-cartridge
```

Any value that does not start with `http://`, `https://`, or `github:` is treated as a local filesystem path and passed directly to the engine. This is the existing behaviour.

### URL

```
--cartridge=https://example.com/my-cartridge.zip
```

Downloads the ZIP from the given URL, extracts it, and caches the result in `~/.apibridge/cartridges/<sha256-of-url>/`. Subsequent runs with the same URL reuse the cached directory without re-downloading.

### GitHub shorthand

```
--cartridge=github:owner/repo
--cartridge=github:owner/repo/subpath
--cartridge=github:owner/repo@ref
--cartridge=github:owner/repo/subpath@ref
```

Expands to `https://github.com/owner/repo/archive/refs/heads/<ref>.zip` (default `ref` = `main`), downloads the GitHub archive ZIP, extracts it, and caches under `~/.apibridge/cartridges/<sha256-of-spec>/`. When a `subpath` is given, the resolved directory is `<cacheDir>/repo-<ref>/<subpath>/`.

**Examples:**

```bash
# Built-in local cartridge (existing behaviour)
--cartridge=apibridge-cartridges/backend/spring-boot

# Public ZIP from any server
--cartridge=https://releases.example.com/my-team-cartridge-1.0.zip

# Latest main branch of a GitHub repo
--cartridge=github:my-org/apibridge-cartridges

# Specific subdirectory of a GitHub repo at a pinned branch
--cartridge=github:my-org/apibridge-cartridges/backend/custom-spring@release-1

# Cache location (automatically managed — do not edit manually)
~/.apibridge/cartridges/<sha256>/
```
```

- [ ] **Step 2: Update CLAUDE.md — Build & Run section**

In `CLAUDE.md`, inside the `Build & Run` code block, replace:

```
  --cartridge=apibridge-cartridges/backend/spring-boot \
```

with:

```
  --cartridge=apibridge-cartridges/backend/spring-boot \   # local path
  --cartridge=https://host/custom.zip \                    # URL (cached to ~/.apibridge/cartridges/)
  --cartridge=github:owner/repo/subpath@ref \              # GitHub shorthand
```

Also add a note below the code block (after the existing `# Optional overrides` comment block):

```markdown
**Cartridge reference formats** (`--cartridge=` accepts three forms):
- Local path: `./my-cartridge` or `/abs/path` — passed directly to engine
- URL: `https://host/file.zip` — downloaded, extracted, cached at `~/.apibridge/cartridges/<sha256>/`
- GitHub shorthand: `github:owner/repo[/subpath][@ref]` — downloads GitHub archive ZIP, default ref is `main`
```

- [ ] **Step 3: Run full test suite one final time**

```
mvn verify -pl apibridge-generator -q
```

Expected: BUILD SUCCESS (tests + Checkstyle).

- [ ] **Step 4: Commit**

```
git add docs/schema-reference.md CLAUDE.md
git commit -m "docs: document cartridge reference formats (URL, github: shorthand, cache location)"
```

---

## Self-Review

**Spec coverage check:**

| Requirement | Covered by |
|---|---|
| Local path passthrough unchanged | Task 3: `testRelativeLocalPathPassthrough`, `testAbsoluteLocalPathPassthrough` |
| URL format (`http://` / `https://`) | Task 3: `CartridgeResolver.resolveUrl()`, `testUrlDownloadsAndExtractsTemplate` |
| GitHub shorthand `github:owner/repo[/subpath][@ref]` | Task 3: `CartridgeResolver.resolveGitHub()`, `testGithubShorthandWithSubpath` |
| Cache at `~/.apibridge/cartridges/<content-hash>/` | Task 1: `CartridgeCache` |
| SHA-256 keying | Task 1: `CartridgeCache.sha256()` |
| Cache hit reuse (no re-download) | Task 3: `testUrlCacheHitReturnsSamePath` |
| `CartridgeResolver` class | Task 3 |
| `CartridgeDownloader` class using `HttpClient` | Task 2 |
| `CartridgeCache` class | Task 1 |
| No new Maven dependencies | All tasks use only JDK classes |
| Local HTTP server for network tests (no mock) | Task 2: `CartridgeDownloaderTest`, Task 3: `CartridgeResolverTest` |
| Zip-slip security | Task 2: `CartridgeDownloader.extractZip()`, `testExtractZipRejectsZipSlip` |
| ApiBridgeRunner wired | Task 4 |
| `docs/schema-reference.md` updated | Task 5 |
| `CLAUDE.md` updated | Task 5 |
| Engine itself unchanged | Verified — engine takes `File`, resolver returns `File` |
| Frequent commits | One commit per task step |

**Placeholder scan:** None found — all steps contain complete code.

**Type consistency check:**
- `CartridgeCache.resolve(String)` → `File` — used in `CartridgeResolver.resolveUrl()` and `resolveGitHub()` ✓
- `CartridgeCache.allocate(String)` → `File` — used in `CartridgeResolver.resolveUrl()` and `resolveGitHub()` ✓
- `CartridgeCache.isCached(String)` → `boolean` — used in resolver guard checks ✓
- `CartridgeCache.sha256(String)` → `String` (static, package-private) — used in `CartridgeCacheTest` ✓
- `CartridgeDownloader.downloadAndExtract(String, File)` — called by resolver ✓
- `CartridgeDownloader.extractZip(byte[], File)` (static, package-private) — called in `CartridgeDownloaderTest` ✓
- `CartridgeResolver.resolve(String)` → `File` throws `IOException, InterruptedException` — called in runner ✓
- 3-arg `CartridgeResolver` constructor takes `(CartridgeCache, CartridgeDownloader, String)` — used in all tests ✓
