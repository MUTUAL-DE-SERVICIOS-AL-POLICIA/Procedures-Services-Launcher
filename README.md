# Procedures Services Launcher

Launcher para levantar el ecosistema de microservicios con Docker Compose.

## Instalación y arranque

1. Clonar el repositorio:

```sh
git clone https://github.com/MUTUAL-DE-SERVICIOS-AL-POLICIA/Procedures-Services-Launcher.git
```

2. Entrar al directorio
```sh
cd Procedures-Services-Launcher
```

2. Inicializar los submódulos (micro-servicios):

```sh
git submodule update --init --recursive
```

3. Crear el archivo de las variables de entorno raíz:

```sh
cp .env.template .env
```

4. Crear el `.env.compose` de cada microservicio antes de ejecutar Docker:

```sh
cp Gateway-Service/.env.compose.template Gateway-Service/.env.compose
cp Auth-Service/.env.compose.template Auth-Service/.env.compose
cp Beneficiary-Service/.env.compose.template Beneficiary-Service/.env.compose
cp Global-Service/.env.compose.template Global-Service/.env.compose
cp Kiosk-Service/.env.compose.template Kiosk-Service/.env.compose
cp App-Mobile-Service/.env.compose.template App-Mobile-Service/.env.compose
cp Records-Service/.env.compose.template Records-Service/.env.compose
cp Loans-Service/.env.compose.template Loans-Service/.env.compose
cp Contributions-Service/.env.compose.template Contributions-Service/.env.compose
```

5. Editar `.env` (raiz) y cada `.env.compose` (micro-service) con los valores reales del entorno.

La documentacion de cada variable de entorno: [ENVDOC.md](./ENVDOC.md).

6. Ejecutar el comando para construir las imagenes y correr la aplicacion

#### Desarrollo (DEV)

```sh
docker compose build --no-cache && docker compose up
```

#### Producción (PROD)

```sh
docker compose -f docker-compose.prod.yml build --no-cache && docker compose -f docker-compose.prod.yml up -d
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
2. Agregarlo desde la raíz del launcher:

```sh
git submodule add <url-del-repositorio>
```

## Actualizar submódulos

```sh
git submodule update --remote
```
