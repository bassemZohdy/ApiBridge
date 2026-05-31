package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

/**
 * CLI entry point for the ApiBridge code generator. Parses command-line arguments,
 * loads and composes schema files, resolves cartridges, and invokes the template engine.
 *
 * <p>Usage: {@code java -jar apibridge-generator.jar --schema=schema.yaml
 * --cartridge=./cartridges/backend/spring-boot --output=./out}</p>
 */
public class ApiBridgeRunner {

    private static final String BANNER_LINE = "==================================================";

    public static void main(String[] args) {
        long startTime = System.nanoTime();
        
        System.out.println(BANNER_LINE);
        System.out.println("  ApiBridge Pluggable MDA Code Generator Engine");
        System.out.println(BANNER_LINE);

        List<String> schemaPaths = new ArrayList<>();
        List<String> cartridgePaths = new ArrayList<>();
        String outputPath = null;
        String feFlavorOverride = null;
        String beFlavorOverride = null;
        String deployTargetOverride = null;
        String securityLevelOverride = null;

        for (String arg : args) {
            if (arg.startsWith("--schema=")) {
                schemaPaths.add(arg.substring("--schema=".length()));
            } else if (arg.startsWith("--cartridge=")) {
                cartridgePaths.add(arg.substring("--cartridge=".length()));
            } else if (arg.startsWith("--output=")) {
                outputPath = arg.substring("--output=".length());
            } else if (arg.startsWith("--fe-flavor=")) {
                feFlavorOverride = arg.substring("--fe-flavor=".length());
            } else if (arg.startsWith("--be-flavor=")) {
                beFlavorOverride = arg.substring("--be-flavor=".length());
            } else if (arg.startsWith("--deploy-target=")) {
                deployTargetOverride = arg.substring("--deploy-target=".length());
            } else if (arg.startsWith("--security-level=")) {
                securityLevelOverride = arg.substring("--security-level=".length());
            } else if (arg.equals("--version") || arg.equals("-v")) {
                System.out.println("ApiBridge Generator " + getVersion());
                System.exit(0);
            } else if (arg.equals("--help") || arg.equals("-h")) {
                printUsage();
                System.exit(0);
            } else {
                System.err.println("Warning: Unrecognized argument ignored: " + arg);
            }
        }

        if (schemaPaths.isEmpty()) {
            System.err.println("Error: At least one '--schema=<path>' argument is required");
            printUsage();
            System.exit(1);
        }
        if (cartridgePaths.isEmpty()) {
            System.err.println("Error: At least one '--cartridge=<path>' argument is required");
            printUsage();
            System.exit(1);
        }
        if (outputPath == null || outputPath.isBlank()) {
            System.err.println("Error: Missing required argument '--output=<path>'");
            printUsage();
            System.exit(1);
        }

        try {
            File outputDir = new File(outputPath);
            YamlParser parser = new YamlParser();
            List<BridgeSchemaModel> parsedSchemas = new java.util.ArrayList<>();

            for (String sp : schemaPaths) {
                File schemaFile = new File(sp);
                System.out.println("Parsing schema: " + schemaFile.getAbsolutePath());
                parsedSchemas.add(parser.parse(schemaFile));
            }

            BridgeSchemaModel model = new SchemaComposer().compose(parsedSchemas);
            System.out.println("Composed Schema ID  : " + model.getId());
            System.out.println("Composed Base Path  : " + model.getBasePath());
            System.out.println("Composed Endpoints  : " + model.getEndpoints().size());

            // Apply CLI overrides (take precedence over schema flags)
            if (model.getFlags() == null) {
                model.setFlags(new BridgeSchemaModel.Flags());
            }
            applyOverride(feFlavorOverride, "FE Flavor", v -> model.getFlags().setFeFlavor(v));
            applyOverride(beFlavorOverride, "BE Flavor", v -> model.getFlags().setBackendFlavor(v));
            applyOverride(deployTargetOverride, "Deploy Target", v -> model.getFlags().setDeployTarget(v));
            applyOverride(securityLevelOverride, "Security Level", v -> model.getFlags().setSecurityLevel(v));

            parser.validate(model);

            CartridgeResolver resolver = new CartridgeResolver();
            ApiBridgeCartridgeEngine engine = new ApiBridgeCartridgeEngine();
            for (String cartridgePath : cartridgePaths) {
                File cartridgeDir = resolver.resolve(cartridgePath);
                System.out.println("Applying cartridge: " + cartridgeDir.getAbsolutePath());
                engine.generate(model, cartridgeDir, outputDir);
            }

            long durationNs = System.nanoTime() - startTime;
            double durationMs = durationNs / 1_000_000.0;
            
            System.out.println(BANNER_LINE);
            System.out.println("✓ Cartridge Compilation and Projecting SUCCESSFUL!");
            System.out.printf("  Execution Time: %.2f ms\n", durationMs);
            System.out.println(BANNER_LINE);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            System.err.println(BANNER_LINE);
            System.err.println("❌ CARTRIDGE GENERATION INTERRUPTED.");
            System.err.println(BANNER_LINE);
            System.exit(2);
        } catch (Exception e) {
            System.err.println(BANNER_LINE);
            System.err.println("❌ CARTRIDGE GENERATION FAILED due to a critical exception:");
            System.err.println("  " + e.getMessage());
            if (e.getCause() != null) {
                System.err.println("  Context: " + e.getCause().getMessage());
            }
            System.err.println(BANNER_LINE);
            System.exit(2);
        }
    }

    static String getVersion() {
        String v = ApiBridgeRunner.class.getPackage().getImplementationVersion();
        return (v != null && !v.isBlank()) ? v : "unknown";
    }

    private static void applyOverride(String value, String label, Consumer<String> setter) {
        if (value != null && !value.isBlank()) {
            setter.accept(value);
            System.out.println(label + " Override: " + value);
        }
    }

    private static void printUsage() {
        System.out.println("\nUsage:");
        System.out.println("  java -jar apibridge-generator.jar --schema=<path> --cartridge=<path> [--cartridge=<path2>...] --output=<path> [options]");
        System.out.println("\nRequired:");
        System.out.println("  --schema=<path>      Path to a YAML schema (repeatable; schemas are merged in order)");
        System.out.println("  --cartridge=<ref>    Cartridge to apply (repeatable; applied in order). Formats:");
        System.out.println("                         ./local/path           Local filesystem path");
        System.out.println("                         https://host/file.zip  URL to a ZIP archive (cached)");
        System.out.println("                         github:owner/repo[/subpath][@ref]  GitHub archive");
        System.out.println("  --output=<path>      Path to the output directory for generated artifacts");
        System.out.println("\nOptional overrides (override schema flags):");
        System.out.println("  --fe-flavor=<val>      Frontend framework: angular | react | vue");
        System.out.println("  --be-flavor=<val>      Backend framework: spring-boot | quarkus");
        System.out.println("  --deploy-target=<val>  Deployment config: docker-compose | kubernetes | openshift");
        System.out.println("  --security-level=<val> Security mode: bearer-token | apiKey");
        System.out.println("  --version, -v          Print version and exit");
        System.out.println("  -h, --help             Show this help menu\n");
    }
}

