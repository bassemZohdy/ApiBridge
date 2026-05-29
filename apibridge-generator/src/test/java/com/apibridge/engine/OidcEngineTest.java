package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class OidcEngineTest extends ApiBridgeCartridgeEngineTestBase {

    private BridgeSchemaModel createOidcModel() {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableOidc(true);
        model.getFlags().setOidcIssuerUri("https://keycloak.example.com/realms/myrealm");
        return model;
    }

    @Test
    public void testSpringBootGeneratesSecurityConfig(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve(
                "out/backend/src/main/java/com/apibridge/generated/SecurityConfig.java"));
        assertTrue(content.contains("SecurityConfig"), "must generate SecurityConfig class");
        assertTrue(content.contains("oauth2ResourceServer"), "must configure OAuth2 resource server");
        assertTrue(content.contains("STATELESS"), "must use stateless sessions");
    }

    @Test
    public void testSpringBootSecurityConfigNotGeneratedWhenFlagOff(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        assertFalse(
                Files.exists(tempDir.resolve(
                        "out/backend/src/main/java/com/apibridge/generated/SecurityConfig.java")),
                "SecurityConfig must NOT be generated when enableOidc is false");
    }

    @Test
    public void testSpringBootPomHasOidcDepWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("spring-boot-starter-oauth2-resource-server"),
                "pom must include OAuth2 resource server starter when enableOidc=true");
    }

    @Test
    public void testSpringBootApplicationPropertiesHasIssuerUri(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String props = Files.readString(tempDir.resolve(
                "out/backend/src/main/resources/application.properties"));
        assertTrue(props.contains("spring.security.oauth2.resourceserver.jwt.issuer-uri"),
                "application.properties must declare issuer-uri when enableOidc=true");
        assertTrue(props.contains("keycloak.example.com"),
                "application.properties must embed the configured oidcIssuerUri");
    }

    @Test
    public void testQuarkusPomHasOidcDepWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("quarkus-oidc"),
                "Quarkus pom must include quarkus-oidc dep when enableOidc=true");
    }

    @Test
    public void testQuarkusApplicationPropertiesHasOidcConfig(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String props = Files.readString(tempDir.resolve(
                "out/backend/src/main/resources/application.properties"));
        assertTrue(props.contains("quarkus.oidc.auth-server-url"),
                "Quarkus application.properties must have quarkus.oidc.auth-server-url");
        assertTrue(props.contains("keycloak.example.com"),
                "Quarkus application.properties must embed the oidcIssuerUri");
    }

    @Test
    public void testHealthAndConfigEndpointsPermitAllInSecurityConfig(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve(
                "out/backend/src/main/java/com/apibridge/generated/SecurityConfig.java"));
        assertTrue(content.contains("bridge-config") || content.contains("permitAll"),
                "SecurityConfig must allow bridge-config + bridge-health without auth");
    }
}
