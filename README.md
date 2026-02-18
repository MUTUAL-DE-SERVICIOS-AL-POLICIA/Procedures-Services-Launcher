# PASOS PARA LEVANTAR EL PROYECTO

1. Clonar el repositorio
```sh
git clone https://github.com/MUTUAL-DE-SERVICIOS-AL-POLICIA/Procedures-Services-Launcher.git
``` 
2. Crear el `.env` basado en el .env.template
```sh
cp .env.template .env
``` 
3. Ejecutar el siguiente comando para inicializar los sub-modulos
```sh
git submodule update --init --recursive
``` 
4. En cada proyecto crear `.env.compose` basado en el `.env.compose.template`

6. Ejecutar el comando para construir las imágenes y correr la aplicación
## DEV
```sh
docker compose build --no-cache && docker compose up
```
## PROD
```sh
docker compose -f docker-compose.prod.yml build --no-cache && docker compose -f docker-compose.prod.yml up -d

```

#### Para reconstruir todos contenedores
## dev
```sh
docker compose up -d --force-recreate
```
#### prod
```sh
docker compose -f docker-compose.prod.yml up -d --force-recreate
```
#### Para reconstruir un contenedor especifico
Si se actualiza el `.env.compose` de un servicio ejecutar desde el proyecto padre
#### dev
```sh
docker compose up <nombre-servicio> -d --force-recreate
```
#### prod
```sh
docker compose -f docker-compose.prod.yml up <nombre-servicio> -d --force-recreate
```

## Para añadir un nuevo micro servicio (git submodules)
1. Crear un nuevo repositorio en GitHub
2. Copiar el Url de nuevo repositorio y en la terminal de `Procedures-Services-Launcher` local ejecutar:
```sh
git submodule add <url>
```

# Otros
## Para actualizar los sub modules 
```sh
git submodule update --remote
```
