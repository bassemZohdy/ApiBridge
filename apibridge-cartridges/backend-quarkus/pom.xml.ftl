<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.apibridge.generated</groupId>
    <artifactId>${id}</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <name>${id?replace("-", " ")?capitalize}</name>
    <description>Generated integration bridge backend for ${id} (Quarkus)</description>

    <!-- Quarkus Build Configuration -->
    <properties>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <quarkus.platform.version>3.11.0</quarkus.platform.version>
        <quarkus.platform.group-id>io.quarkus.platform</quarkus.platform.group-id>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>${"$"}{quarkus.platform.group-id}</groupId>
                <artifactId>quarkus-bom</artifactId>
                <version>${"$"}{quarkus.platform.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <!-- Quarkus REST Jackson for dynamic endpoint mappings (GraalVM and AOT-compliant) -->
        <dependency>
            <groupId>io.quarkus</groupId>
            <artifactId>quarkus-rest-jackson</artifactId>
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

        <!-- OpenTelemetry extension for Quarkus -->
        <#if flags.enableTelemetry>
        <dependency>
            <groupId>io.quarkus</groupId>
            <artifactId>quarkus-opentelemetry</artifactId>
        </dependency>
        </#if>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>io.quarkus.platform</groupId>
                <artifactId>quarkus-maven-plugin</artifactId>
                <version>${"$"}{quarkus.platform.version}</version>
                <extensions>true</extensions>
                <executions>
                    <execution>
                        <goals>
                            <goal>build</goal>
                        </goals>
                    </execution>
                </executions>
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
