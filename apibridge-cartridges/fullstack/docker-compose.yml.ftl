<#if deployTarget == "docker-compose">
services:
  ${id}:
    build:
      context: .
      dockerfile: Dockerfile
    image: ${id}:latest
    ports:
      - "8080:8080"
    environment:
      MOCK_MODE: "false"
      BLOCK_TRAFFIC: "false"
      # JAVA_OPTS: "-Xms128m -Xmx256m"
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
        reservations:
          cpus: "0.25"
          memory: 128M
    healthcheck:
<#if backendFlavor == "spring-boot">
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/actuator/health/liveness"]
<#else>
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/q/health/live"]
</#if>
      interval: 30s
      timeout: 5s
      start_period: 60s
      retries: 3
    restart: unless-stopped
    networks:
      - ${id}-net

networks:
  ${id}-net:
    driver: bridge
</#if>
