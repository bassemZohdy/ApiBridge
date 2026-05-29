package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import freemarker.template.Configuration;
import freemarker.template.Template;
import freemarker.template.TemplateException;
import freemarker.template.TemplateExceptionHandler;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.StringWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

public class ApiBridgeCartridgeEngine {

    private final Map<String, Configuration> configurationCache = new HashMap<>();

    // Cartridges nested under one of these category dirs auto-prefix their output with that dir name.
    private static final java.util.Set<String> OUTPUT_PREFIX_CATEGORIES =
            java.util.Set.of("backend", "frontend", "k8s");

    public void generate(BridgeSchemaModel model, File cartridgeDir, File outputDir)
            throws IOException, TemplateException {
        if (model == null) {
            throw new IllegalArgumentException("Bridge Schema Model (PIM) cannot be null.");
        }
        if (cartridgeDir == null || !cartridgeDir.exists() || !cartridgeDir.isDirectory()) {
            throw new IllegalArgumentException("Cartridge path must point to a valid, existing directory.");
        }
        if (outputDir == null) {
            throw new IllegalArgumentException("Output directory cannot be null.");
        }

        File effectiveOutputDir = resolveEffectiveOutputDir(cartridgeDir, outputDir);

        if (!effectiveOutputDir.exists() && !effectiveOutputDir.mkdirs()) {
            throw new IOException("Failed to create target output directory: " + effectiveOutputDir.getAbsolutePath());
        }

        Configuration cfg = buildConfiguration(cartridgeDir);

        List<TemplateEntry> entries = new ArrayList<>();
        collectTemplates(cartridgeDir, cartridgeDir, effectiveOutputDir, entries);

        if (entries.isEmpty()) {
            throw new IllegalArgumentException(
                    "No blueprint template files (*.ftl) found in cartridge: " + cartridgeDir.getAbsolutePath());
        }

        System.out.println("Discovered " + entries.size() + " blueprint templates inside cartridge: "
                + cartridgeDir.getName());

        Map<String, Object> context = buildContext(model);

        for (TemplateEntry entry : entries) {
            System.out.println("Processing blueprint template: " + entry.templateName);

            Template template = cfg.getTemplate(entry.templateName);
            StringWriter sw = new StringWriter();
            template.process(context, sw);
            String rendered = sw.toString();

            if (rendered.isBlank()) {
                System.out.println("Skipping empty output for: " + entry.templateName);
                continue;
            }

            File parentDir = entry.outputFile.getParentFile();
            if (!parentDir.exists() && !parentDir.mkdirs()) {
                throw new IOException("Failed to create output directory: " + parentDir.getAbsolutePath());
            }

            try (Writer writer = new FileWriter(entry.outputFile, StandardCharsets.UTF_8)) {
                writer.write(rendered);
            }
            System.out.println("Projected generated outlet asset: " + entry.outputFile.getAbsolutePath());
        }
    }

    private void collectTemplates(File cartridgeRoot, File dir, File outputBase,
                                   List<TemplateEntry> entries) {
        File[] children = dir.listFiles();
        if (children == null) {
            return;
        }
        for (File child : children) {
            if (child.isDirectory()) {
                collectTemplates(cartridgeRoot, child, new File(outputBase, child.getName()), entries);
            } else if (child.getName().endsWith(".ftl")) {
                String templateName = cartridgeRoot.toURI().relativize(child.toURI()).getPath();
                String outputFilename = child.getName().substring(0, child.getName().length() - ".ftl".length());
                entries.add(new TemplateEntry(templateName, new File(outputBase, outputFilename)));
            }
        }
    }

    // Templates access all flags via the `flags` object (e.g. flags.enableRateLimiter).
    // Some templates also use top-level convenience booleans for enableX flags.
    private Map<String, Object> buildContext(BridgeSchemaModel model) {
        Map<String, Object> context = new HashMap<>();
        context.put("id", model.getId());
        context.put("basePath", model.getBasePath());
        context.put("flags", model.getFlags());
        context.put("endpoints", model.getEndpoints());
        context.put("feFlavor", resolvedFeFlavor(model));
        context.put("backendFlavor", resolvedBeFlavor(model));
        context.put("deployTarget", resolvedDeployTarget(model));
        context.put("enableRateLimiter", resolvedFlag(model, f -> f.isEnableRateLimiter()));
        context.put("enableTransform", resolvedFlag(model, f -> f.isEnableTransform()));
        context.put("apiVersion", resolvedString(model, f -> f.getApiVersion()));
        context.put("enableHealthCheck", resolvedFlag(model, f -> f.isEnableHealthCheck()));
        context.put("enableSearch", resolvedFlag(model, f -> f.isEnableSearch()));
        context.put("enableOfflineSupport", resolvedFlag(model, f -> f.isEnableOfflineSupport()));
        context.put("enableOpenApi", resolvedFlag(model, f -> f.isEnableOpenApi()));
        return context;
    }

    private Configuration buildConfiguration(File cartridgeDir) throws IOException {
        String cacheKey = cartridgeDir.getCanonicalPath();
        Configuration cached = configurationCache.get(cacheKey);
        if (cached != null) {
            return cached;
        }
        Configuration cfg = new Configuration(Configuration.VERSION_2_3_32);
        cfg.setDirectoryForTemplateLoading(cartridgeDir);
        cfg.setDefaultEncoding(StandardCharsets.UTF_8.name());
        cfg.setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);
        cfg.setLogTemplateExceptions(false);
        cfg.setWrapUncheckedExceptions(true);
        configurationCache.put(cacheKey, cfg);
        return cfg;
    }

    private File resolveEffectiveOutputDir(File cartridgeDir, File baseOutputDir) {
        File parent = cartridgeDir.getParentFile();
        if (parent != null && OUTPUT_PREFIX_CATEGORIES.contains(parent.getName())) {
            return new File(baseOutputDir, parent.getName());
        }
        return baseOutputDir;
    }

    private String resolvedBeFlavor(BridgeSchemaModel model) {
        if (model.getFlags() != null && model.getFlags().getBackendFlavor() != null) {
            return model.getFlags().getBackendFlavor().toLowerCase();
        }
        return "spring-boot";
    }

    private String resolvedFeFlavor(BridgeSchemaModel model) {
        if (model.getFlags() != null && model.getFlags().getFeFlavor() != null) {
            return model.getFlags().getFeFlavor().toLowerCase();
        }
        return "";
    }

    private String resolvedDeployTarget(BridgeSchemaModel model) {
        if (model.getFlags() != null && model.getFlags().getDeployTarget() != null) {
            return model.getFlags().getDeployTarget().toLowerCase();
        }
        return "";
    }

    private boolean resolvedFlag(BridgeSchemaModel model, Function<BridgeSchemaModel.Flags, Boolean> getter) {
        if (model.getFlags() != null) {
            return getter.apply(model.getFlags());
        }
        return false;
    }

    private String resolvedString(BridgeSchemaModel model, Function<BridgeSchemaModel.Flags, String> getter) {
        if (model.getFlags() != null) {
            String val = getter.apply(model.getFlags());
            return val != null ? val : "";
        }
        return "";
    }

    private static final class TemplateEntry {
        final String templateName;
        final File outputFile;

        TemplateEntry(String templateName, File outputFile) {
            this.templateName = templateName;
            this.outputFile = outputFile;
        }
    }
}
