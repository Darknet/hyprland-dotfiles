# Multi-stage build para Java con Gradle
FROM gradle:8-jdk17 AS builder

WORKDIR /app

# Copiar archivos de configuración de Gradle
COPY build.gradle settings.gradle ./
COPY gradle/ gradle/

# Descargar dependencias (para cache)
RUN gradle dependencies --no-daemon

# Copiar código fuente
COPY src/ src/

# Construir aplicación
RUN gradle build --no-daemon -x test

# Etapa de producción
FROM openjdk:17-jre-slim AS production

# Instalar herramientas necesarias
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario no-root
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

# Copiar JAR desde builder
COPY --from=builder --chown=appuser:appuser /app/build/libs/*.jar app.jar

# Cambiar a usuario no-root
USER appuser

# Exponer puerto
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# JVM options
ENV JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseG1GC -XX:+UseContainerSupport"

# Comando de inicio
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
