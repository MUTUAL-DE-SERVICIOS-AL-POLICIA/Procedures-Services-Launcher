# Procedures Services Launcher

Para levantar el ecosistema de microservicios con Docker Compose.

## Instalación y arranque

1. Clonar el repositorio:

```sh
git clone https://github.com/MUTUAL-DE-SERVICIOS-AL-POLICIA/Procedures-Services-Launcher.git
```

2. Entrar al directorio
```sh
cd Procedures-Services-Launcher
```

3. Inicializar los submódulos (micro-servicios):

```sh
git submodule update --init --recursive
```

4. Crear el archivo `.env` en el proyecto Padre:

```sh
cp .env.template .env
```

6. Crear el `.env.compose` de cada microservicio de `.env.compose.template` a `.env.compose`. Ejecutar en el directorio principal `Procedures-Services-Launcher`
```sh
for template in */.env.compose.template; do
  cp "$template" "${template%.template}"
done
```

7. Editar `.env` (raiz) y cada `.env.compose` (micro-service) con los valores reales del entorno.

Documentación de configuración:

- [Matriz de variables por ambiente](./ENVIRONMENT.md)
- [Configuración reproducible de Keycloak](./KEYCLOAK-CONFIGURATION.md)
- [Checklist para un ambiente de pruebas](./DEPLOYMENT-CHECKLIST.md)
- [Autenticación web y sesiones](./WEB-AUTHENTICATION.md)
- [Variables históricas de los microservicios](./ENVDOC.md)

### Ejecutar el comando para construir las imagenes y correr la aplicacion

#### Desarrollo (DEV)

```sh
docker compose build --no-cache && docker compose up
```

#### Producción (PROD)

El Compose de producción usa el mismo `.env` raíz como configuración compartida. Créalo desde la plantilla y reemplaza todos los ejemplos por valores del ambiente:

```sh
cp .env.template .env
```

Establece `ENVIRONMENT=prod`, `WEB_AUTH_ENABLED=true` y configura los `.env.compose` de cada servicio con sus integraciones productivas. Validar antes de construir:

```sh
docker compose -f docker-compose.prod.yml config --quiet
```

Construir y levantar:

```sh
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d
```

## RECREAR CONTENEDORES

#### RECONSTRUIR TODOS CONTENEDORES

```sh
# DESARROLLO (DEV)
docker compose up -d --force-recreate

# PRODUCCION (PROD)
docker compose -f docker-compose.prod.yml up -d --force-recreate
```

#### RECONSTRUIR UN CONTENEDOR ESPECIFICO
Si cambias el `.env.compose` de un solo servicio, recréalo de forma puntual desde la raíz del launcher.

```sh
# DESARROLLO (DEV)
docker compose up <nombre-servicio> -d --force-recreate

# PRODUCCION (PROD)
docker compose -f docker-compose.prod.yml up <nombre-servicio> -d --force-recreate
```

Reemplaza `gateway-service-dev` o `gateway-service` por el servicio que corresponda.

## Añadir un nuevo microservicio como submódulo

1. Crear el nuevo repositorio.
2. Agregarlo desde la raíz del launcher (Proyecto Padre):

```sh
git submodule add <url-del-repositorio>
```

## Actualizar submódulos

```sh
git submodule update --remote
```
