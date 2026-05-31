package com.apibridge.engine;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Content-addressable cache for downloaded cartridge archives. Each cartridge URL is
 * hashed (SHA-256) and stored under {@code ~/.apibridge/cartridges/<hash>/}.
 */
public class CartridgeCache {

    private final File cacheRoot;

    public CartridgeCache() {
        this(new File(System.getProperty("user.home"), ".apibridge/cartridges"));
    }

    CartridgeCache(File cacheRoot) {
        this.cacheRoot = cacheRoot;
    }

    public boolean isCached(String key) {
        if (key == null) {
            throw new IllegalArgumentException("Cache key cannot be null.");
        }
        File dir = resolve(key);
        return dir.isDirectory() && dir.list() != null && dir.list().length > 0;
    }

    public File resolve(String key) {
        if (key == null) {
            throw new IllegalArgumentException("Cache key cannot be null.");
        }
        return new File(cacheRoot, sha256(key));
    }

    public File allocate(String key) {
        if (key == null) {
            throw new IllegalArgumentException("Cache key cannot be null.");
        }
        File tmpDir = new File(cacheRoot, sha256(key) + ".tmp");
        tmpDir.mkdirs();
        return tmpDir;
    }

    public void commit(String key) throws IOException {
        if (key == null) {
            throw new IllegalArgumentException("Cache key cannot be null.");
        }
        File tmpDir = new File(cacheRoot, sha256(key) + ".tmp");
        File finalDir = resolve(key);
        if (!tmpDir.isDirectory()) {
            throw new IOException("Temporary cache directory does not exist: " + tmpDir);
        }
        if (finalDir.exists()) {
            deleteRecursive(finalDir);
        }
        Files.move(tmpDir.toPath(), finalDir.toPath(), StandardCopyOption.ATOMIC_MOVE);
    }

    public void cleanup(String key) {
        if (key == null) {
            return;
        }
        File tmpDir = new File(cacheRoot, sha256(key) + ".tmp");
        if (tmpDir.exists()) {
            deleteRecursive(tmpDir);
        }
    }

    private static void deleteRecursive(File dir) {
        File[] files = dir.listFiles();
        if (files != null) {
            for (File f : files) {
                if (f.isDirectory()) {
                    deleteRecursive(f);
                } else {
                    f.delete();
                }
            }
        }
        dir.delete();
    }

    static String sha256(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(64);
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
