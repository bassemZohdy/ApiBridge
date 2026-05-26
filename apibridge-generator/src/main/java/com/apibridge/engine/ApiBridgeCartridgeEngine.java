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

/**
 * Pluggable Model-Driven Architecture (MDA) Cartridge Engine.
 * Supports flat cartridges (all templates at root) and subdirectory-routed cartridges
 * where backend-{flavor}/ and frontend-{flavor}/ directories are selected by schema flags.
 */
public class ApiBridgeCartridgeEngine {

    /**
     * Executes single-pass compilation of all applicable templates in the cartridge directory.
     *
     * @param model       Fully validated schema PIM
     * @param cartridgeDir Path to the pluggable Cartridge directory containing templates
     * @param outputDir   Target Outlet directory where generated files will be written
     * @throws IOException       If file access fails
     * @throws TemplateException If template rendering fails
     */
    public void generate(BridgeSchemaModel model, File cartridgeDir, File outputDir) throws IOException, TemplateException {
        if (model == null) {
            throw new IllegalArgumentException("Bridge Schema Model (PIM) cannot be null.");
        }
        if (cartridgeDir == null || !cartridgeDir.exists() || !cartridgeDir.isDirectory()) {
            throw new IllegalArgumentException("Cartridge path must point to a valid, existing directory.");
        }
        if (outputDir == null) {
            throw new IllegalArgumentException("Output directory cannot be null.");
        }

        if (!outputDir.exists() && !outputDir.mkdirs()) {
            throw new IOException("Failed to create target output directory: " + outputDir.getAbsolutePath());
        }

        Configuration cfg = new Configuration(Configuration.VERSION_2_3_32);
        cfg.setDirectoryForTemplateLoading(cartridgeDir);
        cfg.setDefaultEncoding(StandardCharsets.UTF_8.name());
        cfg.setTemplateExceptionHandler(TemplateExceptionHandler.RETHROW_HANDLER);
        cfg.setLogTemplateExceptions(false);
        cfg.setWrapUncheckedExceptions(true);

        String selectedBeFlavor = resolvedBeFlavor(model);
        String selectedFeFlavor = resolvedFeFlavor(model);

        List<TemplateEntry> entries = new ArrayList<>();
        collectTemplates(cartridgeDir, cartridgeDir, outputDir, selectedBeFlavor, selectedFeFlavor, entries);

        if (entries.isEmpty()) {
            throw new IllegalArgumentException("No blueprint template files (*.ftl) found in cartridge: " + cartridgeDir.getAbsolutePath());
        }

        System.out.println("Discovered " + entries.size() + " blueprint templates inside cartridge: " + cartridgeDir.getName());

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

    /**
     * Recursively collects all applicable .ftl templates, applying flavor-directory routing.
     * Directories named backend-{flavor}/ and frontend-{flavor}/ are only entered when the
     * flavor matches the selected BE/FE flavor; their content maps to backend/ and frontend/
     * in the output. All other directories recurse normally.
     */
    private void collectTemplates(File cartridgeRoot, File dir, File outputBase,
                                   String beFlavor, String feFlavor,
                                   List<TemplateEntry> entries) {
        File[] children = dir.listFiles();
        if (children == null) {
            return;
        }
        for (File child : children) {
            if (child.isDirectory()) {
                String dirName = child.getName();
                if (dirName.startsWith("backend-")) {
                    String dirFlavor = dirName.substring("backend-".length());
                    if (!dirFlavor.equalsIgnoreCase(beFlavor)) {
                        continue;
                    }
                    collectTemplates(cartridgeRoot, child, new File(outputBase, "backend"), beFlavor, feFlavor, entries);
                } else if (dirName.startsWith("frontend-")) {
                    String dirFlavor = dirName.substring("frontend-".length());
                    if (!dirFlavor.equalsIgnoreCase(feFlavor)) {
                        continue;
                    }
                    collectTemplates(cartridgeRoot, child, new File(outputBase, "frontend"), beFlavor, feFlavor, entries);
                } else {
                    collectTemplates(cartridgeRoot, child, new File(outputBase, dirName), beFlavor, feFlavor, entries);
                }
            } else if (child.getName().endsWith(".ftl")) {
                String templateName = cartridgeRoot.toURI().relativize(child.toURI()).getPath();
                String outputFilename = child.getName().substring(0, child.getName().length() - ".ftl".length());
                entries.add(new TemplateEntry(templateName, new File(outputBase, outputFilename)));
            }
        }
    }

    /**
     * Builds the FreeMarker context map from the schema model.
     * Exposes all model fields plus top-level feFlavor and backendFlavor shortcuts.
     */
    private Map<String, Object> buildContext(BridgeSchemaModel model) {
        Map<String, Object> context = new HashMap<>();
        context.put("id", model.getId());
        context.put("basePath", model.getBasePath());
        context.put("flags", model.getFlags());
        context.put("endpoints", model.getEndpoints());
        context.put("feFlavor", resolvedFeFlavor(model));
        context.put("backendFlavor", resolvedBeFlavor(model));
        context.put("deployTarget", resolvedDeployTarget(model));
        return context;
    }

    private String resolvedBeFlavor(BridgeSchemaModel model) {
        if (model.getFlags() != null) {
            return model.getFlags().getBackendFlavor().toLowerCase();
        }
        return "spring-boot";
    }

    private String resolvedFeFlavor(BridgeSchemaModel model) {
        if (model.getFlags() != null) {
            return model.getFlags().getFeFlavor().toLowerCase();
        }
        return "react";
    }

    private String resolvedDeployTarget(BridgeSchemaModel model) {
        if (model.getFlags() != null && model.getFlags().getDeployTarget() != null) {
            return model.getFlags().getDeployTarget().toLowerCase();
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
