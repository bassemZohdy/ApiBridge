package com.apibridge.engine;

import java.io.File;
import java.io.IOException;

/**
 * Resolves cartridge references to local directories. Supports three formats:
 * <ul>
 *   <li>Local path: {@code ./my-cartridge} or {@code /abs/path}</li>
 *   <li>URL: {@code https://host/file.zip} — downloaded, extracted, and cached</li>
 *   <li>GitHub shorthand: {@code github:owner/repo[/subpath][@ref]}</li>
 * </ul>
 * Downloaded cartridges are cached at {@code ~/.apibridge/cartridges/<sha256>/}.
 */
public class CartridgeResolver {

    private static final String GITHUB_PREFIX = "github:";
    private static final String DEFAULT_REF = "main";

    private final CartridgeCache cache;
    private final CartridgeDownloader downloader;
    private final String githubBaseUrl;

    public CartridgeResolver() {
        this(new CartridgeCache(), new CartridgeDownloader(), "https://github.com");
    }

    CartridgeResolver(CartridgeCache cache, CartridgeDownloader downloader, String githubBaseUrl) {
        this.cache = cache;
        this.downloader = downloader;
        this.githubBaseUrl = githubBaseUrl;
    }

    public File resolve(String cartridgeArg) throws IOException, InterruptedException {
        if (cartridgeArg == null || cartridgeArg.isBlank()) {
            throw new IllegalArgumentException("Cartridge reference cannot be null or blank.");
        }
        if (cartridgeArg.startsWith(GITHUB_PREFIX)) {
            return resolveGitHub(cartridgeArg.substring(GITHUB_PREFIX.length()));
        }
        if (cartridgeArg.startsWith("https://") || cartridgeArg.startsWith("http://")) {
            return resolveUrl(cartridgeArg);
        }
        return new File(cartridgeArg);
    }

    private File resolveUrl(String url) throws IOException, InterruptedException {
        if (cache.isCached(url)) {
            return cache.resolve(url);
        }
        File targetDir = cache.allocate(url);
        try {
            downloader.downloadAndExtract(url, targetDir);
            cache.commit(url);
        } catch (Exception e) {
            cache.cleanup(url);
            throw e;
        }
        return cache.resolve(url);
    }

    private File resolveGitHub(String spec) throws IOException, InterruptedException {
        String ref = DEFAULT_REF;
        String path = spec;
        if (spec.contains("@")) {
            int atIdx = spec.lastIndexOf('@');
            ref = spec.substring(atIdx + 1);
            path = spec.substring(0, atIdx);
        }

        String[] parts = path.split("/", 3);
        if (parts.length < 2) {
            throw new IllegalArgumentException(
                    "Invalid github: reference — expected github:owner/repo[/subpath][@ref], got: github:" + spec);
        }
        String owner = parts[0];
        String repo = parts[1];
        String subpath = (parts.length == 3) ? parts[2] : null;

        String archiveUrl = githubBaseUrl + "/" + owner + "/" + repo
                + "/archive/refs/heads/" + ref + ".zip";
        String cacheKey = archiveUrl + (subpath != null ? "#" + subpath : "");

        if (cache.isCached(cacheKey)) {
            return cache.resolve(cacheKey);
        }

        File archiveDir = cache.allocate(cacheKey);
        try {
            downloader.downloadAndExtract(archiveUrl, archiveDir);
            cache.commit(cacheKey);
        } catch (Exception e) {
            cache.cleanup(cacheKey);
            throw e;
        }

        File committedDir = cache.resolve(cacheKey);
        if (subpath != null) {
            return new File(committedDir, repo + "-" + ref + "/" + subpath);
        }
        return new File(committedDir, repo + "-" + ref);
    }
}
