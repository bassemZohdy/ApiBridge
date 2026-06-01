package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class SearchFilterEngineTest extends ApiBridgeCartridgeEngineTestBase {

    private BridgeSchemaModel createSearchTestModel() {
        BridgeSchemaModel model = new BridgeSchemaModel();
        model.setId("search-service");
        model.setBasePath("/api/search");
        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        flags.setEnableTelemetry(false);
        flags.setEnableSearch(true);
        flags.setFeFlavor("react");
        model.setFlags(flags);
        BridgeSchemaModel.Endpoint listEp = new BridgeSchemaModel.Endpoint();
        listEp.setPath("/items");
        listEp.setMethod("GET");
        listEp.setBackendUrl("https://example.com/items");
        BridgeSchemaModel.UiLayout layout = new BridgeSchemaModel.UiLayout();
        layout.setComponent("List");
        layout.setSearchMode("delegate");
        listEp.setUiLayout(layout);
        model.setEndpoints(java.util.List.of(listEp));
        return model;
    }

    @Test
    public void testReactListContainsSearchBarWhenEnabled(@TempDir Path tempDir) throws Exception {
        engine.generate(createSearchTestModel(), findCartridgeDir("frontend/react"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/ApiBridgeList.tsx"));
        assertTrue(content.contains("apib-search-bar"), "React List must contain apib-search-bar when enableSearch=true");
        assertTrue(content.contains("searchTerm"), "React List must have searchTerm state");
    }

    @Test
    public void testAngularListContainsSearchWhenEnabled(@TempDir Path tempDir) throws Exception {
        engine.generate(createSearchTestModel(), findCartridgeDir("frontend/angular"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/app/bridge-list.component.ts"));
        assertTrue(content.contains("searchTerm"), "Angular List must have searchTerm field when enableSearch=true");
        assertTrue(content.contains("searchParam"), "Angular List must use searchParam");
    }

    @Test
    public void testVueListContainsSearchWhenEnabled(@TempDir Path tempDir) throws Exception {
        engine.generate(createSearchTestModel(), findCartridgeDir("frontend/vue"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/ApiBridgeList.vue"));
        assertTrue(content.contains("apib-search-bar"), "Vue List must contain apib-search-bar when enableSearch=true");
        assertTrue(content.contains("searchTerm"), "Vue List must have searchTerm ref");
    }

    @Test
    public void testReactListNoSearchWhenDisabled(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createSearchTestModel();
        model.getFlags().setEnableSearch(false);
        engine.generate(model, findCartridgeDir("frontend/react"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/ApiBridgeList.tsx"));
        assertFalse(content.contains("apib-search-bar"), "React List must not contain search bar when disabled");
        assertFalse(content.contains("searchTerm"), "React List must not have searchTerm when disabled");
    }

    @Test
    public void testBridgeConfigControllerContainsEnableSearchAndSearchParam(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createSearchTestModel();
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeConfigController.java"));
        assertTrue(content.contains("enableSearch"), "BridgeConfigController must expose enableSearch");
        assertTrue(content.contains("searchParam"), "BridgeConfigController must expose searchParam");
        assertTrue(content.contains("SEARCH_PARAM"), "BridgeConfigController must inject SEARCH_PARAM env var");
    }

    @Test
    public void testDockerComposeContainsSearchParamWhenEnabled(@TempDir Path tempDir) throws Exception {
        engine.generate(createSearchTestModel(), findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("SEARCH_PARAM"), "docker-compose must contain SEARCH_PARAM when enableSearch=true");
    }

    private BridgeSchemaModel createLocalSearchModel() {
        BridgeSchemaModel model = createSearchTestModel();
        model.getEndpoints().get(0).getUiLayout().setSearchMode("local");
        return model;
    }

    @Test
    public void testReactDelegateSearchHasNoLocalTotal(@TempDir Path tempDir) throws Exception {
        engine.generate(createSearchTestModel(), findCartridgeDir("frontend/react"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/ApiBridgeList.tsx"));
        assertFalse(content.contains("localTotal"), "React: localTotal must not appear when searchMode=delegate");
        assertTrue(content.contains("total !== null"), "React: server total check must appear when searchMode=delegate");
    }

    @Test
    public void testReactLocalSearchHasLocalTotal(@TempDir Path tempDir) throws Exception {
        engine.generate(createLocalSearchModel(), findCartridgeDir("frontend/react"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/ApiBridgeList.tsx"));
        assertTrue(content.contains("localTotal"), "React: localTotal must appear when searchMode=local");
        assertTrue(content.contains("visibleRows"), "React: visibleRows must appear when searchMode=local");
    }

    @Test
    public void testAngularDelegateSearchHasNoLocalTotal(@TempDir Path tempDir) throws Exception {
        engine.generate(createSearchTestModel(), findCartridgeDir("frontend/angular"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/app/bridge-list.component.ts"));
        assertFalse(content.contains("localTotal"), "Angular: localTotal must not appear when searchMode=delegate");
    }

    @Test
    public void testAngularLocalSearchHasLocalTotal(@TempDir Path tempDir) throws Exception {
        engine.generate(createLocalSearchModel(), findCartridgeDir("frontend/angular"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/app/bridge-list.component.ts"));
        assertTrue(content.contains("localTotal"), "Angular: localTotal must appear when searchMode=local");
    }

    @Test
    public void testVueDelegateSearchHasNoLocalTotal(@TempDir Path tempDir) throws Exception {
        engine.generate(createSearchTestModel(), findCartridgeDir("frontend/vue"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/ApiBridgeList.vue"));
        assertFalse(content.contains("localTotal"), "Vue: localTotal must not appear when searchMode=delegate");
    }

    @Test
    public void testVueLocalSearchHasLocalTotal(@TempDir Path tempDir) throws Exception {
        engine.generate(createLocalSearchModel(), findCartridgeDir("frontend/vue"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/ApiBridgeList.vue"));
        assertTrue(content.contains("localTotal"), "Vue: localTotal must appear when searchMode=local");
    }
}
