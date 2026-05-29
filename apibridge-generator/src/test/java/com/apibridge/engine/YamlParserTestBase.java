package com.apibridge.engine;

import org.junit.jupiter.api.BeforeEach;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;

public abstract class YamlParserTestBase {

    protected YamlParser parser;

    @BeforeEach
    public void setUp() {
        parser = new YamlParser();
    }

    protected File writeYaml(Path dir, String name, String content) throws IOException {
        File file = dir.resolve(name).toFile();
        try (FileWriter writer = new FileWriter(file)) {
            writer.write(content);
        }
        return file;
    }
}
