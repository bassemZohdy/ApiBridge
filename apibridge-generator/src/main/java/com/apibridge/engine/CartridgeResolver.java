package com.apibridge.engine;

import java.io.File;
import java.io.IOException;

public class CartridgeResolver {

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
        if (cartridgeArg.startsWith("github:")) {
            return resolveGitHub(cartridgeArg.substring("github:".length()));
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
        downloader.downloadAndExtract(url, targetDir);
        return targetDir;
    }

    private File resolveGitHub(String spec) throws IOException, InterruptedException {
        String ref = "main";
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
        downloader.downloadAndExtract(archiveUrl, archiveDir);

        if (subpath != null) {
            return new File(archiveDir, repo + "-" + ref + "/" + subpath);
        }
        return new File(archiveDir, repo + "-" + ref);
    }
}
