package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class DarkModeEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testReactAppContainsDarkModeToggle(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("frontend/react"), tempDir.resolve("out").toFile());

        String app = Files.readString(tempDir.resolve("out/frontend/src/App.tsx"));
        assertTrue(app.contains("apib-theme-toggle"), "React App must render apib-theme-toggle button");
        assertTrue(app.contains("localStorage.getItem('apib-theme')"), "React App must read theme from localStorage");
        assertTrue(app.contains("data-theme"), "React App must set data-theme attribute");
        String css = Files.readString(tempDir.resolve("out/frontend/src/index.css"));
        assertTrue(css.contains("[data-theme=\"dark\"]"), "index.css must contain dark mode CSS block");
    }

    @Test
    public void testAngularAppContainsDarkModeToggle(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("frontend/angular"), tempDir.resolve("out").toFile());

        String ts = Files.readString(tempDir.resolve("out/frontend/src/app/app.component.ts"));
        assertTrue(ts.contains("toggleTheme"), "Angular AppComponent must have toggleTheme method");
        assertTrue(ts.contains("apib-theme"), "Angular AppComponent must reference apib-theme localStorage key");
        assertTrue(ts.contains("data-theme"), "Angular AppComponent must set data-theme attribute");
        String html = Files.readString(tempDir.resolve("out/frontend/src/app/app.component.html"));
        assertTrue(html.contains("apib-theme-toggle"), "Angular app.component.html must render apib-theme-toggle button");
        String css = Files.readString(tempDir.resolve("out/frontend/src/styles.css"));
        assertTrue(css.contains("[data-theme=\"dark\"]"), "styles.css must contain dark mode CSS block");
    }

    @Test
    public void testVueAppContainsDarkModeToggle(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("frontend/vue"), tempDir.resolve("out").toFile());

        String app = Files.readString(tempDir.resolve("out/frontend/src/App.vue"));
        assertTrue(app.contains("apib-theme-toggle"), "Vue App must render apib-theme-toggle button");
        assertTrue(app.contains("localStorage.getItem('apib-theme')"), "Vue App must read theme from localStorage");
        assertTrue(app.contains("[data-theme=\"dark\"]"), "Vue App.vue must contain dark mode CSS block");
        assertTrue(app.contains("toggleTheme"), "Vue App must have toggleTheme function");
    }
}
