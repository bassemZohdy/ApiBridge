package com.apibridge.engine;

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import static org.junit.jupiter.api.Assertions.*;

public class CartridgeDownloaderTest {

    static HttpServer server;
    static int port;
    static byte[] testZipBytes;

    @TempDir
    Path tempDir;

    @BeforeAll
    static void startServer() throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            ZipEntry entry = new ZipEntry("hello.txt.ftl");
            zos.putNextEntry(entry);
            zos.write("Hello ${model.id}".getBytes());
            zos.closeEntry();
        }
        testZipBytes = baos.toByteArray();

        server = HttpServer.create(new InetSocketAddress(0), 0);
        port = server.getAddress().getPort();
        server.createContext("/cartridge.zip", exchange -> {
            exchange.sendResponseHeaders(200, testZipBytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(testZipBytes);
            }
        });
        server.start();
    }

    @AfterAll
    static void stopServer() {
        server.stop(0);
    }

    @Test
    public void testDownloadAndExtractCreatesFile() throws Exception {
        CartridgeDownloader downloader = new CartridgeDownloader();
        downloader.downloadAndExtract("http://localhost:" + port + "/cartridge.zip", tempDir.toFile());

        java.io.File extracted = tempDir.resolve("hello.txt.ftl").toFile();
        assertTrue(extracted.exists(), "Expected extracted file: " + extracted.getPath());
        assertEquals("Hello ${model.id}", Files.readString(extracted.toPath()));
    }

    @Test
    public void testExtractZipDirectly() throws IOException {
        CartridgeDownloader.extractZip(testZipBytes, tempDir.toFile());
        assertTrue(tempDir.resolve("hello.txt.ftl").toFile().exists());
    }

    @Test
    public void testExtractZipRejectsZipSlip() throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            ZipEntry malicious = new ZipEntry("../../evil.txt");
            zos.putNextEntry(malicious);
            zos.write("evil".getBytes());
            zos.closeEntry();
        }
        assertThrows(IOException.class,
                () -> CartridgeDownloader.extractZip(baos.toByteArray(), tempDir.toFile()));
    }

    @Test
    public void testDownloadThrowsOnConnectionRefused() {
        CartridgeDownloader downloader = new CartridgeDownloader();
        assertThrows(Exception.class,
                () -> downloader.downloadAndExtract("http://localhost:1/missing.zip", tempDir.toFile()));
    }
}
