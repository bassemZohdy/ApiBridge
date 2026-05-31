package com.apibridge.engine;

import java.io.File;
import java.nio.charset.StandardCharsets;
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
        return resolve(key).isDirectory();
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
        File dir = resolve(key);
        dir.mkdirs();
        return dir;
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
