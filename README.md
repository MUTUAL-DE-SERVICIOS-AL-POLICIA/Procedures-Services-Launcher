# Procedures Services Launcher

Launcher para levantar el ecosistema de microservicios con Docker Compose.

## Instalación y arranque

1. Clonar el repositorio:

```sh
git clone https://github.com/MUTUAL-DE-SERVICIOS-AL-POLICIA/Procedures-Services-Launcher.git
cd Procedures-Services-Launcher
```

2. Inicializar los submódulos:

```sh
git submodule update --init --recursive
```

3. Crear el archivo de entorno raíz:

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

La descripción de cada variable, el orden de carga y qué archivo usa cada servicio está documentado en [ENVDOC.md](./ENVDOC.md).

6. Levantar el entorno en desarrollo:

```sh
docker compose build --no-cache && docker compose up
```

## Producción

Antes de usar producción, revisa igualmente [ENVDOC.md](./ENVDOC.md) y confirma que todos los `.env.compose` estén configurados.

```sh
docker compose -f docker-compose.prod.yml build --no-cache && docker compose -f docker-compose.prod.yml up -d
```

## Recrear contenedores

#### Para recrear todo el entorno (reconstruir todos los contenedores):

```sh
# desarrollo
docker compose up -d --force-recreate

# producción
docker compose -f docker-compose.prod.yml up -d --force-recreate
```

#### Si cambias el `.env.compose` de un solo servicio, recréalo de forma puntual desde la raíz del launcher.

```sh
# desarrollo
docker compose up <nombre-servicio> -d --force-recreate

# producción
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
