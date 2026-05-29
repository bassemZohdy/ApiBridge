package com.apibridge.engine;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class CartridgeCacheTest {

    @TempDir
    Path tempDir;

    @Test
    public void testNotCachedInitially() {
        CartridgeCache cache = new CartridgeCache(tempDir.toFile());
        assertFalse(cache.isCached("https://example.com/cartridge.zip"));
    }

    @Test
    public void testAllocateCreatesDirectory() {
        CartridgeCache cache = new CartridgeCache(tempDir.toFile());
        File dir = cache.allocate("https://example.com/cartridge.zip");
        assertTrue(dir.exists());
        assertTrue(dir.isDirectory());
    }

    @Test
    public void testIsCachedAfterAllocate() {
        CartridgeCache cache = new CartridgeCache(tempDir.toFile());
        String key = "https://example.com/cartridge.zip";
        assertFalse(cache.isCached(key));
        cache.allocate(key);
        assertTrue(cache.isCached(key));
    }

    @Test
    public void testResolveReturnsSamePathForSameKey() {
        CartridgeCache cache = new CartridgeCache(tempDir.toFile());
        File dir1 = cache.resolve("https://example.com/cartridge.zip");
        File dir2 = cache.resolve("https://example.com/cartridge.zip");
        assertEquals(dir1.getAbsolutePath(), dir2.getAbsolutePath());
    }

    @Test
    public void testResolveReturnsDifferentPathForDifferentKeys() {
        CartridgeCache cache = new CartridgeCache(tempDir.toFile());
        File dir1 = cache.resolve("https://example.com/a.zip");
        File dir2 = cache.resolve("https://example.com/b.zip");
        assertNotEquals(dir1.getAbsolutePath(), dir2.getAbsolutePath());
    }

    @Test
    public void testSha256Is64HexChars() {
        String hash = CartridgeCache.sha256("test-input");
        assertEquals(64, hash.length());
        assertTrue(hash.matches("[0-9a-f]+"));
    }

    @Test
    public void testSha256IsDeterministic() {
        assertEquals(CartridgeCache.sha256("abc"), CartridgeCache.sha256("abc"));
    }
}
