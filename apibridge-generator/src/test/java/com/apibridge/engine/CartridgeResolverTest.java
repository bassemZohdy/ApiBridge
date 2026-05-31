package com.apibridge.engine;

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.file.Path;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import static org.junit.jupiter.api.Assertions.*;

public class CartridgeResolverTest {

    static HttpServer server;
    static int port;
    static byte[] directZip;
    static byte[] githubArchiveZip;

    @TempDir
    Path tempDir;

    @BeforeAll
    static void startServer() throws IOException {
        directZip = buildZip("template.txt.ftl", "<#-- direct -->");
        githubArchiveZip = buildZip("my-cartridge-main/templates/template.txt.ftl", "<#-- github -->");

        server = HttpServer.create(new InetSocketAddress(0), 0);
        port = server.getAddress().getPort();

        server.createContext("/my-cartridge.zip", exchange -> {
            exchange.sendResponseHeaders(200, directZip.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(directZip);
            }
        });
        server.createContext("/my-org/my-cartridge/archive/refs/heads/main.zip", exchange -> {
            exchange.sendResponseHeaders(200, githubArchiveZip.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(githubArchiveZip);
            }
        });
        server.start();
    }

    @AfterAll
    static void stopServer() {
        server.stop(0);
    }

    private static byte[] buildZip(String entryName, String content) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            zos.putNextEntry(new ZipEntry(entryName));
            zos.write(content.getBytes());
            zos.closeEntry();
        }
        return baos.toByteArray();
    }

    private CartridgeResolver resolver() {
        return new CartridgeResolver(
                new CartridgeCache(tempDir.resolve("cache").toFile()),
                new CartridgeDownloader(),
                "http://localhost:" + port);
    }

    @Test
    public void testRelativeLocalPathPassthrough() throws Exception {
        File result = resolver().resolve("./my-cartridge");
        assertEquals(new File("./my-cartridge").getPath(), result.getPath());
    }

    @Test
    public void testAbsoluteLocalPathPassthrough() throws Exception {
        File result = resolver().resolve("/opt/cartridges/my-cartridge");
        assertEquals(new File("/opt/cartridges/my-cartridge").getPath(), result.getPath());
    }

    @Test
    public void testUrlDownloadsAndExtractsTemplate() throws Exception {
        String url = "http://localhost:" + port + "/my-cartridge.zip";
        File result = resolver().resolve(url);
        assertTrue(result.exists(), "Resolved dir should exist: " + result);
        assertTrue(new File(result, "template.txt.ftl").exists(), "template.txt.ftl should be extracted");
    }

    @Test
    public void testUrlCacheHitReturnsSamePath() throws Exception {
        CartridgeResolver r = resolver();
        String url = "http://localhost:" + port + "/my-cartridge.zip";
        File first = r.resolve(url);
        File second = r.resolve(url);
        assertEquals(first.getAbsolutePath(), second.getAbsolutePath());
    }

    @Test
    public void testGithubShorthandWithSubpath() throws Exception {
        File result = resolver().resolve("github:my-org/my-cartridge/templates");
        assertTrue(result.exists(), "Resolved dir should exist: " + result);
        assertTrue(new File(result, "template.txt.ftl").exists(),
                "template.txt.ftl should be present inside templates/ subdir");
    }

    @Test
    public void testInvalidGithubSpecThrows() {
        assertThrows(IllegalArgumentException.class, () -> resolver().resolve("github:badspec"));
    }

    @Test
    public void testNullArgThrows() {
        assertThrows(IllegalArgumentException.class, () -> resolver().resolve(null));
    }

    @Test
    public void testBlankArgThrows() {
        assertThrows(IllegalArgumentException.class, () -> resolver().resolve("  "));
    }
}
