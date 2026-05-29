package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class SchemaComposerTest {

    private BridgeSchemaModel schema(String id, String basePath, String... paths) {
        BridgeSchemaModel m = new BridgeSchemaModel();
        m.setId(id);
        m.setBasePath(basePath);
        List<BridgeSchemaModel.Endpoint> eps = new ArrayList<>();
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
        BridgeSchemaModel b = schema("b", "/api", "/items");
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
