<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.apibridge.generated</groupId>
    <artifactId>${id}</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <name>${id?replace("-", " ")?capitalize}</name>
    <description>Generated integration bridge backend for ${id} (Spring Boot)</description>

    <properties>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <spring.boot.version>3.3.0</spring.boot.version>
        <opentelemetry.version>1.38.0</opentelemetry.version>
    </properties>

    <dependencies>
        <!-- Spring Boot Starter Web for API mapping (GraalVM and AOT-compliant) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>${"$"}{spring.boot.version}</version>
        </dependency>

        <!-- Jackson Databind for dynamic payload handling -->
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>2.17.1</version>
        </dependency>

        <!-- Pre-compiled Enterprise Core Shared proxy dependency -->
        <dependency>
            <groupId>com.apibridge</groupId>
            <artifactId>apibridge-enterprise-core</artifactId>
            <version>1.0.0</version>
        </dependency>

        <!-- OpenTelemetry API for programmatic tracing -->
        <#if flags.enableTelemetry>
        <dependency>
            <groupId>io.opentelemetry</groupId>
            <artifactId>opentelemetry-api</artifactId>
            <version>${"$"}{opentelemetry.version}</version>
        </dependency>
        </#if>
    </dependencies>

    <build>
        <plugins>
            <!-- Native compilation support -->
            <plugin>
                <groupId>org.graalvm.buildtools</groupId>
                <artifactId>native-maven-plugin</artifactId>
                <version>0.10.2</version>
                <extensions>true</extensions>
            </plugin>
            <!-- Maven Compiler Plugin -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.13.0</version>
                <configuration>
                    <release>21</release>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
