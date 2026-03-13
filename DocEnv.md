# DocEnv

## Objetivo y alcance

Este documento consolida la documentacion general de variables de entorno del launcher `Procedures-Services-Launcher`, del `Gateway-Service` y de los microservicios que el launcher orquesta. La fuente de verdad usada para este informe es:

- [README.md](./README.md)
- [.env](./.env)
- [.env.template](./.env.template)
- [docker-compose.yml](./docker-compose.yml)
- [docker-compose.prod.yml](./docker-compose.prod.yml)
- Los `README.md`, `src/config/envs.ts`, `src/main.ts` y `src/database/data-source.ts` de cada servicio

El objetivo no es exponer configuracion viva ni secretos operativos. Cuando se hace referencia a valores, estos salen de archivos `template` o `example`.

<a id="indice"></a>
## Índice

- [1. Contexto general y arranque](#contexto-general-y-arranque)
- [2. Cómo se cargan los archivos de entorno](#como-se-cargan-los-archivos-de-entorno)
- [3. Variables del `.env` principal](#variables-del-env-principal)
- [4. `Gateway-Service`](#gateway-service) | [Directorio](./Gateway-Service/) | [README](./Gateway-Service/README.md)
- [5. `Beneficiary-Service`](#beneficiary-service) | [Directorio](./Beneficiary-Service/) | [README](./Beneficiary-Service/README.md)
- [6. `Global-Service`](#global-service) | [Directorio](./Global-Service/) | [README](./Global-Service/README.md)
- [7. `Auth-Service`](#auth-service) | [Directorio](./Auth-Service/) | [README](./Auth-Service/README.md)
- [8. `Kiosk-Service`](#kiosk-service) | [Directorio](./Kiosk-Service/) | [README](./Kiosk-Service/README.md)
- [9. `App-Mobile-Service`](#app-mobile-service) | [Directorio](./App-Mobile-Service/) | [README](./App-Mobile-Service/README.md)
- [10. `Records-Service`](#records-service) | [Directorio](./Records-Service/) | [README](./Records-Service/README.md)
- [11. `Loans-Service`](#loans-service) | [Directorio](./Loans-Service/) | [README](./Loans-Service/README.md)
- [12. `Contributions-Service`](#contributions-service) | [Directorio](./Contributions-Service/) | [README](./Contributions-Service/README.md)

<a id="contexto-general-y-arranque"></a>
## 1. Contexto general y arranque

Este repositorio funciona como launcher del ecosistema. Orquesta el arranque conjunto del servidor NATS y de los servicios NestJS definidos como submodulos Git:

1. `Gateway-Service`
2. `Beneficiary-Service`
3. `Global-Service`
4. `Auth-Service`
5. `Kiosk-Service`
6. `App-Mobile-Service`
7. `Records-Service`
8. `Loans-Service`
9. `Contributions-Service`

### 1.1 Flujo base para levantar el proyecto

Segun [README.md](./README.md), el flujo general es:

```bash
git clone https://github.com/MUTUAL-DE-SERVICIOS-AL-POLICIA/Procedures-Services-Launcher.git
cd Procedures-Services-Launcher
cp .env.template .env
git submodule update --init --recursive
```

Despues de eso, cada servicio debe contar con su propio `.env.compose` a partir de su `.env.compose.template`.

### 1.2 Comandos de ejecución

#### Desarrollo

```bash
docker compose build --no-cache && docker compose up
```

#### Producción

```bash
docker compose -f docker-compose.prod.yml build --no-cache && docker compose -f docker-compose.prod.yml up -d
```

#### Reconstrucción

```bash
# Dev
docker compose up -d --force-recreate

# Prod
docker compose -f docker-compose.prod.yml up -d --force-recreate
```

#### Reconstrucción de un servicio puntual

```bash
# Dev
docker compose up <nombre-servicio> -d --force-recreate

# Prod
docker compose -f docker-compose.prod.yml up <nombre-servicio> -d --force-recreate
```

### 1.3 Diferencias entre `docker-compose.yml` y `docker-compose.prod.yml`

| Aspecto | Desarrollo | Producción |
| --- | --- | --- |
| Archivo principal | [docker-compose.yml](./docker-compose.yml) | [docker-compose.prod.yml](./docker-compose.prod.yml) |
| Nombre de servicios | Usa sufijo `-dev` | Usa nombres sin sufijo |
| Build del gateway y microservicios | `build: ./Servicio` | `build.context` + `dockerfile: dockerfile.prod` |
| Volúmenes bind mount | Sí, monta `./Servicio:/app` y deja `/app/node_modules` aislado | No |
| Comando de arranque | Fuerza `yarn start:dev` | Usa el comando definido por la imagen productiva |
| NATS | Expone `8222` y `4222` | Expone solo `4222` |
| Puerto publicado del gateway | `${CLIENT_GATEWAY_PORT}:3000` | `${CLIENT_GATEWAY_PORT}:3000` |
| Modo típico de ejecución | Primer plano | Segundo plano con `up -d` |

### 1.4 Qué papel cumple cada archivo leído

- [README.md](./README.md): explica el flujo general del launcher, submodulos y comandos de arranque.
- [docker-compose.yml](./docker-compose.yml): define el stack de desarrollo y el orden visible de los servicios.
- [docker-compose.prod.yml](./docker-compose.prod.yml): define el stack productivo y su forma de build.

<a id="como-se-cargan-los-archivos-de-entorno"></a>
## 2. Cómo se cargan los archivos de entorno

### 2.1 Diferencia entre `.env`, `.env.compose`, `.env.template` y `.env.example`

- [`.env`](./.env): archivo operativo del launcher. Centraliza variables compartidas entre contenedores, como base de datos, NATS, ambiente y el puerto publicado del gateway.
- [`.env.template`](./.env.template): plantilla de referencia para crear el `.env` real del launcher.
- `./<Servicio>/.env.compose`: archivo operativo de Compose por servicio. Agrega o sobrescribe variables especificas dentro del contenedor de ese servicio.
- `./<Servicio>/.env.compose.template`: plantilla del archivo anterior.
- `./<Servicio>/.env.template` o `./<Servicio>/.env.example`: referencia para correr un microservicio de forma individual, fuera del launcher Compose.

### 2.2 Precedencia y comportamiento en Docker Compose

Los servicios declarados en [docker-compose.yml](./docker-compose.yml) y [docker-compose.prod.yml](./docker-compose.prod.yml) siguen este patron:

1. Compose parte del `.env` de la raiz para interpolar valores del propio archivo, como `${CLIENT_GATEWAY_PORT}`.
2. En cada servicio, `env_file` inyecta primero [`.env`](./.env) y despues el `./<Servicio>/.env.compose`.
3. Si una misma clave existe en ambos archivos, el valor del `.env.compose` del servicio es el que prevalece dentro del contenedor.
4. Los archivos `./<Servicio>/.env.template` o `./<Servicio>/.env.example` no forman parte del `env_file` del launcher; sirven como referencia para ejecutar el servicio individualmente.

### 2.3 Implicación práctica

- El `.env` de la raiz concentra la configuracion compartida del stack.
- El `.env.compose` aterriza la configuracion propia del servicio.
- Los `template` y `example` no sustituyen al `.env` ni al `.env.compose`; ayudan a recrearlos o a correr servicios fuera del launcher.
- En el estado actual del repo, el inventario de claves de cada `.env.compose` coincide con su respectivo `.env.compose.template`.

### 2.4 Mapa rápido de archivos por servicio

| Servicio | Directorio | Archivo Compose del servicio | Archivo standalone |
| --- | --- | --- | --- |
| `Gateway-Service` | [Abrir](./Gateway-Service/) | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | [.env.template](./Gateway-Service/.env.template) |
| `Beneficiary-Service` | [Abrir](./Beneficiary-Service/) | [.env.compose](./Beneficiary-Service/.env.compose) / [.env.compose.template](./Beneficiary-Service/.env.compose.template) | [.env.template](./Beneficiary-Service/.env.template) |
| `Global-Service` | [Abrir](./Global-Service/) | [.env.compose](./Global-Service/.env.compose) / [.env.compose.template](./Global-Service/.env.compose.template) | [.env.template](./Global-Service/.env.template) |
| `Auth-Service` | [Abrir](./Auth-Service/) | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) | [.env.template](./Auth-Service/.env.template) |
| `Kiosk-Service` | [Abrir](./Kiosk-Service/) | [.env.compose](./Kiosk-Service/.env.compose) / [.env.compose.template](./Kiosk-Service/.env.compose.template) | [.env.template](./Kiosk-Service/.env.template) |
| `App-Mobile-Service` | [Abrir](./App-Mobile-Service/) | [.env.compose](./App-Mobile-Service/.env.compose) / [.env.compose.template](./App-Mobile-Service/.env.compose.template) | [.env.example](./App-Mobile-Service/.env.example) |
| `Records-Service` | [Abrir](./Records-Service/) | [.env.compose](./Records-Service/.env.compose) / [.env.compose.template](./Records-Service/.env.compose.template) | [.env.example](./Records-Service/.env.example) |
| `Loans-Service` | [Abrir](./Loans-Service/) | [.env.compose](./Loans-Service/.env.compose) / [.env.compose.template](./Loans-Service/.env.compose.template) | [.env.example](./Loans-Service/.env.example) |
| `Contributions-Service` | [Abrir](./Contributions-Service/) | [.env.compose](./Contributions-Service/.env.compose) / [.env.compose.template](./Contributions-Service/.env.compose.template) | [.env.example](./Contributions-Service/.env.example) |

<a id="variables-del-env-principal"></a>
## 3. Variables del `.env` principal

Referencias: [.env](./.env) | [.env.template](./.env.template) | [docker-compose.yml](./docker-compose.yml) | [docker-compose.prod.yml](./docker-compose.prod.yml)

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `CLIENT_GATEWAY_PORT` | Launcher | [.env](./.env) / [.env.template](./.env.template) | Se interpola en [docker-compose.yml](./docker-compose.yml) y [docker-compose.prod.yml](./docker-compose.prod.yml) para publicar `${CLIENT_GATEWAY_PORT}:3000`. | Define el puerto host desde el que se expone el gateway al cliente. | Sí para Compose | No la consume el codigo interno del gateway; su efecto es externo al contenedor. |
| `DB_PASSWORD` | Launcher compartido | [.env](./.env) / [.env.template](./.env.template) | Entra por `env_file` a gateway y a los microservicios con TypeORM; luego se usa en los `data-source.ts`. | Entrega la credencial de acceso a PostgreSQL. | Sí operativamente para servicios con BD | No existe una validacion central en el launcher; la obligatoriedad real depende de cada servicio. |
| `DB_DATABASE` | Launcher compartido | [.env](./.env) / [.env.template](./.env.template) | Entra a los servicios que usan TypeORM y alimenta `DbEnvs.dbDatabase`. | Indica la base de datos física a la que se conectan los servicios. | Sí operativamente para servicios con BD | Se comparte entre varios servicios; cada uno puede aislarse por `DB_SCHEMA`. |
| `DB_HOST` | Launcher compartido | [.env](./.env) / [.env.template](./.env.template) | Entra a gateway y microservicios; luego se usa como host de PostgreSQL. | Apunta al servidor de base de datos del ecosistema. | Sí operativamente para servicios con BD | En `Gateway-Service` y `Kiosk-Service` el `data-source` lo lee con `process.env.DB_HOST` directo. |
| `DB_PORT` | Launcher compartido | [.env](./.env) / [.env.template](./.env.template) | Alimenta `DbEnvs.dbPort` o conversiones numericas equivalentes en los `data-source.ts`. | Define el puerto TCP de PostgreSQL. | Sí operativamente para servicios con BD | El template raiz usa un valor de referencia distinto al `.env` operativo; este documento no replica el valor vivo. |
| `DB_USERNAME` | Launcher compartido | [.env](./.env) / [.env.template](./.env.template) | Se propaga a todos los `data-source.ts` de servicios con BD. | Define el usuario con el que los servicios autentican contra PostgreSQL. | Sí operativamente para servicios con BD | En varios servicios se usa aunque Joi no la marque como requerida. |
| `DB_SYNCHRONIZE` | Launcher compartido | [.env](./.env) / [.env.template](./.env.template) | Se transforma a booleano en la mayoria de `src/config/envs.ts` y luego alimenta `synchronize` en TypeORM. | Controla si TypeORM sincroniza el esquema automaticamente al arrancar. | No siempre; depende del servicio | En el gateway se inyecta, pero el `data-source` actual no la usa. |
| `NATS_SERVERS` | Launcher compartido | [.env](./.env) / [.env.template](./.env.template) | Se divide por coma en los `envs.ts` y se usa en los `main.ts` para conectar a NATS. | Permite la comunicacion asincrona entre gateway y microservicios. | Sí operativamente para servicios NATS | Es una de las claves mas compartidas del stack. |
| `ENVIRONMENT` | Launcher compartido | [.env](./.env) / [.env.template](./.env.template) | La consume el gateway para habilitar o deshabilitar Swagger. | Controla el comportamiento de arranque del gateway segun ambiente. | Sí en `Gateway-Service` | Actualmente no es una variable de uso general en todos los microservicios. |

<a id="gateway-service"></a>
## 4. `Gateway-Service`

Referencias: [Directorio](./Gateway-Service/) | [README](./Gateway-Service/README.md)

Archivos técnicos: [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) | [src/main.ts](./Gateway-Service/src/main.ts) | [src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts)

El gateway es la puerta de entrada HTTP del ecosistema. Expone APIs REST, habilita CORS, levanta Swagger en `dev`, conecta al bus NATS y concentra integraciones con PVT, FTP, SMS, WhatsApp y ciudadania digital.

### 4.1 Variables heredadas del `.env` raíz

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `CLIENT_GATEWAY_PORT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [docker-compose.yml](./docker-compose.yml) y [docker-compose.prod.yml](./docker-compose.prod.yml) para mapear el puerto del host hacia el `PORT` interno del gateway. | Hace visible el gateway para clientes externos. | Sí para Compose | Es distinta de `PORT`: `CLIENT_GATEWAY_PORT` es externa; `PORT` es interna al servicio. |
| `ENVIRONMENT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | La publica [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) y la usa [src/main.ts](./Gateway-Service/src/main.ts). | Activa Swagger en `dev` y lo desactiva en `prod`. | Sí en Joi | Es la variable de ambiente mas importante para el arranque del gateway. |
| `NATS_SERVERS` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se valida en [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) y se usa en [src/main.ts](./Gateway-Service/src/main.ts). | Conecta el gateway al bus NATS para hablar con los microservicios. | Sí en Joi | Se separa por comas antes de validarse. |
| `DB_PASSWORD` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | La exporta [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) y la usa [src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts). | Permite autenticacion a PostgreSQL. | Sí en Joi | Aplica solo a la parte del gateway que usa TypeORM. |
| `DB_DATABASE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts). | Selecciona la base de datos que consulta el gateway. | Sí en Joi | Se comparte con otros servicios del stack. |
| `DB_HOST` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts). | Apunta al servidor PostgreSQL. | Sí en Joi | El `data-source` lo lee con `process.env.DB_HOST` directo. |
| `DB_PORT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts). | Define el puerto TCP de PostgreSQL. | Sí en Joi | El servicio lo convierte a numero antes de usarlo. |
| `DB_USERNAME` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts). | Define el usuario de acceso a la base de datos. | Sí en Joi | Sigue el patron comun del resto de servicios. |
| `DB_SYNCHRONIZE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se inyecta al contenedor, pero el `data-source` del gateway no la usa. | En teoria serviria para controlar sincronizacion del esquema. | No en el estado actual | El gateway fija `synchronize: true` y `schema: 'public'` de forma hardcodeada. |

### 4.2 Puerto interno, ambiente y CORS

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `PORT` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) / [.env.template](./Gateway-Service/.env.template) | Se valida y luego se usa en [src/main.ts](./Gateway-Service/src/main.ts) con `app.listen(PortEnvs.port)`. | Define el puerto interno del proceso Node dentro del contenedor. | Sí en Joi | No debe confundirse con `CLIENT_GATEWAY_PORT`. |
| `FRONTENDS_SERVERS` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) / [.env.template](./Gateway-Service/.env.template) | Se valida en [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) y alimenta `app.enableCors()` en [src/main.ts](./Gateway-Service/src/main.ts). | Lista de orígenes que pueden consumir el gateway por CORS. | Sí en Joi | Se divide por comas. |

### 4.3 Integración PVT

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `PVT_BE_API_SERVER` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) / [.env.template](./Gateway-Service/.env.template) | Se exporta desde [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) y se usa desde controladores PVT del gateway. | Define la URL base de la API PVT BE y permite el enrutamiento hacia ese backend. | Sí operativamente | Joi no valida este nombre real; valida `PVT_API_SERVER`, lo cual deja una discrepancia con el código. |
| `PVT_BACKEND_API_SERVER` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) / [.env.template](./Gateway-Service/.env.template) | Se exporta desde [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) y se usa en controladores PVT STI y kiosk. | Define la URL base del backend PVT STI. | Sí operativamente | Igual que el caso anterior, el nombre usado por el código no coincide con el validado por Joi. |
| `PVT_HASH_SECRET` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) / [.env.template](./Gateway-Service/.env.template) | Se usa desde [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) y en el guard de hash PVT. | Sirve para firmar o validar tokens/hash usados en integraciones PVT. | Sí en Joi | Es una clave sensible y no debe documentarse con valores reales. |

### 4.4 FTP, mensajería y proveedores externos

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `FTP_HOST` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se expone en [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) y la usa [src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts). | Indica el servidor FTP al que el gateway se conecta para archivos. | Útil/operativa, no validada formalmente | El `.env.template` standalone del gateway no la trae. |
| `FTP_USERNAME` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se usa en [src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts). | Define el usuario de acceso al FTP. | Útil/operativa, no validada formalmente | Solo aparece en archivos Compose del gateway. |
| `FTP_PASSWORD` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se usa en [src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts). | Permite autenticacion en el servidor FTP. | Útil/operativa, no validada formalmente | Valor sensible. |
| `FTP_ROOT` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se usa en [src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts). | Define el directorio raiz remoto para operaciones de archivos. | Útil/operativa, no validada formalmente | Aporta contexto al resolver rutas relativas. |
| `FTP_SSL` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se usa en [src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts). | Habilita o deshabilita TLS para la conexion FTP. | Útil/operativa, no validada formalmente | El código la consume como flag booleano. |
| `SMS_SERVER_URL` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se consume en [src/common/services/sms.service.ts](./Gateway-Service/src/common/services/sms.service.ts). | Define la URL del proveedor o servidor de SMS. | Útil/operativa, no validada formalmente | Sin esta variable la integración SMS pierde destino. |
| `SMS_SERVER_ROOT` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se usa en [src/common/services/sms.service.ts](./Gateway-Service/src/common/services/sms.service.ts). | Completa la ruta base del API de SMS. | Útil/operativa, no validada formalmente | Complementa a `SMS_SERVER_URL`. |
| `SMS_SERVER_PASSWORD` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se usa en [src/common/services/sms.service.ts](./Gateway-Service/src/common/services/sms.service.ts). | Permite autenticarse contra el proveedor de SMS. | Útil/operativa, no validada formalmente | Valor sensible. |
| `SMS_PROVIDER` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se usa en [src/common/services/sms.service.ts](./Gateway-Service/src/common/services/sms.service.ts). | Identifica el tipo o proveedor de SMS que debe usarse. | Útil/operativa, no validada formalmente | Ayuda a seleccionar comportamiento segun el proveedor. |
| `WHATSAPP_SERVER_URL` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se usa en [src/common/services/whatsapp.service.ts](./Gateway-Service/src/common/services/whatsapp.service.ts). | Define la URL base del integrador de WhatsApp. | Útil/operativa, no validada formalmente | Solo aparece en los archivos Compose del gateway. |

### 4.5 Ciudadanía digital

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `CITIZENSHIP_DIGITAL_CLIENT_URL` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | Se expone en [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) y la usa el servicio de ciudadania digital. | Define la URL del proveedor OAuth externo. | Útil/operativa, no validada formalmente | Solo está en los archivos Compose del gateway. |
| `CITIZENSHIP_DIGITAL_CLIENT_ID` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | La usa la integracion OAuth del gateway. | Identifica al cliente registrado ante el proveedor de ciudadania digital. | Útil/operativa, no validada formalmente | Valor sensible a nivel de integración. |
| `CITIZENSHIP_DIGITAL_REDIRECT_URI` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | La usa la integracion OAuth del gateway. | Define a qué URL regresa el flujo de autenticación externa. | Útil/operativa, no validada formalmente | Debe ser coherente con la configuración del proveedor. |
| `CITIZENSHIP_DIGITAL_SCOPES` | Propia del gateway | [.env.compose](./Gateway-Service/.env.compose) / [.env.compose.template](./Gateway-Service/.env.compose.template) | La usa la integracion OAuth del gateway. | Determina qué permisos o claims se solicitan al proveedor. | Útil/operativa, no validada formalmente | Suele ser una cadena separada por espacios o comas, segun el proveedor. |

### 4.6 Observaciones del gateway

- `CLIENT_GATEWAY_PORT` pertenece al launcher y expone el servicio hacia el host; `PORT` es el puerto interno del proceso NestJS.
- El `data-source` del gateway no sigue el mismo patrón que otros servicios: fija `synchronize: true` y `schema: 'public'`, por eso `DB_SYNCHRONIZE` no aporta efecto real hoy.
- En [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) Joi valida `PVT_API_SERVER`, pero el código exporta y consume `PVT_BE_API_SERVER` y `PVT_BACKEND_API_SERVER`.
- El archivo standalone [Gateway-Service/.env.template](./Gateway-Service/.env.template) cubre el arranque básico, pero deja fuera varias integraciones que sí aparecen en [Gateway-Service/.env.compose.template](./Gateway-Service/.env.compose.template).

<a id="beneficiary-service"></a>
## 5. `Beneficiary-Service`

Referencias: [Directorio](./Beneficiary-Service/) | [README](./Beneficiary-Service/README.md)

Archivos técnicos: [src/config/envs.ts](./Beneficiary-Service/src/config/envs.ts) | [src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts)

Este microservicio trabaja con afiliados, personas, documentos y expedientes. Además de la base de datos y NATS, depende de rutas FTP para ubicar huellas, documentos y dossiers.

### 5.1 Variables heredadas del `.env` raíz

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `NATS_SERVERS` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se valida en [src/config/envs.ts](./Beneficiary-Service/src/config/envs.ts) y se usa en el arranque del servicio. | Permite que el microservicio reciba y procese mensajes por NATS. | Sí en Joi | También aparece como referencia en [.env.template](./Beneficiary-Service/.env.template). |
| `DB_PASSWORD` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts). | Autentica la conexion de TypeORM a PostgreSQL. | Sí en Joi | Forma parte del bloque DB compartido por el launcher. |
| `DB_DATABASE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts). | Selecciona la base de datos física usada por el servicio. | Sí en Joi | Se complementa con `DB_SCHEMA`. |
| `DB_HOST` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts). | Define el host PostgreSQL del servicio. | Sí en Joi | Comparte origen con el resto del stack. |
| `DB_PORT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts). | Define el puerto del servidor PostgreSQL. | Sí en Joi | El servicio lo consume como numero. |
| `DB_USERNAME` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts). | Define el usuario de conexión. | Sí en Joi | Mantiene el mismo patrón del resto de servicios más estrictos. |
| `DB_SYNCHRONIZE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se normaliza en [src/config/envs.ts](./Beneficiary-Service/src/config/envs.ts) y luego se usa en [src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts). | Controla la sincronización automática del esquema TypeORM. | No; tiene default `false` | Aporta al arranque, pero no obliga a definir la variable si se acepta el default. |

### 5.2 Variables propias del servicio

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `DB_SCHEMA` | Propia del servicio | [.env.compose](./Beneficiary-Service/.env.compose) / [.env.compose.template](./Beneficiary-Service/.env.compose.template) / [.env.template](./Beneficiary-Service/.env.template) | Se expone en [src/config/envs.ts](./Beneficiary-Service/src/config/envs.ts) y se usa en [src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts). | Aísla las tablas del servicio dentro de un esquema de PostgreSQL. | No; tiene default `beneficiaries` | En plantilla standalone aparece repetida dos veces. |
| `PATH_FTP_FINGERPRINTS` | Propia del servicio | [.env.compose](./Beneficiary-Service/.env.compose) / [.env.compose.template](./Beneficiary-Service/.env.compose.template) / [.env.template](./Beneficiary-Service/.env.template) | La consume la logica de personas para resolver huellas. | Indica dónde buscar o guardar huellas dactilares en FTP. | Útil/operativa, no validada formalmente | Se usa, pero Joi no la valida. |
| `PATH_FTP_DOCUMENTS` | Propia del servicio | [.env.compose](./Beneficiary-Service/.env.compose) / [.env.compose.template](./Beneficiary-Service/.env.compose.template) / [.env.template](./Beneficiary-Service/.env.template) | La consumen servicios de afiliados y seeders. | Ubica documentos de afiliados en FTP. | Útil/operativa, no validada formalmente | Se usa, pero Joi no la valida. |
| `PATH_FTP_FILE_DOSSIERS` | Propia del servicio | [.env.compose](./Beneficiary-Service/.env.compose) / [.env.compose.template](./Beneficiary-Service/.env.compose.template) / [.env.template](./Beneficiary-Service/.env.template) | La consume la lógica de expedientes. | Permite localizar expedientes o dossiers del afiliado. | Útil/operativa, no validada formalmente | Se usa, pero Joi no la valida. |
| `PATH_FTP_IMPORT_DOCUMENTS_PVTBE` | Propia del servicio | [.env.compose](./Beneficiary-Service/.env.compose) / [.env.compose.template](./Beneficiary-Service/.env.compose.template) / [.env.template](./Beneficiary-Service/.env.template) | La consume la lógica de importación desde PVTBE. | Define el origen FTP para documentos importados desde otro backend. | Útil/operativa, no validada formalmente | Se usa, pero Joi no la valida. |

### 5.3 Observaciones del servicio

- `PATH_FTP_*` aporta funcionalidad real al microservicio, pero hoy no está formalmente validada por Joi.
- [.env.template](./Beneficiary-Service/.env.template) repite `DB_SCHEMA`.
- El servicio usa tanto `DB_DATABASE` como `DB_SCHEMA`: la base física es compartida y el aislamiento lógico lo aporta el esquema.

<a id="global-service"></a>
## 6. `Global-Service`

Referencias: [Directorio](./Global-Service/) | [README](./Global-Service/README.md)

Archivos técnicos: [src/config/envs.ts](./Global-Service/src/config/envs.ts) | [src/database/data-source.ts](./Global-Service/src/database/data-source.ts)

Este servicio centraliza tablas o catálogos globales. Su configuración es sencilla: base de datos, NATS y el esquema lógico donde vive.

### 6.1 Variables heredadas del `.env` raíz

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `NATS_SERVERS` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se valida en [src/config/envs.ts](./Global-Service/src/config/envs.ts) y se usa en el arranque del microservicio. | Habilita la comunicación por NATS con el gateway y otros servicios. | Sí en Joi | También figura en [.env.template](./Global-Service/.env.template). |
| `DB_PASSWORD` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Global-Service/src/database/data-source.ts). | Autentica el acceso a PostgreSQL. | Sí en Joi | Comparte origen con el resto del stack. |
| `DB_DATABASE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Global-Service/src/database/data-source.ts). | Selecciona la base física. | Sí en Joi | Se complementa con `DB_SCHEMA`. |
| `DB_HOST` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Global-Service/src/database/data-source.ts). | Define el host de PostgreSQL. | Sí en Joi | Sin ella no hay conexión al motor. |
| `DB_PORT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Global-Service/src/database/data-source.ts). | Define el puerto del motor de BD. | Sí en Joi | Se valida como número. |
| `DB_USERNAME` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Global-Service/src/database/data-source.ts). | Define el usuario de conexión. | Sí en Joi | Sigue el patrón estricto de validación. |
| `DB_SYNCHRONIZE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se transforma a booleano y se usa como `synchronize` en TypeORM. | Controla la sincronización del esquema al arrancar. | No; tiene default `false` | Ayuda al arranque, pero puede omitirse si se acepta el default. |

### 6.2 Variable propia del servicio

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `DB_SCHEMA` | Propia del servicio | [.env.compose](./Global-Service/.env.compose) / [.env.compose.template](./Global-Service/.env.compose.template) / [.env.template](./Global-Service/.env.template) | Se expone en [src/config/envs.ts](./Global-Service/src/config/envs.ts) y se usa en [src/database/data-source.ts](./Global-Service/src/database/data-source.ts). | Separa las tablas del servicio dentro de PostgreSQL. | No; tiene default `global` | El template standalone muestra `DB_SCHEMA=beneficiaries`, pero el código define `global` como default. |

### 6.3 Observaciones del servicio

- Existe una discrepancia clara entre el default del código (`global`) y la referencia del template (`beneficiaries`).
- El servicio no declara un `PORT` propio; su arranque se basa en el transporte NATS y el `app.listen()` sin variable de puerto específica.

<a id="auth-service"></a>
## 7. `Auth-Service`

Referencias: [Directorio](./Auth-Service/) | [README](./Auth-Service/README.md)

Archivos técnicos: [src/config/envs.ts](./Auth-Service/src/config/envs.ts) | [src/database/data-source.ts](./Auth-Service/src/database/data-source.ts)

Este microservicio autentica usuarios, integra LDAP, firma JWT, valida `API_KEY` y mantiene un flujo especial para dispositivos de prueba del canal móvil.

### 7.1 Variables heredadas del `.env` raíz

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `NATS_SERVERS` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se valida en [src/config/envs.ts](./Auth-Service/src/config/envs.ts) y se usa para conectar el servicio al bus NATS. | Permite exponer autenticación vía mensajería al resto del ecosistema. | Sí en Joi | También aparece como referencia en [.env.template](./Auth-Service/.env.template). |
| `DB_PASSWORD` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Auth-Service/src/database/data-source.ts). | Autentica el acceso del servicio a PostgreSQL. | Sí en Joi | Es parte del bloque DB estricto del servicio. |
| `DB_DATABASE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Auth-Service/src/database/data-source.ts). | Selecciona la base física. | Sí en Joi | Se complementa con `DB_SCHEMA`. |
| `DB_HOST` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Auth-Service/src/database/data-source.ts). | Define el host PostgreSQL. | Sí en Joi | Sin ella el `data-source` no puede arrancar. |
| `DB_PORT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Auth-Service/src/database/data-source.ts). | Define el puerto TCP de PostgreSQL. | Sí en Joi | Joi la valida como numérica. |
| `DB_USERNAME` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Auth-Service/src/database/data-source.ts). | Define el usuario de conexión a BD. | Sí en Joi | Comparte patrón con los servicios más estrictos. |
| `DB_SYNCHRONIZE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se transforma a booleano y alimenta `synchronize` en TypeORM. | Permite controlar sincronización automática del esquema. | No; tiene default `false` | Aunque no es obligatoria, sí tiene efecto real en el servicio. |

### 7.2 Variables propias de autenticación, LDAP y seguridad

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `DB_SCHEMA` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | Se usa en [src/database/data-source.ts](./Auth-Service/src/database/data-source.ts). | Aísla las tablas del servicio de autenticación dentro de PostgreSQL. | No; tiene default `beneficiaries` | Aunque se define en archivos, el código ya trae default. |
| `LDAP_AUTHENTICATION` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | Se exporta en [src/config/envs.ts](./Auth-Service/src/config/envs.ts) como bandera de comportamiento LDAP. | Permite activar o desactivar la autenticación real contra LDAP. | Útil/operativa, no validada formalmente | Se usa/exporta, pero Joi no la declara. |
| `LDAP_HOST` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | La usa la estrategia LDAP del servicio. | Define el servidor LDAP contra el que se hará `bind` y búsqueda. | Sí en Joi | Es clave para autenticación corporativa. |
| `LDAP_PORT` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | La usa la estrategia LDAP. | Define el puerto del servidor LDAP. | Sí en Joi | Usualmente será `389` o equivalente. |
| `LDAP_ADMIN_PREFIX` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | La usa la estrategia LDAP para construir el usuario administrador. | Define el prefijo del DN del administrador LDAP. | Sí en Joi | Aporta a la composición del bind administrativo. |
| `LDAP_ADMIN_USERNAME` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | La usa la estrategia LDAP. | Define el usuario administrador de LDAP. | Sí en Joi | Valor sensible. |
| `LDAP_ADMIN_PASSWORD` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | La usa la estrategia LDAP. | Define la credencial del administrador LDAP. | Sí en Joi | Valor sensible. |
| `LDAP_ACCOUNT_PREFIX` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | La usa la estrategia LDAP para construir la cuenta del usuario final. | Ayuda a formar el DN o cuenta buscada. | Sí en Joi | Trabaja junto con `LDAP_ACCOUNT_SUFFIX`. |
| `LDAP_ACCOUNT_SUFFIX` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | La usa la estrategia LDAP. | Define el sufijo del DN o contenedor LDAP. | Sí en Joi | Sin ella la búsqueda LDAP queda incompleta. |
| `LDAP_BASEDN` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | La usa la estrategia LDAP para búsquedas. | Determina el árbol base donde se buscan usuarios. | Sí en Joi | Es una de las variables más importantes de LDAP. |
| `JWT_SECRET` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | La usa el módulo de autenticación para firmar y verificar JWT. | Permite emitir tokens confiables para el ecosistema. | Sí en Joi | Valor sensible; no documentar el real. |
| `API_KEY` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) / [.env.template](./Auth-Service/.env.template) | La consume la lógica de autenticación interna. | Sirve para proteger llamadas internas o integraciones controladas. | No; opcional en Joi | Aunque no es obligatoria, sí tiene uso real cuando se habilita. |
| `USER_TEST_DEVICE` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) | La usa el flujo `auth-app-mobile`. | Identifica un dispositivo de prueba permitido. | No; opcional en Joi | Solo existe en Compose, no en `.env.template` standalone. |
| `USER_TEST_ACCESS` | Propia del servicio | [.env.compose](./Auth-Service/.env.compose) / [.env.compose.template](./Auth-Service/.env.compose.template) | La usa el flujo `auth-app-mobile`. | Habilita o bloquea el acceso especial de pruebas para mobile. | No; default `false` | Solo existe en Compose, no en `.env.template` standalone. |

### 7.3 Observaciones del servicio

- `LDAP_AUTHENTICATION` influye en el comportamiento del servicio, pero no tiene validación Joi explícita.
- `USER_TEST_DEVICE` y `USER_TEST_ACCESS` viven únicamente en los archivos Compose del servicio, no en el `.env.template` standalone.
- La interfaz del archivo [src/config/envs.ts](./Auth-Service/src/config/envs.ts) declara `PVTBE_USERNAME` y `PVTBE_PASSWORD`, pero esas claves no aparecen en los archivos `.env*` revisados ni en exports/consumos efectivos del servicio.

<a id="kiosk-service"></a>
## 8. `Kiosk-Service`

Referencias: [Directorio](./Kiosk-Service/) | [README](./Kiosk-Service/README.md)

Archivos técnicos: [src/config/envs.ts](./Kiosk-Service/src/config/envs.ts) | [src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts)

Este servicio mantiene una configuración pequeña: NATS, base de datos y el esquema lógico de PostgreSQL.

### 8.1 Variables heredadas del `.env` raíz

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `NATS_SERVERS` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se valida en [src/config/envs.ts](./Kiosk-Service/src/config/envs.ts) y conecta el servicio a NATS. | Permite integración asíncrona con el gateway y otros servicios. | Sí en Joi | También está en [.env.template](./Kiosk-Service/.env.template). |
| `DB_PASSWORD` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts). | Autentica la conexión a PostgreSQL. | Sí en Joi | Es parte del bloque DB validado de forma estricta. |
| `DB_DATABASE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts). | Selecciona la base física. | Sí en Joi | Se complementa con `DB_SCHEMA`. |
| `DB_HOST` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts). | Define el host del motor PostgreSQL. | Sí en Joi | El `data-source` lo lee con `process.env.DB_HOST` directo. |
| `DB_PORT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts). | Define el puerto del motor PostgreSQL. | Sí en Joi | El servicio lo castea con `+` antes de usarlo. |
| `DB_USERNAME` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts). | Define el usuario de conexión. | Sí en Joi | Mantiene el patrón estricto del servicio. |
| `DB_SYNCHRONIZE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se normaliza y alimenta `synchronize` en TypeORM. | Controla la sincronización automática del esquema. | No; tiene default `false` | En el template standalone aparece como referencia explícita. |

### 8.2 Variable propia del servicio

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `DB_SCHEMA` | Propia del servicio | [.env.compose](./Kiosk-Service/.env.compose) / [.env.compose.template](./Kiosk-Service/.env.compose.template) / [.env.template](./Kiosk-Service/.env.template) | Se usa en [src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts). | Separa las tablas del servicio dentro de PostgreSQL. | No; tiene default `beneficiaries` | El template standalone usa `public`, mientras el código trae `beneficiaries` como default si no se define. |

### 8.3 Observaciones del servicio

- `DB_HOST` se valida y exporta, pero el `data-source` lo toma con `process.env.DB_HOST` directo.
- Es uno de los servicios con validación Joi más estricta para `DB_*` y `NATS_SERVERS`.

<a id="app-mobile-service"></a>
## 9. `App-Mobile-Service`

Referencias: [Directorio](./App-Mobile-Service/) | [README](./App-Mobile-Service/README.md)

Archivos técnicos: [src/config/envs.ts](./App-Mobile-Service/src/config/envs.ts) | [src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts)

Este servicio comparte el patrón base de NATS y PostgreSQL, pero además conserva variables en su `.env.example` que hoy no están conectadas al código.

### 9.1 Variables heredadas del `.env` raíz

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `NATS_SERVERS` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se valida en [src/config/envs.ts](./App-Mobile-Service/src/config/envs.ts) y se usa para conectar el microservicio a NATS. | Permite la comunicación con el resto del ecosistema. | Sí en Joi | También figura como referencia en [.env.example](./App-Mobile-Service/.env.example). |
| `DB_PASSWORD` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts). | Autentica el acceso a PostgreSQL. | Sí operativamente, no formal en Joi | El servicio la usa aunque Joi no la declare como obligatoria. |
| `DB_DATABASE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts). | Selecciona la base de datos física. | Sí operativamente, no formal en Joi | Se usa junto a `DB_SCHEMA`. |
| `DB_HOST` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts). | Define el host de PostgreSQL. | Sí operativamente, no formal en Joi | Se exporta desde `DbEnvs`, pero no se valida formalmente. |
| `DB_PORT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts). | Define el puerto del motor. | Sí operativamente, no formal en Joi | Joi solo valida `NATS_SERVERS` y `DB_SYNCHRONIZE`. |
| `DB_USERNAME` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts). | Define el usuario de conexión. | Sí operativamente, no formal en Joi | El patrón es operativo, no validado. |
| `DB_SYNCHRONIZE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se transforma a booleano y alimenta `synchronize`. | Controla la sincronización automática del esquema. | No; tiene default `false` | Sí está declarada en Joi. |

### 9.2 Variable propia del servicio

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `DB_SCHEMA` | Propia del servicio | [.env.compose](./App-Mobile-Service/.env.compose) / [.env.compose.template](./App-Mobile-Service/.env.compose.template) / [.env.example](./App-Mobile-Service/.env.example) | Se usa en [src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts). | Permite aislar las tablas del servicio dentro de un esquema de PostgreSQL. | Sí operativamente, no formal en Joi | Se usa y exporta, pero Joi no la declara. |

### 9.3 Variables solo visibles en el archivo standalone

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `PORT` | Solo archivo standalone | [.env.example](./App-Mobile-Service/.env.example) | No se encontró consumo en [src/config/envs.ts](./App-Mobile-Service/src/config/envs.ts) ni en el arranque del servicio. | En teoría serviría para un puerto HTTP local si se implementara. | No | Hoy es una referencia sin efecto real en el código. |
| `FTP_HOST` | Solo archivo standalone | [.env.example](./App-Mobile-Service/.env.example) | No se encontró consumo en el código del servicio. | En teoría identificaría un servidor FTP para archivos. | No | La variable existe en la plantilla, no en el wiring actual. |
| `FTP_USERNAME` | Solo archivo standalone | [.env.example](./App-Mobile-Service/.env.example) | No se encontró consumo en el código del servicio. | En teoría definiría el usuario FTP. | No | Sin uso real detectado. |
| `FTP_PASSWORD` | Solo archivo standalone | [.env.example](./App-Mobile-Service/.env.example) | No se encontró consumo en el código del servicio. | En teoría permitiría autenticación FTP. | No | Valor sensible, pero hoy no participa en el servicio. |
| `FTP_ROOT` | Solo archivo standalone | [.env.example](./App-Mobile-Service/.env.example) | No se encontró consumo en el código del servicio. | En teoría definiría el directorio raíz remoto. | No | Sin uso real detectado. |
| `FTP_SSL` | Solo archivo standalone | [.env.example](./App-Mobile-Service/.env.example) | No se encontró consumo en el código del servicio. | En teoría activaría o desactivaría TLS para FTP. | No | Sin uso real detectado. |

### 9.4 Observaciones del servicio

- `DB_*` y `DB_SCHEMA` se usan realmente en el servicio, pero Joi solo valida `NATS_SERVERS` y `DB_SYNCHRONIZE`.
- El archivo [.env.example](./App-Mobile-Service/.env.example) conserva `PORT` y `FTP_*`, pero no hay wiring efectivo hacia el código actual.

<a id="records-service"></a>
## 10. `Records-Service`

Referencias: [Directorio](./Records-Service/) | [README](./Records-Service/README.md)

Archivos técnicos: [src/config/envs.ts](./Records-Service/src/config/envs.ts) | [src/database/data-source.ts](./Records-Service/src/database/data-source.ts)

Este servicio usa el mismo patrón mínimo que varios microservicios de soporte: NATS, bloque DB compartido y un `DB_SCHEMA` propio.

### 10.1 Variables heredadas del `.env` raíz

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `NATS_SERVERS` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se expone en [src/config/envs.ts](./Records-Service/src/config/envs.ts) y conecta el servicio a NATS. | Permite que el servicio participe en la mensajería del ecosistema. | Operativa, no formalmente requerida en Joi | Joi la declara, pero sin `.required()`. |
| `DB_PASSWORD` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Records-Service/src/database/data-source.ts). | Autentica la conexión a PostgreSQL. | Sí operativamente, no formal en Joi | El servicio la usa aunque Joi no la exige. |
| `DB_DATABASE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Records-Service/src/database/data-source.ts). | Selecciona la base física del servicio. | Sí operativamente, no formal en Joi | Se complementa con `DB_SCHEMA`. |
| `DB_HOST` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Records-Service/src/database/data-source.ts). | Define el host PostgreSQL. | Sí operativamente, no formal en Joi | Forma parte del bloque DB usado, no validado. |
| `DB_PORT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Records-Service/src/database/data-source.ts). | Define el puerto del motor. | Sí operativamente, no formal en Joi | Joi no la declara. |
| `DB_USERNAME` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Records-Service/src/database/data-source.ts). | Define el usuario de conexión. | Sí operativamente, no formal en Joi | Igual que el resto del bloque DB. |
| `DB_SYNCHRONIZE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se transforma a booleano y se usa como `synchronize`. | Controla la sincronización del esquema en TypeORM. | No; tiene default `false` | Sí está declarada formalmente en Joi. |

### 10.2 Variable propia del servicio

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `DB_SCHEMA` | Propia del servicio | [.env.compose](./Records-Service/.env.compose) / [.env.compose.template](./Records-Service/.env.compose.template) / [.env.example](./Records-Service/.env.example) | Se usa en [src/database/data-source.ts](./Records-Service/src/database/data-source.ts). | Separa las tablas del servicio dentro de PostgreSQL. | Sí operativamente, no formal en Joi | Vive en Compose y en `.env.example`, pero Joi no la valida. |

### 10.3 Observaciones del servicio

- `NATS_SERVERS` existe en Joi, pero no está marcada con `.required()`.
- `DB_*` y `DB_SCHEMA` se usan en runtime aunque el esquema Joi no los obligue.
- El `.env.example` y el `.env.compose.template` usan espacios alrededor de `=`, lo cual conviene conservar solo como estilo de ejemplo, no como estándar obligatorio.

<a id="loans-service"></a>
## 11. `Loans-Service`

Referencias: [Directorio](./Loans-Service/) | [README](./Loans-Service/README.md)

Archivos técnicos: [src/config/envs.ts](./Loans-Service/src/config/envs.ts) | [src/database/data-source.ts](./Loans-Service/src/database/data-source.ts)

Este servicio replica el patrón básico de servicios que solo necesitan NATS, acceso a PostgreSQL y el esquema lógico donde persistir sus datos.

### 11.1 Variables heredadas del `.env` raíz

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `NATS_SERVERS` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se valida en [src/config/envs.ts](./Loans-Service/src/config/envs.ts) y conecta el servicio a NATS. | Permite exponer operaciones del servicio vía mensajería. | Sí en Joi | También está en [.env.example](./Loans-Service/.env.example). |
| `DB_PASSWORD` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Loans-Service/src/database/data-source.ts). | Autentica la conexión a PostgreSQL. | Sí operativamente, no formal en Joi | El servicio la usa, pero Joi no la exige. |
| `DB_DATABASE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Loans-Service/src/database/data-source.ts). | Selecciona la base física del servicio. | Sí operativamente, no formal en Joi | Se complementa con `DB_SCHEMA`. |
| `DB_HOST` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Loans-Service/src/database/data-source.ts). | Define el host PostgreSQL. | Sí operativamente, no formal en Joi | Joi no la declara. |
| `DB_PORT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Loans-Service/src/database/data-source.ts). | Define el puerto del motor. | Sí operativamente, no formal en Joi | El `data-source` la consume sin validación estricta. |
| `DB_USERNAME` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Loans-Service/src/database/data-source.ts). | Define el usuario de conexión. | Sí operativamente, no formal en Joi | Sigue el patrón operativo no validado. |
| `DB_SYNCHRONIZE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se transforma a booleano y alimenta `synchronize`. | Controla la sincronización automática del esquema. | No; tiene default `false` | Sí está contemplada por Joi. |

### 11.2 Variable propia del servicio

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `DB_SCHEMA` | Propia del servicio | [.env.compose](./Loans-Service/.env.compose) / [.env.compose.template](./Loans-Service/.env.compose.template) / [.env.example](./Loans-Service/.env.example) | Se usa en [src/database/data-source.ts](./Loans-Service/src/database/data-source.ts). | Aísla las tablas del servicio dentro de PostgreSQL. | Sí operativamente, no formal en Joi | Vive en archivos de entorno, pero Joi no la declara. |

### 11.3 Observaciones del servicio

- Joi solo marca `NATS_SERVERS` y `DB_SYNCHRONIZE`; el resto del bloque `DB_*` y `DB_SCHEMA` se usa en runtime sin validación estricta.
- [.env.example](./Loans-Service/.env.example) usa espacios alrededor de `=`, lo que conviene entender como estilo de ejemplo.

<a id="contributions-service"></a>
## 12. `Contributions-Service`

Referencias: [Directorio](./Contributions-Service/) | [README](./Contributions-Service/README.md)

Archivos técnicos: [src/config/envs.ts](./Contributions-Service/src/config/envs.ts) | [src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts)

Este servicio sigue el mismo patrón que `Loans-Service`: depende de NATS, de la base de datos compartida y de un esquema específico dentro de PostgreSQL.

### 12.1 Variables heredadas del `.env` raíz

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `NATS_SERVERS` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se valida en [src/config/envs.ts](./Contributions-Service/src/config/envs.ts) y conecta el servicio a NATS. | Permite intercambio de mensajes con el resto del ecosistema. | Sí en Joi | También está en [.env.example](./Contributions-Service/.env.example). |
| `DB_PASSWORD` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts). | Autentica el acceso del servicio a PostgreSQL. | Sí operativamente, no formal en Joi | Joi no la exige aunque se usa. |
| `DB_DATABASE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts). | Selecciona la base física del servicio. | Sí operativamente, no formal en Joi | Se complementa con `DB_SCHEMA`. |
| `DB_HOST` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts). | Define el host PostgreSQL. | Sí operativamente, no formal en Joi | Forma parte del bloque DB usado, no validado. |
| `DB_PORT` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts). | Define el puerto del motor. | Sí operativamente, no formal en Joi | Joi no la declara. |
| `DB_USERNAME` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se usa en [src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts). | Define el usuario de conexión. | Sí operativamente, no formal en Joi | Igual que el resto del bloque DB. |
| `DB_SYNCHRONIZE` | `.env` principal | [.env](./.env) / [.env.template](./.env.template) | Se transforma a booleano y alimenta `synchronize`. | Controla la sincronización automática del esquema. | No; tiene default `false` | Sí está contemplada por Joi. |

### 12.2 Variable propia del servicio

| Variable | Origen | Dónde se define | Uso / dónde se consume | Para qué sirve / aporte | ¿Requerida? | Observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `DB_SCHEMA` | Propia del servicio | [.env.compose](./Contributions-Service/.env.compose) / [.env.compose.template](./Contributions-Service/.env.compose.template) / [.env.example](./Contributions-Service/.env.example) | Se usa en [src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts). | Aísla las tablas del servicio dentro de PostgreSQL. | Sí operativamente, no formal en Joi | Vive en los archivos de entorno, pero Joi no la valida. |

### 12.3 Observaciones del servicio

- Joi solo marca `NATS_SERVERS` y `DB_SYNCHRONIZE`; `DB_*` y `DB_SCHEMA` quedan como uso operativo no validado.
- [.env.example](./Contributions-Service/.env.example) usa espacios alrededor de `=`, igual que otros servicios similares.

<a id="cierre-general"></a>
## Cierre general

- El patrón predominante del launcher es: `.env` raiz para valores compartidos + `.env.compose` por servicio para detalles propios del contenedor.
- Los archivos `.env.template` y `.env.example` son guías de ejecución individual, no sustitutos del wiring de Compose.
- El gateway es el servicio con mayor densidad de variables y además concentra más discrepancias entre validación Joi y consumo real.
- `Beneficiary-Service` y `Auth-Service` son los servicios con más variables específicas por integraciones adicionales.
- `App-Mobile-Service`, `Loans-Service`, `Contributions-Service` y `Records-Service` muestran un patrón repetido: usan varias `DB_*` en runtime, pero sus `envs.ts` no las validan todas de forma estricta.
