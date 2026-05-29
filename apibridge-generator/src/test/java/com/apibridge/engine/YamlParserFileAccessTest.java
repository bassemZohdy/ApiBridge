package com.apibridge.engine;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserFileAccessTest extends YamlParserTestBase {

    @Test
    public void testNullFileThrows() {
        assertThrows(IllegalArgumentException.class, () -> parser.parse(null));
    }

    @Test
    public void testNonExistentFileThrows(@TempDir Path tempDir) {
        File ghost = tempDir.resolve("does-not-exist.yaml").toFile();
        assertThrows(FileNotFoundException.class, () -> parser.parse(ghost));
    }

    @Test
    public void testDirectoryThrows(@TempDir Path tempDir) {
        File dir = tempDir.toFile();
        assertThrows(IllegalArgumentException.class, () -> parser.parse(dir));
    }

    @Test
    public void testMalformedYamlThrows(@TempDir Path tempDir) throws IOException {
        // Unclosed double-quoted scalar — guaranteed SnakeYAML ScannerException
        File file = writeYaml(tempDir, "malformed.yaml", """
                id: "unclosed
                basePath: /api
                """);
        assertThrows(IOException.class, () -> parser.parse(file));
    }

    @Test
    public void testNullYamlDocumentThrows(@TempDir Path tempDir) throws IOException {
        // YAML '~' is the null literal — Jackson parses successfully but returns null model
        File file = writeYaml(tempDir, "null.yaml", "~\n");
        assertThrows(IllegalArgumentException.class, () -> parser.parse(file));
    }
}
