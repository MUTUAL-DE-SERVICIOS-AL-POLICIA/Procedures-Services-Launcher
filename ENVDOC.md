# ENVDOC



Guia de referencia para las variables de entorno que usa el launcher con Docker Compose.
Aqui se documenta:

- ¿Qué archivos de entorno carga Docker Compose?
- ¿Qué variable usa cada servicio?
- ¿Dónde se consume en el código?
- ¿Para qué sirve?
- ¿Un ejemplo de valor por variable?


## Indice

- [1. Archivos de entorno que intervienen](#1-archivos-de-entorno-que-intervienen)
- [2. Orden de carga en Docker Compose](#2-orden-de-carga-en-docker-compose)
- [2.1 Confirmacion por proyecto](#21-confirmacion-por-proyecto)
- [3. Variables compartidas del `.env` raiz](#3-variables-compartidas-del-env-raiz)
- [3.1. Variables de `Gateway-Service`](#31-variables-de-gateway-service)
- [3.2. Variables de `Auth-Service`](#32-variables-de-auth-service)
- [3.3. Variables de `Beneficiary-Service`](#33-variables-de-beneficiary-service)
- [3.4. Variables de `Global-Service`](#34-variables-de-global-service)
- [3.5. Variables de `Kiosk-Service`](#35-variables-de-kiosk-service)
- [3.6. Variables de `App-Mobile-Service`](#36-variables-de-app-mobile-service)
- [3.7. Variables de `Records-Service`](#37-variables-de-records-service)
- [3.8. Variables de `Loans-Service`](#38-variables-de-loans-service)
- [3.9. Variables de `Contributions-Service`](#39-variables-de-contributions-service)
- [4. Observaciones utiles](#4-observaciones-utiles)

<a id="1-archivos-de-entorno-que-intervienen"></a>
## 1. Archivos de entorno que intervienen

| Archivo | Alcance | Funcion |
| --- | --- | --- |
| `.env` | Launcher completo (raiz) | Define variables compartidas para el stack y valores interpolados por `docker-compose.yml` y `docker-compose.prod.yml`. |
| `./<Servicio>/.env.compose` | Un microservicio | Define o sobrescribe variables especificas del contenedor de ese servicio. |
| `./<Servicio>/.env.compose.template` | Un microservicio | Sirve como base para crear el `.env.compose` real. |
| `./<Servicio>/.env.template` | Servicio individual | Referencia para ejecutar el microservicio por separado. No es el archivo que usa el `docker compose` raiz. |

<a id="2-orden-de-carga-en-docker-compose"></a>
## 2. Orden de carga en Docker Compose

En `docker-compose.yml` y `docker-compose.prod.yml`, cada microservicio carga:

1. `.env`
2. `./<Servicio>/.env.compose`

Los archivos `docker-compose.yml || docker-compose.prod.yml` se encargar de cargas las variables de entorno para cada microservicio tanto para el entorno modo desarrollador o produccion respectiva.

Esto implica lo siguiente:

- el `.env` raiz inyecta variables compartidas como `DB_*`, `NATS_SERVERS` y `ENVIRONMENT`
- el `.env.compose` del servicio agrega sus variables propias, por ejemplo `DB_SCHEMA`, LDAP, FTP o integraciones externas
- si una clave existe en ambos archivos, prevalece el valor del `.env.compose` del microservicio dentro del contenedor

<a id="3-variables-compartidas-del-env-raiz"></a>
## 3. Variables compartidas del `.env` raiz

Estas variables no pertenecen a un solo microservicio; se reutilizan en varios contenedores del launcher.

| Variable | Valor de ejemplo | Funcion |
| --- | --- | --- |
| `CLIENT_GATEWAY_PORT` | `3000`<br>`8080` | Expone el gateway hacia el host en el puerto que abrira el cliente. |
| `DB_PASSWORD` | `123456`<br>`secure_pass` | Entrega la contrasena con la que TypeORM se conecta a PostgreSQL. Primero se normaliza en `src/config/envs.ts` de cada servicio y luego llega a `data-source.ts`. |
| `DB_DATABASE` | `microservice3`<br>`app_db` | Define la base de datos fisica que compartiran los microservicios. Primero se prepara en `envs.ts` y luego se consume en `data-source.ts`. |
| `DB_HOST` | `localhost`<br>`postgres` | Indica el host del servidor PostgreSQL. En casi todos pasa por `DbEnvs.dbHost`, pero en `Gateway-Service` y `Kiosk-Service` `data-source.ts` usa `process.env.DB_HOST` directamente. |
| `DB_PORT` | `5433`<br>`5432` | Indica el puerto del servidor PostgreSQL. Primero se transforma en `envs.ts` y luego `data-source.ts` lo usa como numero. |
| `DB_USERNAME` | `postgres`<br>`admin` | Define el usuario con el que cada servicio abre la conexion a PostgreSQL. Primero se exporta desde `DbEnvs` y luego se consume en `data-source.ts`. |
| `DB_SYNCHRONIZE` | `false`<br>`true` | Activa o desactiva `synchronize` en TypeORM. El `Gateway-Service` no la consume porque fija `synchronize: true`. |
| `NATS_SERVERS` | `"nats://192.168.2.90:4222"`<br>`"nats://localhost:4222"` | Define la URL o lista de URLs del broker NATS para la comunicacion entre servicios. |
| `ENVIRONMENT` | `dev`<br>`prod` | Define el ambiente de ejecucion del gateway. En `dev` habilita Swagger. |

<a id="3.1-variables-de-gateway-service"></a>
## 3.1. Variables de `Gateway-Service`

Archivo documentado: `Gateway-Service/.env.compose`

| Variable | Valor de ejemplo | Funcion |
| --- | --- | --- |
| `PORT` | `3000`<br>`8080` | Puerto interno en el que el proceso NestJS del gateway hace `listen`. |
| `FRONTENDS_SERVERS` | `"http://localhost:3001,http://localhost:3002"`<br>`"https://app.com,https://admin.com"` | Lista separada por comas que se usa en `enableCors` para definir origenes permitidos. |
| `PVT_BE_API_SERVER` | `"http://localhost:8000"`<br>`"https://api.pvt.com"` | URL base de la integracion PVT BE. El codigo le concatena `/api/v1`. |
| `PVT_BACKEND_API_SERVER` | `"http://localhost:8001"`<br>`"https://backend.pvt.com"` | URL base del backend PVT usado para prestamos, kardex y otras consultas. El codigo le concatena `/api`. |
| `PVT_HASH_SECRET` | `"secret"`<br>`"super_secret_key"` | Secreto con el que el guard valida el token hash de peticiones PVT. |
| `FTP_HOST` | `192.168.2.100`<br>`ftp.server.com` | Host del servidor FTP al que el gateway sube, descarga, lista y renombra archivos. |
| `FTP_USERNAME` | `test_pruebas`<br>`admin` | Usuario con el que el gateway autentica la sesion FTP. |
| `FTP_PASSWORD` | `test`<br>`secure123` | Contrasena usada para abrir la conexion FTP. |
| `FTP_ROOT` | `"/test_pruebas/"`<br>`"/data/files/"` | Ruta raiz sobre la que el gateway construye `upload`, `download`, `list` y `rename`. |
| `FTP_SSL` | `false`<br>`true` | Indica si la conexion FTP se abre con `secure: true` o `false`. |
| `SMS_SERVER_URL` | `"http://172.16.1.20/goip/en/"`<br>`"https://sms.provider.com/api/"` | URL base del proveedor SMS. Desde aqui se arma la llamada a `dosend.php` y `resend.php`. |
| `SMS_SERVER_ROOT` | `"root"`<br>`"user1"` | Usuario o identificador que el proveedor SMS espera como `USERNAME`. |
| `SMS_SERVER_PASSWORD` | `"TEST1234"`<br>`"pass123"` | Contrasena que el gateway envia al proveedor SMS. |
| `SMS_PROVIDER` | `"1"`<br>`"2"` | Identificador del proveedor o canal SMS enviado como `smsprovider`. |
| `WHATSAPP_SERVER_URL` | `"http://localhost:3100"`<br>`"https://wa.service.com"` | URL base del integrador de WhatsApp. El servicio publica a `/whatsapp/send`. |
| `CITIZENSHIP_DIGITAL_CLIENT_URL` | `"https://proveedor.bo"`<br>`"https://auth.service.com"` | URL base del proveedor OAuth de ciudadania digital. Se usa para `/token`, `/me` y `session/end`. |
| `CITIZENSHIP_DIGITAL_CLIENT_ID` | `"YYYYYYYYYYYYYYYY"`<br>`"ABC123XYZ"` | Identificador del cliente registrado ante el proveedor de ciudadania digital. |
| `CITIZENSHIP_DIGITAL_REDIRECT_URI` | `"com.app.pvt:/oauth2redirect"`<br>`"https://app.com/callback"` | Redirect URI usada en el intercambio del `authorization_code`. |
| `CITIZENSHIP_DIGITAL_SCOPES` | `"openid profile fecha_nacimiento email celular offline_access"`<br>`"openid email"` | Lista de scopes que el gateway expone al cliente para el flujo OAuth. |

<a id="3.2-variables-de-auth-service"></a>
## 3.2. Variables de `Auth-Service`

Archivo documentado: `Auth-Service/.env.compose`

| Variable | Valor de ejemplo | Funcion |
| --- | --- | --- |
| `DB_SCHEMA` | `auth`<br>`public` | Define el esquema PostgreSQL sobre el que corre `Auth-Service`. |
| `LDAP_AUTHENTICATION` | `true`<br>`false` | Bandera declarada para habilitar o deshabilitar autenticacion LDAP. En `src/` no se encontro consumo directo adicional. |
| `LDAP_HOST` | `localhost`<br>`ldap.server.com` | Host del servidor LDAP usado por la estrategia `passport-ldapauth`. |
| `LDAP_PORT` | `389`<br>`636` | Puerto del servidor LDAP. |
| `LDAP_ADMIN_PREFIX` | `cn`<br>`uid` | Prefijo del administrador LDAP usado para construir `bindDN`. |
| `LDAP_ADMIN_USERNAME` | `root`<br>`admin` | Nombre de usuario del administrador LDAP usado en `bindDN`. |
| `LDAP_ADMIN_PASSWORD` | `password`<br>`secure_pass` | Contrasena del administrador LDAP usada como `bindCredentials`. |
| `LDAP_ACCOUNT_PREFIX` | `uid`<br>`cn` | Prefijo pensado para cuentas LDAP de usuario final. En `src/` no se encontro consumo directo adicional. |
| `LDAP_ACCOUNT_SUFFIX` | `"o=users"`<br>`"ou=people"` | Sufijo o rama LDAP de las cuentas de usuario. En `src/` no se encontro consumo directo adicional. |
| `LDAP_BASEDN` | `"dc=example,dc=com"`<br>`"dc=company,dc=com"` | Base DN usada tanto para `bindDN` como para `searchBase`. |
| `JWT_SECRET` | `"your_jwt_secret"`<br>`"super_secret_key"` | Secreto con el que se firman y verifican los JWT del servicio. |
| `API_KEY` | `"internal-service-key"`<br>`"api_key_123"` | Llave que el servicio compara en `verifyApiKey` para integraciones internas. |
| `USER_TEST_DEVICE` | `99999`<br>`12345` | Identificador de dispositivo o usuario autorizado para ingreso de prueba. |
| `USER_TEST_ACCESS` | `false`<br>`true` | Habilita el acceso directo para el dispositivo de pruebas cuando vale `true`. |

<a id="3.2-variables-de-beneficiary-service"></a>
<a id="3.3-variables-de-beneficiary-service"></a>
## 3.3. Variables de `Beneficiary-Service`

Archivo documentado: `Beneficiary-Service/.env.compose`

| Variable | Valor de ejemplo | Funcion |
| --- | --- | --- |
| `DB_SCHEMA` | `beneficiaries`<br>`public` | Define el esquema PostgreSQL del servicio de beneficiarios. |
| `PATH_FTP_FINGERPRINTS` | `"Person/Fingerprints"`<br>`"Users/Biometrics"` | Ruta base donde se guardan y consultan huellas digitales por persona. |
| `PATH_FTP_DOCUMENTS` | `"Affiliate/Documents"`<br>`"Users/Documents"` | Ruta base donde se construyen carpetas y nombres de documentos del afiliado. |
| `PATH_FTP_FILE_DOSSIERS` | `"Affiliate/FileDossiers"`<br>`"Users/Dossiers"` | Ruta base usada para expedientes o dossiers del afiliado. |
| `PATH_FTP_IMPORT_DOCUMENTS_PVTBE` | `"/documentos_pvtbe"`<br>`"/imports/pvtbe"` | Ruta FTP de importacion que se usa en el analisis de documentos provenientes de PVTBE. |

<a id="3.3-servicios-cuyo-envcompose-solo-define-dbschema"></a>
Los siguientes microservicios comparten un patron simple: su `.env.compose` solo agrega `DB_SCHEMA`, pero aun asi conviene documentarlos por separado porque ese valor termina definiendo el esquema real que TypeORM usa en PostgreSQL.

<a id="3.4-variables-de-global-service"></a>
## 3.4. Variables de `Global-Service`

Archivo documentado: `Global-Service/.env.compose`

| Variable | Valor de ejemplo | Funcion |
| --- | --- | --- |
| `DB_SCHEMA` | `global`<br>`public` | Define el esquema PostgreSQL del servicio global. |

Nota tecnica: `src/config/envs.ts` si define `DB_SCHEMA` con default `global`, pero declararlo en `.env.compose` evita depender de defaults implicitos.

<a id="3.5-variables-de-kiosk-service"></a>
## 3.5. Variables de `Kiosk-Service`

Archivo documentado: `Kiosk-Service/.env.compose`

| Variable | Valor de ejemplo | Funcion |
| --- | --- | --- |
| `DB_SCHEMA` | `kiosk`<br>`beneficiaries` | Define el esquema PostgreSQL del servicio de kiosco. |

Nota tecnica: `src/config/envs.ts` deja `beneficiaries` como default, asi que en este servicio es especialmente importante fijar `DB_SCHEMA` de forma explicita en `.env.compose`.

<a id="3.6-variables-de-app-mobile-service"></a>
## 3.6. Variables de `App-Mobile-Service`

Archivo documentado: `App-Mobile-Service/.env.compose`

| Variable | Valor de ejemplo | Funcion |
| --- | --- | --- |
| `DB_SCHEMA` | `app_mobile`<br>`public` | Define el esquema PostgreSQL del servicio movil. |

Nota tecnica: `src/config/envs.ts` exporta `dbSchema`, pero Joi no lo valida como requerido; por eso el `.env.compose` sigue siendo la referencia practica para este valor.

<a id="3.7-variables-de-records-service"></a>
## 3.7. Variables de `Records-Service`

Archivo documentado: `Records-Service/.env.compose`

| Variable | Valor de ejemplo | Funcion |
| --- | --- | --- |
| `DB_SCHEMA` | `records`<br>`public` | Define el esquema PostgreSQL del servicio de records. |

Nota tecnica: `src/config/envs.ts` no marca `DB_SCHEMA` ni el resto del bloque DB como requerido, aunque `data-source.ts` si necesita esos valores para inicializar TypeORM.

<a id="3.8-variables-de-loans-service"></a>
## 3.8. Variables de `Loans-Service`

Archivo documentado: `Loans-Service/.env.compose`

| Variable | Valor de ejemplo | Funcion |
| --- | --- | --- |
| `DB_SCHEMA` | `loans`<br>`public` | Define el esquema PostgreSQL del servicio de prestamos. |

Nota tecnica: `src/config/envs.ts` valida `NATS_SERVERS`, pero no exige el bloque DB completo; aun asi `data-source.ts` usa `dbSchema` y el resto de credenciales para conectarse.

<a id="3.9-variables-de-contributions-service"></a>
## 3.9. Variables de `Contributions-Service`

Archivo documentado: `Contributions-Service/.env.compose`

| Variable | Valor de ejemplo | Funcion |
| --- | --- | --- |
| `DB_SCHEMA` | `contributions`<br>`public` | Define el esquema PostgreSQL del servicio de contribuciones. |

Nota tecnica: `src/config/envs.ts` tampoco obliga `DB_SCHEMA`, pero `data-source.ts` lo usa al crear la conexion, asi que documentarlo explicitamente ayuda a evitar errores silenciosos.

Ir al [README.md](./README.md)
