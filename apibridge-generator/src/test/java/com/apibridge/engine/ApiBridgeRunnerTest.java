package com.apibridge.engine;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class ApiBridgeRunnerTest {

    @Test
    public void testGetVersionReturnsNonEmpty() {
        String version = ApiBridgeRunner.getVersion();
        assertNotNull(version);
        assertFalse(version.isBlank());
    }

    @Test
    public void testGetVersionNeverReturnsNull() {
        // Defensively verify the fallback path: even when running outside
        // a shaded JAR (no Implementation-Version in manifest), getVersion()
        // returns the "unknown" sentinel rather than null.
        String version = ApiBridgeRunner.getVersion();
        assertNotNull(version);
    }
}
