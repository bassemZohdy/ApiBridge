package com.apibridge.generated;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

@Path("/")
@ApplicationScoped
public class CustomCssResource {

    @ConfigProperty(name = "CUSTOM_CSS_PATH", defaultValue = "")
    String customCssPath;

    @GET
    @Path("/custom.css")
    @Produces("text/css;charset=UTF-8")
    public Response customCss() {
        return Response.ok(loadCss()).type("text/css;charset=UTF-8").build();
    }

    private String loadCss() {
        if (customCssPath == null || customCssPath.isBlank()) {
            return "";
        }
        try {
            java.nio.file.Path path = Paths.get(customCssPath);
            if (!Files.exists(path) || !Files.isRegularFile(path)) {
                return "";
            }
            return Files.readString(path, StandardCharsets.UTF_8);
        } catch (IOException e) {
            return "";
        }
    }
}
