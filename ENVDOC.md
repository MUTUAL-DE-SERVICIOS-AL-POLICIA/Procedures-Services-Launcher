# ENVDOC

Guia de referencia para las variables de entorno que usa el launcher con Docker Compose.

Este documento no repite el proceso de instalacion del [README.md](./README.md). Aqui se documenta:

- que archivos de entorno carga Docker Compose
- que variable usa cada servicio
- donde se consume en el codigo
- para que sirve
- un ejemplo de valor por variable

Todos los ejemplos son referenciales y no deben copiarse como secretos reales.

## Indice

- [1. Archivos de entorno que intervienen](#1-archivos-de-entorno-que-intervienen)
- [2. Orden de carga en Docker Compose](#2-orden-de-carga-en-docker-compose)
- [2.1 Confirmacion por proyecto](#21-confirmacion-por-proyecto)
- [3. Variables compartidas del `.env` raiz](#3-variables-compartidas-del-env-raiz)
- [4. Variables de `Gateway-Service`](#4-variables-de-gateway-service)
- [5. Variables de `Auth-Service`](#5-variables-de-auth-service)
- [6. Variables de `Beneficiary-Service`](#6-variables-de-beneficiary-service)
- [7. Servicios cuyo `.env.compose` solo define `DB_SCHEMA`](#7-servicios-cuyo-envcompose-solo-define-dbschema)
- [8. Observaciones utiles](#8-observaciones-utiles)

<a id="1-archivos-de-entorno-que-intervienen"></a>
## 1. Archivos de entorno que intervienen

| Archivo | Alcance | Funcion |
| --- | --- | --- |
| `.env` | Launcher completo | Define variables compartidas para el stack y valores interpolados por `docker-compose.yml` y `docker-compose.prod.yml`. |
| `./<Servicio>/.env.compose` | Un microservicio | Define o sobrescribe variables especificas del contenedor de ese servicio. |
| `./<Servicio>/.env.compose.template` | Un microservicio | Sirve como base para crear el `.env.compose` real. |
| `./<Servicio>/.env.example` o `./<Servicio>/.env.template` | Servicio individual | Referencia para ejecutar el microservicio por separado. No es el archivo que usa el `docker compose` raiz. |

<a id="2-orden-de-carga-en-docker-compose"></a>
## 2. Orden de carga en Docker Compose

En `docker-compose.yml` y `docker-compose.prod.yml`, cada microservicio carga:

1. `.env`
2. `./<Servicio>/.env.compose`

Esto implica lo siguiente:

- el `.env` raiz inyecta variables compartidas como `DB_*`, `NATS_SERVERS` y `ENVIRONMENT`
- el `.env.compose` del servicio agrega sus variables propias, por ejemplo `DB_SCHEMA`, LDAP, FTP o integraciones externas
- si una clave existe en ambos archivos, prevalece el valor del `.env.compose` del microservicio dentro del contenedor

<a id="21-confirmacion-por-proyecto"></a>
### 2.1 Confirmacion por proyecto

La secuencia real en casi todos los servicios es:

1. el servicio importa `src/config`
2. eso ejecuta `src/config/envs.ts`
3. `envs.ts` valida, normaliza y exporta `DbEnvs`, `NastEnvs` u otros bloques
4. luego esas constantes se consumen en `src/main.ts`, `src/common/common.module.ts`, `src/database/data-source.ts` o en servicios/controladores

| Servicio | Primera lectura de variables | Despues se consumen en | Confirmacion importante |
| --- | --- | --- | --- |
| `Gateway-Service` | [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) via [src/config/index.ts](./Gateway-Service/src/config/index.ts) | [src/main.ts](./Gateway-Service/src/main.ts)<br>[src/common/common.module.ts](./Gateway-Service/src/common/common.module.ts)<br>[src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts)<br>[src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts)<br>[src/common/services/sms.service.ts](./Gateway-Service/src/common/services/sms.service.ts)<br>[src/common/services/whatsapp.service.ts](./Gateway-Service/src/common/services/whatsapp.service.ts)<br>[src/common/services/citizenshipDigital.service.ts](./Gateway-Service/src/common/services/citizenshipDigital.service.ts)<br>[src/pvt-be/pvt-be.controller.ts](./Gateway-Service/src/pvt-be/pvt-be.controller.ts)<br>[src/pvt-sti/pvt-sti.controller.ts](./Gateway-Service/src/pvt-sti/pvt-sti.controller.ts) | `DB_HOST` se lee directo desde `process.env` en `data-source.ts`; `schema` esta fijo en `public`; `synchronize` esta fijo en `true`. |
| `Auth-Service` | [src/config/envs.ts](./Auth-Service/src/config/envs.ts) via [src/config/index.ts](./Auth-Service/src/config/index.ts) | [src/main.ts](./Auth-Service/src/main.ts)<br>[src/common/common.module.ts](./Auth-Service/src/common/common.module.ts)<br>[src/database/data-source.ts](./Auth-Service/src/database/data-source.ts)<br>[src/auth/strategies/ldap.strategy.ts](./Auth-Service/src/auth/strategies/ldap.strategy.ts)<br>[src/auth/auth.module.ts](./Auth-Service/src/auth/auth.module.ts)<br>[src/auth/auth.service.ts](./Auth-Service/src/auth/auth.service.ts)<br>[src/auth-app-mobile/auth-app-mobile.service.ts](./Auth-Service/src/auth-app-mobile/auth-app-mobile.service.ts) | `main.ts` tiene un arranque HTTP comentado que hoy no se ejecuta; el default Joi de `DB_SCHEMA` es `beneficiaries`, aunque la plantilla del servicio usa `auth`. |
| `Beneficiary-Service` | [src/config/envs.ts](./Beneficiary-Service/src/config/envs.ts) via [src/config/index.ts](./Beneficiary-Service/src/config/index.ts) | [src/main.ts](./Beneficiary-Service/src/main.ts)<br>[src/common/common.module.ts](./Beneficiary-Service/src/common/common.module.ts)<br>[src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts)<br>[src/affiliates/affiliates.service.ts](./Beneficiary-Service/src/affiliates/affiliates.service.ts)<br>[src/persons/persons.service.ts](./Beneficiary-Service/src/persons/persons.service.ts)<br>[src/database/seeds/1738939765121-import_requirements.ts](./Beneficiary-Service/src/database/seeds/1738939765121-import_requirements.ts) | Ademas del bloque DB y NATS, este servicio consume rutas FTP en servicios y seeds. |
| `Global-Service` | [src/config/envs.ts](./Global-Service/src/config/envs.ts) via [src/config/index.ts](./Global-Service/src/config/index.ts) | [src/main.ts](./Global-Service/src/main.ts)<br>[src/common/common.module.ts](./Global-Service/src/common/common.module.ts)<br>[src/database/data-source.ts](./Global-Service/src/database/data-source.ts) | Flujo estandar: Joi valida, `DbEnvs` alimenta `data-source.ts` y `NastEnvs` alimenta NATS. |
| `Kiosk-Service` | [src/config/envs.ts](./Kiosk-Service/src/config/envs.ts) via [src/config/index.ts](./Kiosk-Service/src/config/index.ts) | [src/main.ts](./Kiosk-Service/src/main.ts)<br>[src/common/common.module.ts](./Kiosk-Service/src/common/common.module.ts)<br>[src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts) | `DB_HOST` se lee directo desde `process.env` en `data-source.ts`; el default Joi de `DB_SCHEMA` es `beneficiaries`, no `kiosk`. |
| `App-Mobile-Service` | [src/config/envs.ts](./App-Mobile-Service/src/config/envs.ts) via [src/config/index.ts](./App-Mobile-Service/src/config/index.ts) | [src/main.ts](./App-Mobile-Service/src/main.ts)<br>[src/common/common.module.ts](./App-Mobile-Service/src/common/common.module.ts)<br>[src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts) | Joi solo exige `NATS_SERVERS` y `DB_SYNCHRONIZE`; el resto del bloque DB se exporta igual, pero no se valida como requerido en `envs.ts`. |
| `Records-Service` | [src/config/envs.ts](./Records-Service/src/config/envs.ts) via [src/config/index.ts](./Records-Service/src/config/index.ts) | [src/main.ts](./Records-Service/src/main.ts)<br>[src/common/common.module.ts](./Records-Service/src/common/common.module.ts)<br>[src/database/data-source.ts](./Records-Service/src/database/data-source.ts) | Joi no marca `NATS_SERVERS` como requerido y tampoco valida el bloque DB como requerido, aunque luego `data-source.ts` si lo usa. |
| `Loans-Service` | [src/config/envs.ts](./Loans-Service/src/config/envs.ts) via [src/config/index.ts](./Loans-Service/src/config/index.ts) | [src/main.ts](./Loans-Service/src/main.ts)<br>[src/common/common.module.ts](./Loans-Service/src/common/common.module.ts)<br>[src/database/data-source.ts](./Loans-Service/src/database/data-source.ts) | Joi exige `NATS_SERVERS`, pero no valida como requeridos `DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` ni `DB_SCHEMA`, aunque `data-source.ts` si los usa. |
| `Contributions-Service` | [src/config/envs.ts](./Contributions-Service/src/config/envs.ts) via [src/config/index.ts](./Contributions-Service/src/config/index.ts) | [src/main.ts](./Contributions-Service/src/main.ts)<br>[src/common/common.module.ts](./Contributions-Service/src/common/common.module.ts)<br>[src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts) | Joi exige `NATS_SERVERS`, pero no valida como requerido el bloque DB completo antes de exportarlo en `DbEnvs`. |

<a id="3-variables-compartidas-del-env-raiz"></a>
## 3. Variables compartidas del `.env` raiz

Estas variables no pertenecen a un solo microservicio; se reutilizan en varios contenedores del launcher.

| Variable | Declarada en | Donde se usa | Funcion | Ejemplo |
| --- | --- | --- | --- | --- |
| `CLIENT_GATEWAY_PORT` | [.env.template](./.env.template) | [docker-compose.yml](./docker-compose.yml), [docker-compose.prod.yml](./docker-compose.prod.yml) | Expone el gateway hacia el host en el puerto que abrira el cliente. | `CLIENT_GATEWAY_PORT=3000` |
| `DB_PASSWORD` | [.env.template](./.env.template) | [Gateway-Service/src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts)<br>[Auth-Service/src/database/data-source.ts](./Auth-Service/src/database/data-source.ts)<br>[Beneficiary-Service/src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts)<br>[Global-Service/src/database/data-source.ts](./Global-Service/src/database/data-source.ts)<br>[Kiosk-Service/src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts)<br>[App-Mobile-Service/src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts)<br>[Records-Service/src/database/data-source.ts](./Records-Service/src/database/data-source.ts)<br>[Loans-Service/src/database/data-source.ts](./Loans-Service/src/database/data-source.ts)<br>[Contributions-Service/src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts) | Entrega la contrasena con la que TypeORM se conecta a PostgreSQL. Primero se normaliza en `src/config/envs.ts` de cada servicio y luego llega a `data-source.ts`. | `DB_PASSWORD=123456` |
| `DB_DATABASE` | [.env.template](./.env.template) | [Gateway-Service/src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts)<br>[Auth-Service/src/database/data-source.ts](./Auth-Service/src/database/data-source.ts)<br>[Beneficiary-Service/src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts)<br>[Global-Service/src/database/data-source.ts](./Global-Service/src/database/data-source.ts)<br>[Kiosk-Service/src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts)<br>[App-Mobile-Service/src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts)<br>[Records-Service/src/database/data-source.ts](./Records-Service/src/database/data-source.ts)<br>[Loans-Service/src/database/data-source.ts](./Loans-Service/src/database/data-source.ts)<br>[Contributions-Service/src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts) | Define la base de datos fisica que compartiran los microservicios. Primero se prepara en `envs.ts` y luego se consume en `data-source.ts`. | `DB_DATABASE=microservice3` |
| `DB_HOST` | [.env.template](./.env.template) | [Gateway-Service/src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts)<br>[Auth-Service/src/database/data-source.ts](./Auth-Service/src/database/data-source.ts)<br>[Beneficiary-Service/src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts)<br>[Global-Service/src/database/data-source.ts](./Global-Service/src/database/data-source.ts)<br>[Kiosk-Service/src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts)<br>[App-Mobile-Service/src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts)<br>[Records-Service/src/database/data-source.ts](./Records-Service/src/database/data-source.ts)<br>[Loans-Service/src/database/data-source.ts](./Loans-Service/src/database/data-source.ts)<br>[Contributions-Service/src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts) | Indica el host del servidor PostgreSQL. En casi todos pasa por `DbEnvs.dbHost`, pero en `Gateway-Service` y `Kiosk-Service` `data-source.ts` usa `process.env.DB_HOST` directamente. | `DB_HOST=localhost` |
| `DB_PORT` | [.env.template](./.env.template) | [Gateway-Service/src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts)<br>[Auth-Service/src/database/data-source.ts](./Auth-Service/src/database/data-source.ts)<br>[Beneficiary-Service/src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts)<br>[Global-Service/src/database/data-source.ts](./Global-Service/src/database/data-source.ts)<br>[Kiosk-Service/src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts)<br>[App-Mobile-Service/src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts)<br>[Records-Service/src/database/data-source.ts](./Records-Service/src/database/data-source.ts)<br>[Loans-Service/src/database/data-source.ts](./Loans-Service/src/database/data-source.ts)<br>[Contributions-Service/src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts) | Indica el puerto del servidor PostgreSQL. Primero se transforma en `envs.ts` y luego `data-source.ts` lo usa como numero. | `DB_PORT=5433` |
| `DB_USERNAME` | [.env.template](./.env.template) | [Gateway-Service/src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts)<br>[Auth-Service/src/database/data-source.ts](./Auth-Service/src/database/data-source.ts)<br>[Beneficiary-Service/src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts)<br>[Global-Service/src/database/data-source.ts](./Global-Service/src/database/data-source.ts)<br>[Kiosk-Service/src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts)<br>[App-Mobile-Service/src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts)<br>[Records-Service/src/database/data-source.ts](./Records-Service/src/database/data-source.ts)<br>[Loans-Service/src/database/data-source.ts](./Loans-Service/src/database/data-source.ts)<br>[Contributions-Service/src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts) | Define el usuario con el que cada servicio abre la conexion a PostgreSQL. Primero se exporta desde `DbEnvs` y luego se consume en `data-source.ts`. | `DB_USERNAME=postgres` |
| `DB_SYNCHRONIZE` | [.env.template](./.env.template) | [Auth-Service/src/database/data-source.ts](./Auth-Service/src/database/data-source.ts)<br>[Beneficiary-Service/src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts)<br>[Global-Service/src/database/data-source.ts](./Global-Service/src/database/data-source.ts)<br>[Kiosk-Service/src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts)<br>[App-Mobile-Service/src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts)<br>[Records-Service/src/database/data-source.ts](./Records-Service/src/database/data-source.ts)<br>[Loans-Service/src/database/data-source.ts](./Loans-Service/src/database/data-source.ts)<br>[Contributions-Service/src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts) | Activa o desactiva `synchronize` en TypeORM. El `Gateway-Service` no la consume porque fija `synchronize: true`. | `DB_SYNCHRONIZE=false` |
| `NATS_SERVERS` | [.env.template](./.env.template) | [Gateway-Service/src/main.ts](./Gateway-Service/src/main.ts)<br>[Gateway-Service/src/common/common.module.ts](./Gateway-Service/src/common/common.module.ts)<br>[Auth-Service/src/main.ts](./Auth-Service/src/main.ts)<br>[Auth-Service/src/common/common.module.ts](./Auth-Service/src/common/common.module.ts)<br>[Beneficiary-Service/src/main.ts](./Beneficiary-Service/src/main.ts)<br>[Beneficiary-Service/src/common/common.module.ts](./Beneficiary-Service/src/common/common.module.ts)<br>[Global-Service/src/main.ts](./Global-Service/src/main.ts)<br>[Global-Service/src/common/common.module.ts](./Global-Service/src/common/common.module.ts)<br>[Kiosk-Service/src/main.ts](./Kiosk-Service/src/main.ts)<br>[Kiosk-Service/src/common/common.module.ts](./Kiosk-Service/src/common/common.module.ts)<br>[App-Mobile-Service/src/main.ts](./App-Mobile-Service/src/main.ts)<br>[App-Mobile-Service/src/common/common.module.ts](./App-Mobile-Service/src/common/common.module.ts)<br>[Records-Service/src/main.ts](./Records-Service/src/main.ts)<br>[Records-Service/src/common/common.module.ts](./Records-Service/src/common/common.module.ts)<br>[Loans-Service/src/main.ts](./Loans-Service/src/main.ts)<br>[Loans-Service/src/common/common.module.ts](./Loans-Service/src/common/common.module.ts)<br>[Contributions-Service/src/main.ts](./Contributions-Service/src/main.ts)<br>[Contributions-Service/src/common/common.module.ts](./Contributions-Service/src/common/common.module.ts) | Define la URL o lista de URLs del broker NATS para la comunicacion entre servicios. | `NATS_SERVERS="nats://192.168.2.90:4222"` |
| `ENVIRONMENT` | [.env.template](./.env.template) | [Gateway-Service/src/main.ts](./Gateway-Service/src/main.ts) | Define el ambiente de ejecucion del gateway. En `dev` habilita Swagger. | `ENVIRONMENT=dev` |

<a id="4-variables-de-gateway-service"></a>
## 4. Variables de `Gateway-Service`

Archivo documentado: `Gateway-Service/.env.compose`

Ruta real:

`.env` + `.env.compose` -> [src/config/envs.ts](./Gateway-Service/src/config/envs.ts) -> [src/config/index.ts](./Gateway-Service/src/config/index.ts) -> consumo en [src/main.ts](./Gateway-Service/src/main.ts), [src/common/common.module.ts](./Gateway-Service/src/common/common.module.ts), [src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts) y servicios/controladores.

| Variable | Declarada en | Donde se usa | Funcion | Ejemplo |
| --- | --- | --- | --- | --- |
| `PORT` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/main.ts](./Gateway-Service/src/main.ts) | Puerto interno en el que el proceso NestJS del gateway hace `listen`. | `PORT=3000` |
| `FRONTENDS_SERVERS` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/main.ts](./Gateway-Service/src/main.ts) | Lista separada por comas que se usa en `enableCors` para definir origenes permitidos. | `FRONTENDS_SERVERS="http://localhost:3001,http://localhost:3002"` |
| `PVT_BE_API_SERVER` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/pvt-be/pvt-be.controller.ts](./Gateway-Service/src/pvt-be/pvt-be.controller.ts)<br>[src/kiosk/kiosk.controller.ts](./Gateway-Service/src/kiosk/kiosk.controller.ts) | URL base de la integracion PVT BE. El codigo le concatena `/api/v1`. | `PVT_BE_API_SERVER="http://localhost:8000"` |
| `PVT_BACKEND_API_SERVER` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/pvt-sti/pvt-sti.controller.ts](./Gateway-Service/src/pvt-sti/pvt-sti.controller.ts)<br>[src/kiosk/kiosk.controller.ts](./Gateway-Service/src/kiosk/kiosk.controller.ts) | URL base del backend PVT usado para prestamos, kardex y otras consultas. El codigo le concatena `/api`. | `PVT_BACKEND_API_SERVER="http://localhost:8001"` |
| `PVT_HASH_SECRET` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/auth/guards/hashpvt.guard.ts](./Gateway-Service/src/auth/guards/hashpvt.guard.ts) | Secreto con el que el guard valida el token hash de peticiones PVT. | `PVT_HASH_SECRET="secret"` |
| `FTP_HOST` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts) | Host del servidor FTP al que el gateway sube, descarga, lista y renombra archivos. | `FTP_HOST=192.168.2.100` |
| `FTP_USERNAME` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts) | Usuario con el que el gateway autentica la sesion FTP. | `FTP_USERNAME=test_pruebas` |
| `FTP_PASSWORD` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts) | Contrasena usada para abrir la conexion FTP. | `FTP_PASSWORD=test` |
| `FTP_ROOT` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts) | Ruta raiz sobre la que el gateway construye `upload`, `download`, `list` y `rename`. | `FTP_ROOT="/test_pruebas/"` |
| `FTP_SSL` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/ftp.service.ts](./Gateway-Service/src/common/services/ftp.service.ts) | Indica si la conexion FTP se abre con `secure: true` o `false`. | `FTP_SSL=false` |
| `SMS_SERVER_URL` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/sms.service.ts](./Gateway-Service/src/common/services/sms.service.ts) | URL base del proveedor SMS. Desde aqui se arma la llamada a `dosend.php` y `resend.php`. | `SMS_SERVER_URL="http://172.16.1.20/goip/en/"` |
| `SMS_SERVER_ROOT` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/sms.service.ts](./Gateway-Service/src/common/services/sms.service.ts) | Usuario o identificador que el proveedor SMS espera como `USERNAME`. | `SMS_SERVER_ROOT="root"` |
| `SMS_SERVER_PASSWORD` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/sms.service.ts](./Gateway-Service/src/common/services/sms.service.ts) | Contrasena que el gateway envia al proveedor SMS. | `SMS_SERVER_PASSWORD="TEST1234"` |
| `SMS_PROVIDER` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/sms.service.ts](./Gateway-Service/src/common/services/sms.service.ts) | Identificador del proveedor o canal SMS enviado como `smsprovider`. | `SMS_PROVIDER="1"` |
| `WHATSAPP_SERVER_URL` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/whatsapp.service.ts](./Gateway-Service/src/common/services/whatsapp.service.ts) | URL base del integrador de WhatsApp. El servicio publica a `/whatsapp/send`. | `WHATSAPP_SERVER_URL="http://localhost:3100"` |
| `CITIZENSHIP_DIGITAL_CLIENT_URL` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/citizenshipDigital.service.ts](./Gateway-Service/src/common/services/citizenshipDigital.service.ts) | URL base del proveedor OAuth de ciudadania digital. Se usa para `/token`, `/me` y `session/end`. | `CITIZENSHIP_DIGITAL_CLIENT_URL="https://proveedor.bo"` |
| `CITIZENSHIP_DIGITAL_CLIENT_ID` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/citizenshipDigital.service.ts](./Gateway-Service/src/common/services/citizenshipDigital.service.ts) | Identificador del cliente registrado ante el proveedor de ciudadania digital. | `CITIZENSHIP_DIGITAL_CLIENT_ID="YYYYYYYYYYYYYYYY"` |
| `CITIZENSHIP_DIGITAL_REDIRECT_URI` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/citizenshipDigital.service.ts](./Gateway-Service/src/common/services/citizenshipDigital.service.ts) | Redirect URI usada en el intercambio del `authorization_code`. | `CITIZENSHIP_DIGITAL_REDIRECT_URI="com.app.pvt:/oauth2redirect"` |
| `CITIZENSHIP_DIGITAL_SCOPES` | [.env.compose.template](./Gateway-Service/.env.compose.template) | [src/common/services/citizenshipDigital.service.ts](./Gateway-Service/src/common/services/citizenshipDigital.service.ts) | Lista de scopes que el gateway expone al cliente para el flujo OAuth. | `CITIZENSHIP_DIGITAL_SCOPES="openid profile fecha_nacimiento email celular offline_access"` |

<a id="5-variables-de-auth-service"></a>
## 5. Variables de `Auth-Service`

Archivo documentado: `Auth-Service/.env.compose`

Ruta real:

`.env` + `.env.compose` -> [src/config/envs.ts](./Auth-Service/src/config/envs.ts) -> [src/config/index.ts](./Auth-Service/src/config/index.ts) -> consumo en [src/main.ts](./Auth-Service/src/main.ts), [src/common/common.module.ts](./Auth-Service/src/common/common.module.ts), [src/database/data-source.ts](./Auth-Service/src/database/data-source.ts), [src/auth/strategies/ldap.strategy.ts](./Auth-Service/src/auth/strategies/ldap.strategy.ts), [src/auth/auth.module.ts](./Auth-Service/src/auth/auth.module.ts), [src/auth/auth.service.ts](./Auth-Service/src/auth/auth.service.ts) y [src/auth-app-mobile/auth-app-mobile.service.ts](./Auth-Service/src/auth-app-mobile/auth-app-mobile.service.ts).

| Variable | Declarada en | Donde se usa | Funcion | Ejemplo |
| --- | --- | --- | --- | --- |
| `DB_SCHEMA` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/database/data-source.ts](./Auth-Service/src/database/data-source.ts) | Define el esquema PostgreSQL sobre el que corre `Auth-Service`. | `DB_SCHEMA=auth` |
| `LDAP_AUTHENTICATION` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/config/envs.ts](./Auth-Service/src/config/envs.ts) | Bandera declarada para habilitar o deshabilitar autenticacion LDAP. En `src/` no se encontro consumo directo adicional. | `LDAP_AUTHENTICATION=true` |
| `LDAP_HOST` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/auth/strategies/ldap.strategy.ts](./Auth-Service/src/auth/strategies/ldap.strategy.ts) | Host del servidor LDAP usado por la estrategia `passport-ldapauth`. | `LDAP_HOST=localhost` |
| `LDAP_PORT` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/auth/strategies/ldap.strategy.ts](./Auth-Service/src/auth/strategies/ldap.strategy.ts) | Puerto del servidor LDAP. | `LDAP_PORT=389` |
| `LDAP_ADMIN_PREFIX` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/auth/strategies/ldap.strategy.ts](./Auth-Service/src/auth/strategies/ldap.strategy.ts) | Prefijo del administrador LDAP usado para construir `bindDN`. | `LDAP_ADMIN_PREFIX=cn` |
| `LDAP_ADMIN_USERNAME` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/auth/strategies/ldap.strategy.ts](./Auth-Service/src/auth/strategies/ldap.strategy.ts) | Nombre de usuario del administrador LDAP usado en `bindDN`. | `LDAP_ADMIN_USERNAME=root` |
| `LDAP_ADMIN_PASSWORD` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/auth/strategies/ldap.strategy.ts](./Auth-Service/src/auth/strategies/ldap.strategy.ts) | Contrasena del administrador LDAP usada como `bindCredentials`. | `LDAP_ADMIN_PASSWORD=password` |
| `LDAP_ACCOUNT_PREFIX` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/config/envs.ts](./Auth-Service/src/config/envs.ts) | Prefijo pensado para cuentas LDAP de usuario final. En `src/` no se encontro consumo directo adicional. | `LDAP_ACCOUNT_PREFIX=uid` |
| `LDAP_ACCOUNT_SUFFIX` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/config/envs.ts](./Auth-Service/src/config/envs.ts) | Sufijo o rama LDAP de las cuentas de usuario. En `src/` no se encontro consumo directo adicional. | `LDAP_ACCOUNT_SUFFIX="o=users"` |
| `LDAP_BASEDN` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/auth/strategies/ldap.strategy.ts](./Auth-Service/src/auth/strategies/ldap.strategy.ts) | Base DN usada tanto para `bindDN` como para `searchBase`. | `LDAP_BASEDN="dc=example,dc=com"` |
| `JWT_SECRET` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/auth/auth.module.ts](./Auth-Service/src/auth/auth.module.ts)<br>[src/auth/auth.service.ts](./Auth-Service/src/auth/auth.service.ts) | Secreto con el que se firman y verifican los JWT del servicio. | `JWT_SECRET="your_jwt_secret"` |
| `API_KEY` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/auth/auth.service.ts](./Auth-Service/src/auth/auth.service.ts) | Llave que el servicio compara en `verifyApiKey` para integraciones internas. | `API_KEY="internal-service-key"` |
| `USER_TEST_DEVICE` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/auth-app-mobile/auth-app-mobile.service.ts](./Auth-Service/src/auth-app-mobile/auth-app-mobile.service.ts) | Identificador de dispositivo o usuario autorizado para ingreso de prueba. | `USER_TEST_DEVICE=99999` |
| `USER_TEST_ACCESS` | [.env.compose.template](./Auth-Service/.env.compose.template) | [src/auth-app-mobile/auth-app-mobile.service.ts](./Auth-Service/src/auth-app-mobile/auth-app-mobile.service.ts) | Habilita el acceso directo para el dispositivo de pruebas cuando vale `true`. | `USER_TEST_ACCESS=false` |

<a id="6-variables-de-beneficiary-service"></a>
## 6. Variables de `Beneficiary-Service`

Archivo documentado: `Beneficiary-Service/.env.compose`

Ruta real:

`.env` + `.env.compose` -> [src/config/envs.ts](./Beneficiary-Service/src/config/envs.ts) -> [src/config/index.ts](./Beneficiary-Service/src/config/index.ts) -> consumo en [src/main.ts](./Beneficiary-Service/src/main.ts), [src/common/common.module.ts](./Beneficiary-Service/src/common/common.module.ts), [src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts), [src/affiliates/affiliates.service.ts](./Beneficiary-Service/src/affiliates/affiliates.service.ts), [src/persons/persons.service.ts](./Beneficiary-Service/src/persons/persons.service.ts) y seeds.

| Variable | Declarada en | Donde se usa | Funcion | Ejemplo |
| --- | --- | --- | --- | --- |
| `DB_SCHEMA` | [.env.compose.template](./Beneficiary-Service/.env.compose.template) | [src/database/data-source.ts](./Beneficiary-Service/src/database/data-source.ts) | Define el esquema PostgreSQL del servicio de beneficiarios. | `DB_SCHEMA=beneficiaries` |
| `PATH_FTP_FINGERPRINTS` | [.env.compose.template](./Beneficiary-Service/.env.compose.template) | [src/persons/persons.service.ts](./Beneficiary-Service/src/persons/persons.service.ts) | Ruta base donde se guardan y consultan huellas digitales por persona. | `PATH_FTP_FINGERPRINTS="Person/Fingerprints"` |
| `PATH_FTP_DOCUMENTS` | [.env.compose.template](./Beneficiary-Service/.env.compose.template) | [src/affiliates/affiliates.service.ts](./Beneficiary-Service/src/affiliates/affiliates.service.ts)<br>[src/database/seeds/1738939765121-import_requirements.ts](./Beneficiary-Service/src/database/seeds/1738939765121-import_requirements.ts) | Ruta base donde se construyen carpetas y nombres de documentos del afiliado. | `PATH_FTP_DOCUMENTS="Affiliate/Documents"` |
| `PATH_FTP_FILE_DOSSIERS` | [.env.compose.template](./Beneficiary-Service/.env.compose.template) | [src/affiliates/affiliates.service.ts](./Beneficiary-Service/src/affiliates/affiliates.service.ts) | Ruta base usada para expedientes o dossiers del afiliado. | `PATH_FTP_FILE_DOSSIERS="Affiliate/FileDossiers"` |
| `PATH_FTP_IMPORT_DOCUMENTS_PVTBE` | [.env.compose.template](./Beneficiary-Service/.env.compose.template) | [src/affiliates/affiliates.service.ts](./Beneficiary-Service/src/affiliates/affiliates.service.ts) | Ruta FTP de importacion que se usa en el analisis de documentos provenientes de PVTBE. | `PATH_FTP_IMPORT_DOCUMENTS_PVTBE="/documentos_pvtbe"` |

<a id="7-servicios-cuyo-envcompose-solo-define-dbschema"></a>
## 7. Servicios cuyo `.env.compose` solo define `DB_SCHEMA`

En estos microservicios, el archivo `.env.compose` actual solo agrega el esquema de base de datos. El resto de su configuracion operativa llega desde el `.env` raiz.

| Servicio | Variable | Declarada en | Donde se usa | Funcion | Ejemplo | Confirmacion tecnica |
| --- | --- | --- | --- | --- | --- | --- |
| `Global-Service` | `DB_SCHEMA` | [.env.compose.template](./Global-Service/.env.compose.template) | [src/database/data-source.ts](./Global-Service/src/database/data-source.ts) | Define el esquema PostgreSQL del servicio global. | `DB_SCHEMA=global` | Joi si define default `global` en [src/config/envs.ts](./Global-Service/src/config/envs.ts). |
| `Kiosk-Service` | `DB_SCHEMA` | [.env.compose.template](./Kiosk-Service/.env.compose.template) | [src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts) | Define el esquema PostgreSQL del servicio de kiosco. | `DB_SCHEMA=kiosk` | Joi define default `beneficiaries` en [src/config/envs.ts](./Kiosk-Service/src/config/envs.ts), por eso conviene declarar `DB_SCHEMA` explicitamente en `.env.compose`. |
| `App-Mobile-Service` | `DB_SCHEMA` | [.env.compose.template](./App-Mobile-Service/.env.compose.template) | [src/database/data-source.ts](./App-Mobile-Service/src/database/data-source.ts) | Define el esquema PostgreSQL del servicio movil. | `DB_SCHEMA=app_mobile` | [src/config/envs.ts](./App-Mobile-Service/src/config/envs.ts) exporta `dbSchema`, pero Joi no lo valida como requerido. |
| `Records-Service` | `DB_SCHEMA` | [.env.compose.template](./Records-Service/.env.compose.template) | [src/database/data-source.ts](./Records-Service/src/database/data-source.ts) | Define el esquema PostgreSQL del servicio de records. | `DB_SCHEMA=records` | [src/config/envs.ts](./Records-Service/src/config/envs.ts) no valida `DB_SCHEMA` ni el resto del bloque DB como requerido. |
| `Loans-Service` | `DB_SCHEMA` | [.env.compose.template](./Loans-Service/.env.compose.template) | [src/database/data-source.ts](./Loans-Service/src/database/data-source.ts) | Define el esquema PostgreSQL del servicio de prestamos. | `DB_SCHEMA=loans` | [src/config/envs.ts](./Loans-Service/src/config/envs.ts) no exige el bloque DB completo, aunque `data-source.ts` si lo necesita. |
| `Contributions-Service` | `DB_SCHEMA` | [.env.compose.template](./Contributions-Service/.env.compose.template) | [src/database/data-source.ts](./Contributions-Service/src/database/data-source.ts) | Define el esquema PostgreSQL del servicio de contribuciones. | `DB_SCHEMA=contributions` | [src/config/envs.ts](./Contributions-Service/src/config/envs.ts) no exige el bloque DB completo, aunque luego se consume en `data-source.ts`. |

<a id="8-observaciones-utiles"></a>
## 8. Observaciones utiles
- [README.md](./README.md) ya cubre la creacion de archivos `.env` y `.env.compose`, por eso aqui solo se documenta su contenido y su uso.
- En [Gateway-Service/src/config/envs.ts](./Gateway-Service/src/config/envs.ts) la validacion Joi incluye `PVT_API_SERVER`, pero el codigo consume `PVT_BE_API_SERVER` y `PVT_BACKEND_API_SERVER`.
- En [Gateway-Service/src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts) y [Kiosk-Service/src/database/data-source.ts](./Kiosk-Service/src/database/data-source.ts), `DB_HOST` entra por `process.env.DB_HOST` en vez de `DbEnvs.dbHost`.
- En [Gateway-Service/src/database/data-source.ts](./Gateway-Service/src/database/data-source.ts), `schema` no depende de `DB_SCHEMA` porque esta fijo en `public`, y `synchronize` no depende de `DB_SYNCHRONIZE` porque esta fijo en `true`.
- En [Auth-Service/src/config/envs.ts](./Auth-Service/src/config/envs.ts), `LDAP_AUTHENTICATION`, `LDAP_ACCOUNT_PREFIX` y `LDAP_ACCOUNT_SUFFIX` estan declaradas en configuracion, pero en el codigo actual no se encontro un consumo directo adicional fuera de `envs.ts`.
- En [Auth-Service/src/config/envs.ts](./Auth-Service/src/config/envs.ts), la interfaz declara `PVTBE_USERNAME` y `PVTBE_PASSWORD`, pero no aparecen en Joi ni en exports ni en usos encontrados dentro de `src/`.
- En [Auth-Service/src/config/envs.ts](./Auth-Service/src/config/envs.ts) y [Kiosk-Service/src/config/envs.ts](./Kiosk-Service/src/config/envs.ts), el default Joi de `DB_SCHEMA` no coincide con el nombre esperado del servicio.
- En [App-Mobile-Service/src/config/envs.ts](./App-Mobile-Service/src/config/envs.ts), [Records-Service/src/config/envs.ts](./Records-Service/src/config/envs.ts), [Loans-Service/src/config/envs.ts](./Loans-Service/src/config/envs.ts) y [Contributions-Service/src/config/envs.ts](./Contributions-Service/src/config/envs.ts), Joi no valida como requeridas todas las variables DB que despues usa `data-source.ts`.
- En [Auth-Service/src/main.ts](./Auth-Service/src/main.ts) existe un arranque HTTP comentado (`NestFactory.create(AppModule)` y `listen(3006)`), pero hoy el flujo activo es solo microservicio NATS.
- En [Gateway-Service/src/main.ts](./Gateway-Service/src/main.ts), `CLIENT_GATEWAY_PORT` publica el puerto hacia el host, mientras que `PORT` es el puerto interno del proceso NestJS.
- Usa siempre formato `CLAVE=valor` sin espacios alrededor de `=`, aunque algunas plantillas antiguas del repositorio muestren espacios.
