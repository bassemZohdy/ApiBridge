package com.apibridge.engine;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/**
 * Downloads a cartridge ZIP archive from a URL and extracts it to a local directory,
 * with zip-slip protection on every entry.
 */
public class CartridgeDownloader {

    private final HttpClient httpClient;

    public CartridgeDownloader() {
        this.httpClient = HttpClient.newHttpClient();
    }

    CartridgeDownloader(HttpClient httpClient) {
        this.httpClient = httpClient;
    }

    public void downloadAndExtract(String url, File targetDir) throws IOException, InterruptedException {
        if (url == null || url.isBlank()) {
            throw new IllegalArgumentException("Download URL cannot be null or blank.");
        }
        if (targetDir == null) {
            throw new IllegalArgumentException("Target directory cannot be null.");
        }
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .GET()
                .build();
        HttpResponse<byte[]> response = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IOException("HTTP " + response.statusCode() + " from " + url);
        }
        extractZip(response.body(), targetDir);
    }

    static void extractZip(byte[] zipBytes, File targetDir) throws IOException {
        String canonicalDest = targetDir.getCanonicalPath() + File.separator;
        targetDir.mkdirs();
        try (ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(zipBytes))) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                File outFile = new File(targetDir, entry.getName());
                if (!outFile.getCanonicalPath().startsWith(canonicalDest)) {
                    throw new IOException("ZIP slip rejected: " + entry.getName());
                }
                if (entry.isDirectory()) {
                    outFile.mkdirs();
                } else {
                    outFile.getParentFile().mkdirs();
                    try (FileOutputStream fos = new FileOutputStream(outFile)) {
                        zis.transferTo(fos);
                    }
                }
                zis.closeEntry();
            }
        }
    }
}
