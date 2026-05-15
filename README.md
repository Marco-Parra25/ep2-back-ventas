# Backend Ventas - API REST Spring Boot

> API REST para gestión de ventas. Parte del proyecto **Innovatech Chile - Evaluación Parcial N°2**

## 📋 Descripción

API REST desarrollada con **Spring Boot 3.x** que proporciona endpoints para la gestión de ventas. Este microservicio se containeriza con Docker y se despliega automáticamente mediante GitHub Actions.

**Características principales:**
- ✅ API REST completa (CRUD operations)
- ✅ Integración con base de datos MySQL
- ✅ Dockerfile multi-stage optimizado
- ✅ Pipeline CI/CD automatizado (GitHub Actions)
- ✅ Usuario sin privilegios en contenedor
- ✅ Health checks configurados

---

## 🛠️ Requisitos

### Desarrollo Local
- **Java 17+** (OpenJDK o similar)
- **Maven 3.8+**
- **Docker & Docker Compose** (opcional, para containerización)
- **Git**

### Runtime en Contenedor
- **Docker 20.10+**
- **Docker Compose 2.0+**
- **Base de datos MySQL** (servicio en docker-compose)

---

## 🚀 Instalación y Ejecución Local

### 1. Clonar el repositorio
```bash
git clone https://github.com/Marco-Parra25/ep2-back-ventas.git
cd ep2-back-ventas
```

### 2. Compilar con Maven
```bash
# Compilar y ejecutar tests
mvn clean package

# Compilar sin tests (desarrollo rápido)
mvn clean package -DskipTests
```

### 3. Ejecutar localmente (sin contenedor)
```bash
# Requiere MySQL corriendo en localhost:3306
mvn spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=dev"
```

### 4. Ejecutar en contenedor (recomendado)

Ver archivo `docker-compose.yml` en el repositorio principal (`ep2-front-despacho`).

```bash
# Desde la raíz del proyecto (donde está el docker-compose.yml)
docker-compose up -d mysql back-ventas
```

---

## 🐳 Contenedorización (Docker)

### Estructura del Dockerfile

El `Dockerfile` usa **multi-stage build** para optimización:

**Stage 1 - Builder:**
```dockerfile
FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder
# ✓ Descarga dependencias (caché de Maven)
# ✓ Compila el código
# ✓ Genera el JAR
```

**Stage 2 - Production:**
```dockerfile
FROM eclipse-temurin:17-jre-alpine AS production
# ✓ Imagen JRE mínima (sin JDK)
# ✓ Usuario no root (seguridad)
# ✓ Health check configurado
```

### Ventajas de este enfoque:
- 📦 **Tamaño reducido**: JRE vs JDK (≈60% menor)
- 🔒 **Seguridad**: Usuario sin privilegios
- 🏥 **Health checks**: Actuator de Spring Boot
- ⚡ **Caché optimizado**: Dependencias separadas del código

### Variables de Entorno (en tiempo de ejecución)

```env
SPRING_PROFILES_ACTIVE=prod
JAVA_OPTS=-Xms256m -Xmx512m
DB_ENDPOINT=mysql
DB_PORT=3306
DB_NAME=innovatech_db
DB_USERNAME=appuser
DB_PASSWORD=apppassword123
```

---

## 🔄 Pipeline CI/CD (GitHub Actions)

### Trigger
**Rama:** `deploy`

Al hacer push a la rama `deploy`, el workflow se ejecuta automáticamente:

```bash
git checkout -b deploy
# ... cambios ...
git push origin deploy
```

### Pasos del Pipeline

1. **Checkout**: Descarga el código del repositorio
2. **Build Docker**: Construye la imagen multi-stage
3. **Push**: Publica la imagen en Docker Hub
4. **Deploy SSH**: Conéctase a EC2 y actualiza el contenedor
5. **Verificación**: Comprueba que el servicio está corriendo

### Archivo del Workflow
Ubicación: `.github/workflows/ci-cd-deploy.yml`

```yaml
on:
  push:
    branches:
      - deploy  # Solo trigger en rama 'deploy'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
      - name: Set up Docker Buildx
      - name: Login to Docker Hub
      - name: Build and push Docker image
      - name: Deploy to EC2
```

---

## 🔐 GitHub Secrets Requeridos

Agrega estos secrets en: `GitHub → Repository Settings → Secrets and variables → Actions`

| Secret | Descripción | Ejemplo |
|--------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `EC2_HOST` | IP pública de la instancia EC2 | `54.123.45.67` |
| `EC2_USER` | Usuario SSH en EC2 | `ubuntu` o `ec2-user` |
| `EC2_SSH_KEY` | Clave privada SSH (multiline) | `-----BEGIN RSA PRIVATE KEY-----...` |

### Obtener AWS Credentials
```bash
# En AWS Academy:
# 1. Ve a AWS Console
# 2. Clic en tu usuario → Security credentials
# 3. Crea Access Key (si no tienes)
# 4. Copia Access Key ID y Secret Access Key
```

### Generar SSH Key para EC2
```bash
# En tu máquina local
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ec2_key

# Copiar la clave privada a GitHub Secrets
cat ~/.ssh/ec2_key  # Copiar TODO el contenido (multiline)

# En EC2, agregar la clave pública a authorized_keys
cat ~/.ssh/ec2_key.pub >> ~/.ssh/authorized_keys
```

---

## 📊 Monitoreo y Verificación

### Health Check
```bash
# En EC2, verificar que el servicio está saludable
curl http://localhost:8082/actuator/health
```

### Logs del Contenedor
```bash
# Ver logs en tiempo real
docker logs -f back_ventas

# Ver logs históricos
docker logs back_ventas | tail -50
```

### Verificar Conexión a BD
```bash
docker exec -it back_ventas curl http://localhost:8082/api/ventas
```

---

## 📝 Estructura del Proyecto

```
ep2-back-ventas/
├── .github/
│   └── workflows/
│       └── ci-cd-deploy.yml      # Pipeline CI/CD
├── src/
│   ├── main/java/com/citt/
│   │   ├── controller/           # Endpoints REST
│   │   ├── service/              # Lógica de negocio
│   │   ├── persistence/          # JPA, Repositories, Entities
│   │   ├── config/               # Configuración (CORS, OpenAPI)
│   │   └── exceptions/           # Manejo de errores
│   └── resources/
│       └── application.properties  # Configuración Spring
├── Dockerfile                    # Multi-stage build
├── pom.xml                       # Dependencias Maven
└── README.md                     # Este archivo
```

---

## 🐛 Troubleshooting

### Error: "Connection refused" a MySQL
**Solución:** Asegúrate que MySQL está corriendo y saludable
```bash
docker-compose ps mysql
docker-compose logs mysql
```

### Error: "Image not found" en Docker Hub
**Solución:** Verifica credenciales de Docker Hub en GitHub Secrets
```bash
docker login
docker push tu-usuario/back-ventas:latest
```

### Pipeline falla en Deploy
**Solución:** Verifica la clave SSH y permisos en EC2
```bash
# En EC2, comprobar que el user puede ejecutar docker
sudo usermod -aG docker ubuntu
```

---

## 🔗 Referencias

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS EC2 Instance Setup](https://docs.aws.amazon.com/ec2/)

---

## 📄 Licencia

Este proyecto es parte de la evaluación **Innovatech Chile - EP2**

**Autores:** Marco Parra, [Compañero]
