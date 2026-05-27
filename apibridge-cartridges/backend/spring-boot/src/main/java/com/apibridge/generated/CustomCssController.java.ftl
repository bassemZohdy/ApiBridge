package com.apibridge.generated;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

@RestController
public class CustomCssController {

    @Value("${r"${CUSTOM_CSS_PATH:}"}")
    private String customCssPath;

    private static final MediaType TEXT_CSS = MediaType.valueOf("text/css;charset=UTF-8");

    @GetMapping(value = "/custom.css", produces = "text/css;charset=UTF-8")
    public ResponseEntity<String> customCss() {
        String css = loadCss();
        return ResponseEntity.ok()
                .contentType(TEXT_CSS)
                .body(css);
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
