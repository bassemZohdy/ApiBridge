# ApiBridge — Active Work

## P7a — CLI Packaging & Distribution

Ship ApiBridge as a properly distributed tool — versioned GitHub Releases with a fat JAR, Docker image with bundled cartridges, and shell wrappers.

**Reference plan:** `docs/superpowers/plans/2026-05-29-p7a-cli-packaging.md`

---

### Checklist

| ID | Task | Files | Status |
|----|------|-------|--------|
| P7a-1 | CI workflow — **SKIP** (`.github/workflows/ci.yml` already exists, 337 lines, 4 jobs) | — | [x] Done (pre-existing) |
| P7a-2 | Version smoke test — assert `ApiBridgeRunner.getVersion()` never returns null/blank | `ApiBridgeRunnerTest.java` | [ ] Pending |
| P7a-3 | Shell wrapper scripts — `bin/apibridge` (Unix) + `bin/apibridge.bat` (Windows) | `bin/apibridge`, `bin/apibridge.bat` | [ ] Pending |
| P7a-4 | Generator Docker image — multi-stage `Dockerfile.generator` (JAR + cartridges) | `Dockerfile.generator` | [ ] Pending |
| P7a-5 | Release workflow — `.github/workflows/release.yml` (v* tag → GitHub Release + GHCR Docker) | `.github/workflows/release.yml` | [ ] Pending |
| P7a-6 | Wire VERSION build-arg into `Dockerfile.generator` for versioned releases | `Dockerfile.generator` | [ ] Pending |
| P7a-7 | Update README with installation instructions (JAR, Docker, source) | `README.md` | [ ] Pending |

---

### Detailed Steps

#### P7a-2 — Version smoke test

1. Read `ApiBridgeRunner.java` to find the `getVersion()` method
2. Read `ApiBridgeRunnerTest.java` to understand existing test structure
3. Add test: `getVersion()` returns non-null, non-blank string (contract: never null, never blank)
4. Run `mvn test -pl apibridge-generator -Dtest=ApiBridgeRunnerTest`
5. Commit

**Verify:** `mvn verify` passes

---

#### P7a-3 — Shell wrapper scripts

1. Create `bin/apibridge`:
   - Bash script, `#!/usr/bin/env bash`
   - Resolves JAR path relative to script dir
   - Error if JAR not found
   - `exec java -jar "$JAR" "$@"`
2. Create `bin/apibridge.bat`:
   - Windows batch equivalent
   - Same JAR resolution logic
3. Smoke-test: `mvn package -DskipTests` then `./bin/apibridge --version`
4. Commit

**Verify:** Wrapper prints version string

---

#### P7a-4 — Generator Docker image

1. Create `Dockerfile.generator`:
   - Stage 1: `eclipse-temurin:21-jdk-alpine` — build fat JAR
   - Stage 2: `eclipse-temurin:21-jre-alpine` — minimal runtime
   - Copy fat JAR + all `apibridge-cartridges/` into image
   - `ENTRYPOINT ["java", "-jar", "/apibridge/apibridge-generator.jar"]`
2. Build locally: `docker build -f Dockerfile.generator -t apibridge-local:test .`
3. Test: `docker run --rm apibridge-local:test --version`
4. Commit

**Verify:** Docker container prints version string

---

#### P7a-5 — Release workflow

1. Create `.github/workflows/release.yml`:
   - Trigger: push tags `v*`
   - Permissions: `contents: write`, `packages: write`
   - Job `release`:
     - Extract version from tag
     - `mvn versions:set` + `mvn package`
     - Package release archive (JAR + bin wrappers + README + LICENSE)
     - `softprops/action-gh-release@v2` creates GitHub Release with ZIP
   - Job `docker`:
     - Build + push to GHCR with version + latest tags
2. Commit

**Verify:** YAML syntax valid (no engine changes)

---

#### P7a-6 — Wire VERSION build-arg into Dockerfile.generator

1. Update `Dockerfile.generator`:
   - Add `ARG VERSION=0.1.0-SNAPSHOT` at both stages
   - Use `mvn versions:set` in build stage
   - Use wildcard `apibridge-generator-*.jar` for COPY
   - Add version label
2. Test: `docker build --build-arg VERSION=0.2.0-test -t apibridge-argtest .`
3. Commit

**Verify:** `docker run --rm apibridge-argtest --version` shows `0.2.0-test`

---

#### P7a-7 — Update README with installation instructions

1. Add Installation section to `README.md`:
   - Option A: Download JAR from GitHub Releases
   - Option B: Docker pull from GHCR
   - Option C: Build from source
2. Commit

**Verify:** `mvn verify` passes (docs-only change)

---

### Prerequisites & Notes

- **No engine/parser changes** — purely infrastructure
- CI workflow (`ci.yml`) already exists — Task 1 skipped
- `getVersion()` reads `Implementation-Version` from JAR manifest (set by `maven-shade-plugin`)
- Release workflow uses `YOUR_ORG` placeholder — replace with actual GitHub org (`bassemZohdy`)
- Docker image is for the **generator tool**, not generated projects

---

## Completed (Pre-P7 Code Review)

| ID | Description | Status |
|----|-------------|--------|
| B1 | React List `${id}` unescaped in backtick string | [x] Done |
| V1 | `searchMode` accepted without `enableSearch: true` | [x] Done |
| V2 | `searchMode` validation order swap | [x] Done |
| V3 | `transforms` internals not validated | [x] Done |
| V4 | No warning when `transforms` present but `enableTransform: false` | [x] Done |
| V5 | `pagination` param names not validated for blank | [x] Done |
| Q1 | `buildContext()` top-level boolean flags — NOT dead code | [x] Done |
| Q2 | FreeMarker `Configuration` rebuilt on every `generate()` | [x] Done |
| Q3 | `ApiBridgeRunner` re-validation guard manual extension | [x] Done |
| V6 | Transform `add` map allows blank header values | [x] Done |
| V7 | Transform warning fires twice per endpoint | [x] Done |
| Q4 | `applyOverride` first param `flags` unused | [x] Done |
| Q5 | `pagination != null` guard is dead code — documented invariant | [x] Done |
| Q6 | `flags??` dead outer guard in templates | [x] Done |
| Q7 | `configurationCache` never gets cache hit — made static | [x] Done |

### Deferred to later P7 phases

| ID | Description | Status |
|----|-------------|--------|
| A1 | `YamlParser.validate()` flat method — extract `validateEnum()` helper | [ ] Deferred |
| A2 | `searchMode`/`enableSearch` cross-field pattern precedent for OIDC | [ ] Deferred |
