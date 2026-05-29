package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserPaginationTest extends YamlParserTestBase {

    @Test
    public void testPaginationDefaults(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                flags: {}
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                """);
        BridgeSchemaModel model = parser.parse(file);
        BridgeSchemaModel.Pagination p = model.getFlags().getPagination();
        assertNotNull(p);
        assertEquals("page", p.getPageParam());
        assertEquals("size", p.getSizeParam());
        assertEquals(20, p.getDefaultPageSize());
        assertEquals("sort", p.getSortParam());
        assertEquals("dir", p.getDirectionParam());
    }

    @Test
    public void testPaginationCustomValues(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                flags:
                  pagination:
                    pageParam: "_page"
                    sizeParam: "_limit"
                    defaultPageSize: 50
                    sortParam: "_sort"
                    directionParam: "_order"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                """);
        BridgeSchemaModel model = parser.parse(file);
        BridgeSchemaModel.Pagination p = model.getFlags().getPagination();
        assertEquals("_page", p.getPageParam());
        assertEquals("_limit", p.getSizeParam());
        assertEquals(50, p.getDefaultPageSize());
        assertEquals("_sort", p.getSortParam());
        assertEquals("_order", p.getDirectionParam());
    }

    @Test
    public void testPaginationNegativePageSizeThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                flags:
                  pagination:
                    defaultPageSize: -1
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().toLowerCase().contains("pagesize") ||
                   ex.getMessage().toLowerCase().contains("page size"));
    }

    @Test
    public void testPaginationDefaultPageSizeZeroThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                flags:
                  pagination:
                    defaultPageSize: 0
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("defaultPageSize"));
    }

    @Test
    public void testPaginationDefaultPageSizeOneIsValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                flags:
                  pagination:
                    defaultPageSize: 1
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals(1, model.getFlags().getPagination().getDefaultPageSize());
    }
}
