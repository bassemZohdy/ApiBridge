@echo off
setlocal
set SCRIPT_DIR=%~dp0
set JAR=%SCRIPT_DIR%..\apibridge-generator\target\apibridge-generator-0.1.0-SNAPSHOT.jar

if not exist "%JAR%" (
    echo ERROR: JAR not found at %JAR% -- run 'mvn package' first
    exit /b 1
)

java -jar "%JAR%" %*
