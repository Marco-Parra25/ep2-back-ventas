# ─────────────────────────────────────────────
# STAGE 1: build con Maven
# ─────────────────────────────────────────────
FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Copiar el pom.xml primero para cachear dependencias de Maven
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar el código fuente y compilar (sin tests para producción)
COPY src ./src
RUN mvn package -DskipTests -B

# ─────────────────────────────────────────────
# STAGE 2: runtime (JRE mínimo, sin JDK)
# ─────────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine AS production

# Instalar curl para el healthcheck
RUN apk add --no-cache curl

# Crear usuario sin privilegios (no root)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiar solo el JAR generado desde el stage anterior
COPY --from=builder /app/target/*.jar app.jar

# Ajustar permisos
RUN chown appuser:appgroup app.jar

# Variables de entorno con valores por defecto (sobreescribibles en runtime)
ENV SPRING_PROFILES_ACTIVE=prod \
    JAVA_OPTS="-Xms256m -Xmx512m"

# Exponer el puerto del backend
EXPOSE 8082

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8082/actuator/health || exit 1

# Ejecutar como usuario no root
USER appuser

# Entrada con JAVA_OPTS configurable
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
