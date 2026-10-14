# Configuración reproducible de Keycloak

La base de datos de Keycloak es estado operativo. No se modifica directamente, no se reemplaza con seeders SQL y no se importa un realm completo sobre un ambiente existente.

## Estrategia

La configuración debe administrarse mediante la API administrativa de Keycloak o `kcadm.sh` con tres acciones separadas:

1. **validate**: solo lectura; compara el estado esperado y reporta diferencias.
2. **plan**: muestra las operaciones que serían necesarias sin aplicarlas.
3. **apply**: crea o actualiza únicamente objetos administrados y requiere una acción explícita.

Mientras no exista esa herramienta versionada, la configuración se aplica manualmente siguiendo este documento. Nunca se ejecuta un `apply` automático al iniciar los contenedores.

Un futuro aprovisionador debe:

- identificar objetos por `clientId`, nombre de recurso, scope y permission, no por UUID exportado;
- ser idempotente;
- no borrar clientes, usuarios, grupos, sesiones ni políticas desconocidas;
- no guardar secretos o contraseñas en Git;
- detenerse ante diferencias destructivas;
- exportar un informe sanitizado antes de aplicar;
- ofrecer `validate` como acción predeterminada.

## Ejecución en producción

El launcher ejecuta Keycloak con `start`, no con `start-dev`. Por defecto publica el puerto en `127.0.0.1` para colocarlo detrás de un proxy TLS. Si la intranet opera deliberadamente con HTTP directo, se usa `KEYCLOAK_BIND_ADDRESS=0.0.0.0` y `KC_HOSTNAME` contiene el origen HTTP público exacto. Auth-Service usa `OIDC_INTERNAL_BASE_URL=http://keycloak:8080` dentro de la red de Compose en ambos casos.

Cambiar la versión de la imagen puede migrar el schema de Keycloak. Antes de actualizarla se necesita respaldo y un plan de reversión probado.

Keycloak usa por defecto PostgreSQL en el puerto `5432` y el schema `keycloak`, definidos en `Auth-Service/keycloak/keycloak.conf`. `KC_DB_URL_PORT` y `KC_DB_SCHEMA` pueden añadirse a `Auth-Service/.env.compose` para sobrescribirlos. El cambio solo afecta la conexión del siguiente arranque: no crea, copia ni migra los datos del schema anterior.

## Traslado inicial a un ambiente de pruebas

Mientras no exista un aprovisionador administrativo versionado, se puede trasladar el esquema completo de una instancia Keycloak ya validada hacia una base vacía de pruebas. Este procedimiento sirve para inicializar el ambiente; no debe usarse para actualizar o combinar dos instalaciones existentes.

Condiciones previas:

- origen y destino deben ejecutar la misma versión de Keycloak;
- el esquema de destino debe estar vacío y debe existir un respaldo de la base de destino;
- Keycloak debe permanecer detenido en el destino durante la restauración;
- el dump se trata como un secreto porque contiene credenciales, configuración y estado de sesiones;
- no se almacena el dump en Git ni en directorios públicos;
- las credenciales y secretos propios del ambiente se rotan después de restaurar;
- antes de habilitar usuarios se cierran las sesiones heredadas desde la consola administrativa.

Ejemplo con un dump SQL, usando conexiones y credenciales suministradas por el entorno:

```sh
pg_dump \
  --dbname="$KEYCLOAK_SOURCE_DATABASE_URL" \
  --schema=keycloak \
  --no-owner \
  --no-privileges \
  --file=/ruta/segura/keycloak.sql

psql \
  --dbname="$KEYCLOAK_TARGET_DATABASE_URL" \
  --set=ON_ERROR_STOP=1 \
  --single-transaction \
  --file=/ruta/segura/keycloak.sql
```

No restaurar el archivo sobre un esquema Keycloak que ya contenga tablas. Si el usuario PostgreSQL del destino es diferente, asignarle la propiedad o los privilegios requeridos sobre el esquema restaurado antes de arrancar Keycloak.

Después de restaurar:

1. configurar las nuevas URL públicas e internas del ambiente;
2. actualizar callback, post logout y backchannel del cliente `hub-interface`;
3. revisar las URL y credenciales de la federación LDAP;
4. rotar secretos administrativos y de clientes confidenciales cuando corresponda;
5. cerrar las sesiones importadas y realizar un login nuevo;
6. arrancar Keycloak y comprobar que no intenta una migración inesperada;
7. ejecutar el validador de solo lectura descrito al final de este documento.

El launcher no modifica automáticamente las URL almacenadas en Keycloak. El validador detecta diferencias, pero su corrección sigue siendo una operación administrativa explícita.

## Realm

El realm esperado por los ejemplos es `muserpol`. Debe coincidir con `OIDC_ISSUER`.

Configurar los tiempos de sesión según [WEB-AUTHENTICATION.md](./WEB-AUTHENTICATION.md). La federación LDAP pertenece a Keycloak; sus credenciales y conexión son configuración del ambiente y no deben incorporarse a un export versionado.

## Enlaces del manual en el tema

El tema personalizado admite un enlace HTTPS a un manual, incluido un
documento de Google Docs. Se configura en `Auth-Service/.env.compose` y se
reutiliza en todas las ayudas del login y de OTP:

```env
KEYCLOAK_USER_MANUAL_URL=https://docs.google.com/document/d/.../edit
```

Keycloak genera las propiedades del tema al iniciar su contenedor. Cambiar
estos valores requiere recrear el servicio `keycloak`, pero no reconstruir su
imagen. Una variable vacía oculta el enlace correspondiente. Una URL no vacía
debe usar HTTPS.

La pantalla de configuración OTP muestra siempre el código QR y la clave
manual, junto con un único enlace general al manual.

## Cliente `hub-interface`

Configuración mínima:

- protocolo OpenID Connect;
- Standard Flow habilitado;
- cliente confidencial con **Client authentication** habilitado;
- redirect URI exacta igual a `OIDC_HUB_CALLBACK_URL`;
- post logout redirect URI exacta igual a `OIDC_HUB_POST_LOGOUT_REDIRECT_URL`;
- Web Origins vacío o restringido, sin comodines; el BFF no usa llamadas OIDC desde JavaScript;
- Backchannel Logout URL: `<gateway-public-origin>/api/auth/backchannel-logout`;
- Backchannel Logout Session Required habilitado;
- Frontchannel Logout no sustituye el backchannel.

En desarrollo local, con los puertos predeterminados:

```text
Valid redirect URI:              http://localhost:3001/api/auth/callback
Valid post logout redirect URI:  http://localhost:3001/
Web origin:                      http://localhost:3001
Backchannel Logout URL:          http://localhost:3000/api/auth/backchannel-logout
```

Los valores reales deben usar el host visible por el navegador y, para backchannel, una URL del Gateway alcanzable desde Keycloak.

## Herramientas

Cada herramienta del `WEB_CLIENT_CATALOG` tiene su propio cliente y Authorization Services:

| Tool key      | Client ID / audience / resource server |
| ------------- | -------------------------------------- |
| `beneficiary` | `beneficiary-interface`                |
| `sales`       | `sales-interface`                      |
| `collections` | `collections-interface`                |

Auth-Service deriva audience y resource server del `clientId`; no se repiten en la variable.

El Hub usa recursos `beneficiary-interface`, `sales-interface` y `collections-interface` con scope `launch` para decidir qué tarjetas presenta y qué lanzamientos permite. La autorización de cada endpoint sigue perteneciendo al cliente de la herramienta.

No se deben inventar recursos o permisos para una herramienta antes de acordar su matriz. Los endpoints marcados como sesión web validan la sesión de la herramienta y los endpoints con permiso ejecutan UMA sobre el resource/scope fijo declarado por Gateway.

## Mappers

Los clientes de herramientas deben entregar al token intercambiado los claims que usa el contexto:

- subject estable;
- username preferido cuando exista;
- nombre y correo cuando correspondan;
- grupos cuando la interfaz deba mostrarlos;
- client roles de la herramienta.

Un usuario sin grupos es válido. Los permisos efectivos siempre provienen de Authorization Services; los grupos y roles mostrados por la UI son informativos.

## Verificación manual segura

Antes de probar:

1. comprobar que Keycloak, Redis, NATS, Auth-Service y Gateway estén activos;
2. confirmar que issuer, URLs públicas y URLs internas corresponden al ambiente;
3. revisar que el catálogo contenga cada tool key usada por los frontends;
4. validar redirect, post logout y backchannel del Hub;
5. confirmar que los clientes de herramientas permiten el token exchange configurado;
6. iniciar una sesión nueva después de cambios en mappers o roles;
7. validar lanzamiento, contexto, permiso UMA y logout global;
8. revocar una sesión desde Keycloak y confirmar que Redis queda invalidado por backchannel.

No se imprimen tokens, SID, secretos, cookies completas ni datos personales durante estas comprobaciones.

## Validación versionada de solo lectura

El estado estructural esperado está en:

```text
Auth-Service/keycloak/config/web-auth.expected.json
```

El validador consulta el realm, la presencia de una federación LDAP habilitada, los clientes, el rol base `user` de cada herramienta y los recursos `launch`. En el Hub también comprueba el tipo public/confidential, Standard Flow, Direct Access Grants deshabilitado, ausencia de comodines en Web Origins, callback y logout. No crea, actualiza ni elimina configuración. El único `POST` que realiza es el intercambio estándar de credenciales administrativas por un token temporal; todas las llamadas administrativas son `GET`.

Variables requeridas:

```env
KEYCLOAK_ADMIN_URL=https://keycloak.example.test
KEYCLOAK_ADMIN_REALM=master
KEYCLOAK_ADMIN_USERNAME=<administrador>
KEYCLOAK_ADMIN_PASSWORD=<secreto>
OIDC_HUB_CALLBACK_URL=https://hub.example.test/api/auth/callback
OIDC_HUB_POST_LOGOUT_REDIRECT_URL=https://hub.example.test/
KEYCLOAK_BACKCHANNEL_LOGOUT_URL=https://gateway.example.test/api/auth/backchannel-logout
```

También puede proporcionarse un `KEYCLOAK_ADMIN_TOKEN` temporal en lugar de usuario y contraseña.

Ejecución explícita con variables administradas por el entorno:

```sh
node Auth-Service/keycloak/scripts/validate-web-auth.mjs
```

Para el ambiente local del launcher existe un wrapper que lee `.env` y `Auth-Service/.env.compose` sin imprimir sus valores y deriva el backchannel usando el host del callback y `CLIENT_GATEWAY_PORT`:

```sh
node Auth-Service/keycloak/scripts/validate-local-web-auth.mjs
```

Este wrapper es apropiado cuando Hub y Gateway comparten host y se diferencian por puerto. En un ambiente con dominios diferentes debe usarse el validador principal y suministrar explícitamente `KEYCLOAK_BACKCHANNEL_LOGOUT_URL`.

El comando no se ejecuta durante el arranque de Compose. No imprime tokens, secretos, UUID de clientes ni respuestas administrativas completas.

## Qué no automatizar todavía

Aunque ya existe un manifiesto y validación de solo lectura, todavía no se automatiza la aplicación:

- no importar un realm JSON sobre la base actual;
- no ejecutar SQL contra el esquema de Keycloak;
- no recrear el realm;
- no rotar secretos automáticamente;
- no eliminar objetos que no aparezcan en la documentación;
- no ejecutar aprovisionamiento al arrancar Docker Compose.
