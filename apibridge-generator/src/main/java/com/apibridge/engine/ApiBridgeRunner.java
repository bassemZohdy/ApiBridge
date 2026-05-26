package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;

import java.io.File;

/**
 * Command-Line Interface (CLI) Entry Point for ApiBridge Generator.
 */
public class ApiBridgeRunner {

    public static void main(String[] args) {
        long startTime = System.nanoTime();
        
        System.out.println("==================================================");
        System.out.println("  ApiBridge Pluggable MDA Code Generator Engine");
        System.out.println("==================================================");

        String schemaPath = null;
        String cartridgePath = null;
        String outputPath = null;
        String feFlavorOverride = null;
        String beFlavorOverride = null;
        String deployTargetOverride = null;

        for (String arg : args) {
            if (arg.startsWith("--schema=")) {
                schemaPath = arg.substring("--schema=".length());
            } else if (arg.startsWith("--cartridge=")) {
                cartridgePath = arg.substring("--cartridge=".length());
            } else if (arg.startsWith("--output=")) {
                outputPath = arg.substring("--output=".length());
            } else if (arg.startsWith("--fe-flavor=")) {
                feFlavorOverride = arg.substring("--fe-flavor=".length());
            } else if (arg.startsWith("--be-flavor=")) {
                beFlavorOverride = arg.substring("--be-flavor=".length());
            } else if (arg.startsWith("--deploy-target=")) {
                deployTargetOverride = arg.substring("--deploy-target=".length());
            } else if (arg.equals("--help") || arg.equals("-h")) {
                printUsage();
                System.exit(0);
            } else {
                System.err.println("Warning: Unrecognized argument ignored: " + arg);
            }
        }

        if (schemaPath == null || schemaPath.isBlank()) {
            System.err.println("Error: Missing required argument '--schema=<path>'");
            printUsage();
            System.exit(1);
        }
        if (cartridgePath == null || cartridgePath.isBlank()) {
            System.err.println("Error: Missing required argument '--cartridge=<path>'");
            printUsage();
            System.exit(1);
        }
        if (outputPath == null || outputPath.isBlank()) {
            System.err.println("Error: Missing required argument '--output=<path>'");
            printUsage();
            System.exit(1);
        }

        try {
            File schemaFile = new File(schemaPath);
            File cartridgeDir = new File(cartridgePath);
            File outputDir = new File(outputPath);

            System.out.println("Parsing Unified PIM Schema: " + schemaFile.getAbsolutePath());
            YamlParser parser = new YamlParser();
            BridgeSchemaModel model = parser.parse(schemaFile);
            
            System.out.println("Parsed Schema ID  : " + model.getId());
            System.out.println("Parsed Base Path  : " + model.getBasePath());
            System.out.println("Parsed Endpoints  : " + model.getEndpoints().size());

            // Apply CLI overrides (take precedence over schema flags)
            if (model.getFlags() == null) {
                model.setFlags(new com.apibridge.engine.model.BridgeSchemaModel.Flags());
            }
            if (feFlavorOverride != null && !feFlavorOverride.isBlank()) {
                model.getFlags().setFeFlavor(feFlavorOverride);
                System.out.println("FE Flavor Override: " + feFlavorOverride);
            }
            if (beFlavorOverride != null && !beFlavorOverride.isBlank()) {
                model.getFlags().setBackendFlavor(beFlavorOverride);
                System.out.println("BE Flavor Override: " + beFlavorOverride);
            }
            if (deployTargetOverride != null && !deployTargetOverride.isBlank()) {
                model.getFlags().setDeployTarget(deployTargetOverride);
                System.out.println("Deploy Target Override: " + deployTargetOverride);
            }

            if (feFlavorOverride != null || beFlavorOverride != null || deployTargetOverride != null) {
                parser.validate(model);
            }

            System.out.println("Initializing Pluggable Cartridge: " + cartridgeDir.getAbsolutePath());
            ApiBridgeCartridgeEngine engine = new ApiBridgeCartridgeEngine();
            engine.generate(model, cartridgeDir, outputDir);

            long durationNs = System.nanoTime() - startTime;
            double durationMs = durationNs / 1_000_000.0;
            
            System.out.println("==================================================");
            System.out.println("✓ Cartridge Compilation and Projecting SUCCESSFUL!");
            System.out.printf("  Execution Time: %.2f ms\n", durationMs);
            System.out.println("==================================================");

        } catch (Exception e) {
            System.err.println("==================================================");
            System.err.println("❌ CARTRIDGE GENERATION FAILED due to a critical exception:");
            System.err.println("  " + e.getMessage());
            if (e.getCause() != null) {
                System.err.println("  Context: " + e.getCause().getMessage());
            }
            System.err.println("==================================================");
            System.exit(2);
        }
    }

    /**
     * Standard command line usage printout.
     */
    private static void printUsage() {
        System.out.println("\nUsage:");
        System.out.println("  java -jar apibridge-generator.jar --schema=<path> --cartridge=<path> --output=<path> [options]");
        System.out.println("\nRequired:");
        System.out.println("  --schema=<path>      Path to the unified YAML configuration schema (PIM)");
        System.out.println("  --cartridge=<path>   Path to the Cartridge directory containing *.ftl templates");
        System.out.println("  --output=<path>      Path to the output directory for generated artifacts");
        System.out.println("\nOptional overrides (override schema flags):");
        System.out.println("  --fe-flavor=<val>      Frontend framework: angular | react | vue");
        System.out.println("  --be-flavor=<val>      Backend framework: spring-boot | quarkus");
        System.out.println("  --deploy-target=<val>  Deployment config: docker-compose | kubernetes | openshift");
        System.out.println("  -h, --help             Show this help menu\n");
    }
}

