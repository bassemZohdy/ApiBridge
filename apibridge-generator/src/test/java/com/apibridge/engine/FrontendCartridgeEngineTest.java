package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class FrontendCartridgeEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testAngularCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("angular");
        File cartridgeDir = findCartridgeDir("frontend/angular");
        File outputDir = tempDir.resolve("output-angular").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path tsPath = outputDir.toPath()
                .resolve("frontend/src/app/bridge-form.component.ts");
        Path htmlPath = outputDir.toPath()
                .resolve("frontend/src/app/bridge-form.component.html");
        Path pkgPath = outputDir.toPath().resolve("frontend/package.json");
        assertTrue(Files.exists(tsPath));
        assertTrue(Files.exists(htmlPath));
        assertTrue(Files.exists(pkgPath));
        String tsContent = Files.readString(tsPath);
        assertTrue(tsContent.contains("export class BridgeFormComponent"));
    }

    @Test
    public void testReactCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("react");
        File cartridgeDir = findCartridgeDir("frontend/react");
        File outputDir = tempDir.resolve("output-react").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path tsxPath = outputDir.toPath().resolve("frontend/src/ApiBridgeForm.tsx");
        Path pkgPath = outputDir.toPath().resolve("frontend/package.json");
        assertTrue(Files.exists(tsxPath));
        assertTrue(Files.exists(pkgPath));
        String tsxContent = Files.readString(tsxPath);
        assertTrue(tsxContent.contains("export const ApiBridgeForm"));
    }

    @Test
    public void testVueCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("vue");
        File cartridgeDir = findCartridgeDir("frontend/vue");
        File outputDir = tempDir.resolve("output-vue").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path vuePath = outputDir.toPath().resolve("frontend/src/ApiBridgeForm.vue");
        Path pkgPath = outputDir.toPath().resolve("frontend/package.json");
        assertTrue(Files.exists(vuePath));
        assertTrue(Files.exists(pkgPath));
        String vueContent = Files.readString(vuePath);
        assertTrue(vueContent.contains("<template>"));
    }

    @Test
    public void testReactCartridgeWithListViewForm(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createListViewFormModel();
        File cartridgeDir = findCartridgeDir("frontend/react");
        File outputDir = tempDir.resolve("output-react-lvf").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path listPath = outputDir.toPath().resolve("frontend/src/ApiBridgeList.tsx");
        Path viewPath = outputDir.toPath().resolve("frontend/src/ApiBridgeView.tsx");
        Path formPath = outputDir.toPath().resolve("frontend/src/ApiBridgeForm.tsx");
        Path appPath  = outputDir.toPath().resolve("frontend/src/App.tsx");
        assertTrue(Files.exists(listPath), "ApiBridgeList.tsx must be generated");
        assertTrue(Files.exists(viewPath), "ApiBridgeView.tsx must be generated");
        assertTrue(Files.exists(formPath), "ApiBridgeForm.tsx must be generated");
        assertTrue(Files.exists(appPath),  "App.tsx must be generated");

        String listContent = Files.readString(listPath);
        assertTrue(listContent.contains("ApiBridgeList"));
        assertTrue(listContent.contains("apib-table"));

        String viewContent = Files.readString(viewPath);
        assertTrue(viewContent.contains("ApiBridgeView"));
        assertTrue(viewContent.contains("apib-detail-grid"));
    }

    @Test
    public void testAngularCartridgeWithListViewForm(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createListViewFormModel();
        model.getFlags().setFeFlavor("angular");
        File cartridgeDir = findCartridgeDir("frontend/angular");
        File outputDir = tempDir.resolve("output-angular-lvf").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path listTs   = outputDir.toPath().resolve("frontend/src/app/bridge-list.component.ts");
        Path listHtml = outputDir.toPath().resolve("frontend/src/app/bridge-list.component.html");
        Path viewTs   = outputDir.toPath().resolve("frontend/src/app/bridge-view.component.ts");
        Path viewHtml = outputDir.toPath().resolve("frontend/src/app/bridge-view.component.html");
        assertTrue(Files.exists(listTs),   "bridge-list.component.ts must be generated");
        assertTrue(Files.exists(listHtml), "bridge-list.component.html must be generated");
        assertTrue(Files.exists(viewTs),   "bridge-view.component.ts must be generated");
        assertTrue(Files.exists(viewHtml), "bridge-view.component.html must be generated");

        assertTrue(Files.readString(listTs).contains("BridgeListComponent"));
        assertTrue(Files.readString(viewTs).contains("BridgeViewComponent"));
    }

    @Test
    public void testVueCartridgeWithListViewForm(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createListViewFormModel();
        File cartridgeDir = findCartridgeDir("frontend/vue");
        File outputDir = tempDir.resolve("output-vue-lvf").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path listPath = outputDir.toPath().resolve("frontend/src/ApiBridgeList.vue");
        Path viewPath = outputDir.toPath().resolve("frontend/src/ApiBridgeView.vue");
        assertTrue(Files.exists(listPath), "ApiBridgeList.vue must be generated");
        assertTrue(Files.exists(viewPath), "ApiBridgeView.vue must be generated");

        assertTrue(Files.readString(listPath).contains("apib-table"));
        assertTrue(Files.readString(viewPath).contains("apib-detail-grid"));
    }
}
