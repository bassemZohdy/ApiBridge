package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class OfflineSupportEngineTest extends ApiBridgeCartridgeEngineTestBase {

    private BridgeSchemaModel createOfflineModel() {
        BridgeSchemaModel model = createListViewFormModel();
        model.getFlags().setEnableOfflineSupport(true);
        return model;
    }

    @Test
    public void testReactSwJsGeneratedWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOfflineModel(), findCartridgeDir("frontend/react"), tempDir.resolve("out").toFile());

        String sw = Files.readString(tempDir.resolve("out/frontend/public/sw.js"));
        assertTrue(sw.contains("CACHE_NAME"), "sw.js must define CACHE_NAME");
        assertTrue(sw.contains("install"), "sw.js must have install handler");
        assertTrue(sw.contains("fetch"), "sw.js must have fetch handler");
        assertTrue(sw.contains("activate"), "sw.js must have activate handler");
    }

    @Test
    public void testAngularSwJsGeneratedWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOfflineModel(), findCartridgeDir("frontend/angular"), tempDir.resolve("out").toFile());

        String sw = Files.readString(tempDir.resolve("out/frontend/src/sw.js"));
        assertTrue(sw.contains("CACHE_NAME"), "Angular sw.js must define CACHE_NAME");
        assertTrue(sw.contains("fetch"), "Angular sw.js must have fetch handler");
    }

    @Test
    public void testVueSwJsGeneratedWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOfflineModel(), findCartridgeDir("frontend/vue"), tempDir.resolve("out").toFile());

        String sw = Files.readString(tempDir.resolve("out/frontend/public/sw.js"));
        assertTrue(sw.contains("CACHE_NAME"), "Vue sw.js must define CACHE_NAME");
        assertTrue(sw.contains("fetch"), "Vue sw.js must have fetch handler");
    }

    @Test
    public void testNoSwJsWhenFlagOff(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createListViewFormModel();
        engine.generate(model, findCartridgeDir("frontend/react"), tempDir.resolve("out").toFile());

        assertFalse(Files.exists(tempDir.resolve("out/frontend/public/sw.js")),
                "sw.js must NOT be generated when enableOfflineSupport is false");
    }

    @Test
    public void testReactMainRegistersSwWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOfflineModel(), findCartridgeDir("frontend/react"), tempDir.resolve("out").toFile());

        String main = Files.readString(tempDir.resolve("out/frontend/src/main.tsx"));
        assertTrue(main.contains("serviceWorker.register"), "main.tsx must register service worker");
        assertTrue(main.contains("/sw.js"), "main.tsx must reference sw.js path");
    }

    @Test
    public void testReactAppContainsOnlineStatusHookWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOfflineModel(), findCartridgeDir("frontend/react"), tempDir.resolve("out").toFile());

        String app = Files.readString(tempDir.resolve("out/frontend/src/App.tsx"));
        assertTrue(app.contains("useOnlineStatus"), "App.tsx must contain useOnlineStatus hook");
        assertTrue(app.contains("apib-offline-banner"), "App.tsx must contain offline banner");
    }
}
