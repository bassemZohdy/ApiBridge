package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public abstract class ApiBridgeCartridgeEngineTestBase {

    protected YamlParser parser;
    protected ApiBridgeCartridgeEngine engine;

    @BeforeEach
    public void setUp() {
        parser = new YamlParser();
        engine = new ApiBridgeCartridgeEngine();
    }

    protected BridgeSchemaModel createTestModel() {
        BridgeSchemaModel model = new BridgeSchemaModel();
        model.setId("user-auth-service");
        model.setBasePath("/api/auth");

        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        flags.setEnableTelemetry(true);
        flags.setSecurityLevel("bearer-token");
        model.setFlags(flags);

        BridgeSchemaModel.Endpoint endpoint = new BridgeSchemaModel.Endpoint();
        endpoint.setPath("/login");
        endpoint.setMethod("POST");
        endpoint.setBackendUrl("https://auth.internal/login");
        endpoint.setTelemetryName("apibridge_auth_login");
        model.setEndpoints(java.util.List.of(endpoint));

        return model;
    }

    protected BridgeSchemaModel createListViewFormModel() {
        BridgeSchemaModel model = new BridgeSchemaModel();
        model.setId("customer-service");
        model.setBasePath("/api/customers");

        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        flags.setEnableTelemetry(false);
        model.setFlags(flags);

        BridgeSchemaModel.Endpoint listEp = new BridgeSchemaModel.Endpoint();
        listEp.setPath("/");
        listEp.setMethod("GET");
        listEp.setBackendUrl("https://example.com/customers");
        BridgeSchemaModel.UiLayout listLayout = new BridgeSchemaModel.UiLayout();
        listLayout.setComponent("List");
        model.getEndpoints();

        BridgeSchemaModel.Endpoint viewEp = new BridgeSchemaModel.Endpoint();
        viewEp.setPath("/{id}");
        viewEp.setMethod("GET");
        viewEp.setBackendUrl("https://example.com/customers/1");
        BridgeSchemaModel.UiLayout viewLayout = new BridgeSchemaModel.UiLayout();
        viewLayout.setComponent("View");
        viewEp.setUiLayout(viewLayout);

        BridgeSchemaModel.Endpoint formEp = new BridgeSchemaModel.Endpoint();
        formEp.setPath("/");
        formEp.setMethod("POST");
        formEp.setBackendUrl("https://example.com/customers");
        BridgeSchemaModel.UiLayout formLayout = new BridgeSchemaModel.UiLayout();
        formLayout.setComponent("Form");
        BridgeSchemaModel.Field nameField = new BridgeSchemaModel.Field();
        nameField.setName("name");
        nameField.setType("string");
        nameField.setRequired(true);
        formLayout.setFields(java.util.List.of(nameField));
        formEp.setUiLayout(formLayout);

        listEp.setUiLayout(listLayout);
        model.setEndpoints(java.util.List.of(listEp, viewEp, formEp));
        return model;
    }

    protected BridgeSchemaModel createMultiEndpointModel() {
        BridgeSchemaModel model = new BridgeSchemaModel();
        model.setId("submission-service");
        model.setBasePath("/api/v1/submissions");

        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        model.setFlags(flags);

        BridgeSchemaModel.Endpoint ep1 = new BridgeSchemaModel.Endpoint();
        ep1.setPath("/");
        ep1.setMethod("GET");
        ep1.setBackendUrl("https://backend.test/submissions");

        BridgeSchemaModel.Endpoint ep2 = new BridgeSchemaModel.Endpoint();
        ep2.setPath("/submissions");
        ep2.setMethod("GET");
        ep2.setBackendUrl("https://backend.test/submissions");

        BridgeSchemaModel.Endpoint ep3 = new BridgeSchemaModel.Endpoint();
        ep3.setPath("/submissions");
        ep3.setMethod("POST");
        ep3.setBackendUrl("https://backend.test/submissions");

        BridgeSchemaModel.Endpoint ep4 = new BridgeSchemaModel.Endpoint();
        ep4.setPath("/submissions/{id}");
        ep4.setMethod("GET");
        ep4.setBackendUrl("https://backend.test/submissions/1");

        BridgeSchemaModel.Endpoint ep5 = new BridgeSchemaModel.Endpoint();
        ep5.setPath("/submissions/{id}");
        ep5.setMethod("PUT");
        ep5.setBackendUrl("https://backend.test/submissions/1");

        BridgeSchemaModel.Endpoint ep6 = new BridgeSchemaModel.Endpoint();
        ep6.setPath("/submissions/{id}");
        ep6.setMethod("DELETE");
        ep6.setBackendUrl("https://backend.test/submissions/1");

        model.setEndpoints(java.util.List.of(ep1, ep2, ep3, ep4, ep5, ep6));
        return model;
    }

    protected void writeFtl(File cartridgeDir, String relativePath, String content) throws IOException {
        File target = new File(cartridgeDir, relativePath + ".ftl");
        target.getParentFile().mkdirs();
        try (FileWriter fw = new FileWriter(target)) {
            fw.write(content);
        }
    }

    protected File findCartridgeDir(String cartridgePath) {
        File dir = new File("../apibridge-cartridges/" + cartridgePath);
        if (!dir.exists()) {
            dir = new File("apibridge-cartridges/" + cartridgePath);
        }
        if (!dir.exists()) {
            throw new IllegalStateException("Cartridge folder not found: " + cartridgePath);
        }
        return dir;
    }
}
