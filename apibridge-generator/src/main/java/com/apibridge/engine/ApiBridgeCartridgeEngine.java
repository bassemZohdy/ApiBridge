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
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Core template engine that applies a FreeMarker cartridge against a {@link BridgeSchemaModel}
 * to generate source files. Each cartridge directory is scanned for {@code .ftl} templates;
 * rendered output is written to the target directory, stripping the {@code .ftl} suffix.
 *
 * <p>Cartridges nested under {@code backend/}, {@code frontend/}, or {@code k8s/} directories
 * are automatically prefixed in the output (e.g. {@code backend/spring-boot/Controller.java.ftl}
 * becomes {@code <output>/backend/Controller.java}).</p>
 */
public class ApiBridgeCartridgeEngine {

    private static final String FTL_SUFFIX = ".ftl";
    private static final String DEFAULT_BE_FLAVOR = "spring-boot";

    private static final Map<String, Configuration> CONFIGURATION_CACHE = new ConcurrentHashMap<>();
    private static final Logger LOG = Logger.getLogger(ApiBridgeCartridgeEngine.class.getName());

    private static final Set<String> OUTPUT_PREFIX_CATEGORIES =
            Set.of("backend", "frontend", "k8s");

    public void generate(BridgeSchemaModel model, File cartridgeDir, File outputDir)
            throws IOException, TemplateException {
        if (model == null) {
            throw new IllegalArgumentException("Bridge Schema Model cannot be null.");
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

        LOG.log(Level.INFO, "Discovered {0} blueprint templates inside cartridge: {1}",
                new Object[]{entries.size(), cartridgeDir.getName()});

        Map<String, Object> context = buildContext(model);

        for (TemplateEntry entry : entries) {
            LOG.log(Level.FINE, "Processing blueprint template: {0}", entry.templateName);

            Template template = cfg.getTemplate(entry.templateName);
            StringWriter sw = new StringWriter();
            template.process(context, sw);
            String rendered = sw.toString();

            if (rendered.isBlank()) {
                LOG.log(Level.FINE, "Skipping empty output for: {0}", entry.templateName);
                continue;
            }

            File parentDir = entry.outputFile.getParentFile();
            if (!parentDir.exists() && !parentDir.mkdirs()) {
                throw new IOException("Failed to create output directory: " + parentDir.getAbsolutePath());
            }

            try (Writer writer = new FileWriter(entry.outputFile, StandardCharsets.UTF_8)) {
                writer.write(rendered);
            }
            LOG.log(Level.INFO, "Wrote generated file: {0}", entry.outputFile.getAbsolutePath());
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
            } else if (child.getName().endsWith(FTL_SUFFIX)) {
                String templateName = cartridgeRoot.toURI().relativize(child.toURI()).getPath();
                String outputFilename = child.getName().substring(0, child.getName().length() - FTL_SUFFIX.length());
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
        context.put("enableOidc", resolvedFlag(model, f -> f.isEnableOidc()));
        context.put("oidcIssuerUri", resolvedString(model, f -> f.getOidcIssuerUri()));
        return context;
    }

    private Configuration buildConfiguration(File cartridgeDir) throws IOException {
        String cacheKey = cartridgeDir.getCanonicalPath();
        Configuration cached = CONFIGURATION_CACHE.get(cacheKey);
        if (cached != null) {
            return cached;
        }
        // Keep in sync with freemarker.version in pom.xml when upgrading FreeMarker.
        Configuration cfg = new Configuration(Configuration.VERSION_2_3_32);
        cfg.setDirectoryForTemplateLoading(cartridgeDir);
        cfg.setDefaultEncoding(StandardCharsets.UTF_8.name());
        cfg.setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);
        cfg.setLogTemplateExceptions(false);
        cfg.setWrapUncheckedExceptions(true);
        CONFIGURATION_CACHE.put(cacheKey, cfg);
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
        String val = resolvedString(model, f -> f.getBackendFlavor());
        return val.isEmpty() ? DEFAULT_BE_FLAVOR : val.toLowerCase();
    }

    private String resolvedFeFlavor(BridgeSchemaModel model) {
        String val = resolvedString(model, f -> f.getFeFlavor());
        return val.isEmpty() ? "" : val.toLowerCase();
    }

    private String resolvedDeployTarget(BridgeSchemaModel model) {
        String val = resolvedString(model, f -> f.getDeployTarget());
        return val.isEmpty() ? "" : val.toLowerCase();
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

    private record TemplateEntry(String templateName, File outputFile) {}
}
