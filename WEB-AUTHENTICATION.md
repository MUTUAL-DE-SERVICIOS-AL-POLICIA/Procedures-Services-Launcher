# Autenticacion web y expiracion de sesiones

Este documento describe la sesion OIDC del Hub, la sesion web local y la configuracion necesaria para que Keycloak, Redis y las cookies tengan limites coherentes.

## 1. Componentes de la sesion

| Componente                | Funcion                                     | Que lo invalida                                  |
| ------------------------- | ------------------------------------------- | ------------------------------------------------ |
| Access token de Keycloak  | Autoriza llamadas durante una vida corta    | Expiracion del token o rechazo de Keycloak       |
| Refresh token de Keycloak | Permite renovar el access token             | Expiracion, revocacion o `invalid_grant`         |
| `sid` de Redis            | Sesion web local y almacen seguro de tokens | TTL idle, TTL absoluto, logout o `invalid_grant` |
| Cookie `sid`              | Transporta solamente el identificador opaco | `maxAge` absoluto o limpieza del Hub             |
| Cookie `profile`          | Datos de presentacion del usuario           | `maxAge` absoluto o limpieza del Hub             |

`profile` nunca es una credencial. La autorizacion depende de `sid`, Redis y Auth-Service.

## 2. Valores recomendados

Auth-Service usa estos defaults internos cuando las variables no existen:

```env
WEB_SESSION_TTL_SECONDS=28800
WEB_SESSION_IDLE_TTL_SECONDS=7200
WEB_REFRESH_SKEW_SECONDS=120
```

Interpretacion:

- `WEB_SESSION_TTL_SECONDS`: limite absoluto de la sesion web, 8 horas.
- `WEB_SESSION_IDLE_TTL_SECONDS`: limite por inactividad, 2 horas.
- `WEB_REFRESH_SKEW_SECONDS`: margen para renovar el access token antes de su expiracion, 120 segundos.
- Las cookies `sid` y `profile` se crean con el limite absoluto informado por Auth-Service.
- Redis conserva la sesion solamente hasta el menor valor entre el limite absoluto y el idle timeout.

Auth-Service rechaza la configuracion si `WEB_SESSION_IDLE_TTL_SECONDS` es mayor que `WEB_SESSION_TTL_SECONDS`.

La regla de coherencia es:

```text
access token < idle timeout <= absolute timeout <= Keycloak SSO max
cookie maxAge = absolute timeout de la sesion web
```

No se debe igualar el `sid` con la vida del access token. El access token debe ser corto y renovarse usando el refresh token.

## 3. Configuracion de Keycloak

En Keycloak, dentro del realm utilizado por `OIDC_ISSUER`:

### Realm settings > Sessions

Usar valores iguales o superiores a los limites de la sesion web:

- **SSO Session Idle**: al menos `2 hours`.
- **SSO Session Max**: al menos `8 hours`.
- **SSO Session Idle Remember Me** y **SSO Session Max Remember Me**: no deben permitir una duracion mayor a la politica de la aplicacion. Si no se usa Remember Me, mantenerlos deshabilitados o alineados.
- Revisar tambien **Client Session Idle** y **Client Session Max**. No deben ser menores que los valores SSO si se espera que el Hub renueve tokens durante toda la sesion.

Es recomendable que los valores de Keycloak sean ligeramente mayores que los de la sesion web, por ejemplo:

```text
Web idle:       2h
Web absolute:   8h
Keycloak idle:  2h 15m
Keycloak max:   8h 15m
```

Esto evita que un desfase de reloj o de red corte la sesion antes de que Auth-Service pueda detectar correctamente la expiracion.

### Clients > hub-interface > Settings

Configurar:

- **Client type**: `OpenID Connect`.
- **Client authentication**: `On`; `hub-interface` es siempre confidencial.
- **Standard flow**: habilitado.
- **Direct access grants**: deshabilitado salvo que exista un caso explicito.
- **Valid redirect URIs**: debe coincidir exactamente con `OIDC_HUB_CALLBACK_URL`, por ejemplo:

  ```text
  http://192.168.2.241:3001/api/auth/callback
  ```

- **Web origins**: usar un origen concreto, por ejemplo `http://192.168.2.241:3001`; no usar `*` en produccion.
- **Valid post logout redirect URIs**: debe incluir exactamente el origen definido por `OIDC_HUB_POST_LOGOUT_REDIRECT_URL`, por ejemplo:

  ```text
  http://192.168.2.241:3001/
  ```

- Mantener el secreto del cliente solamente en el entorno del servidor. No exponerlo en Login Hub ni en el navegador.

## Callback OIDC iniciado hace demasiado tiempo

La cookie HttpOnly `oidc_binding` y el estado pendiente tienen una vida limitada. Keycloak puede crear su sesion SSO y devolver un `code` despues de que esa vinculacion haya expirado. En ese caso el Hub no canjea el codigo, porque ya no puede demostrar que el navegador inicio ese flujo ni recuperar PKCE de forma segura.

Cuando el callback contiene exactamente un `code` y un `state`, pero falta `oidc_binding` o Auth-Service responde `LOGIN_STATE_INVALID`, el Hub inicia automaticamente un unico flujo nuevo hacia `/apphub`. Keycloak puede reutilizar su sesion SSO y completar el segundo flujo sin pedir credenciales nuevamente. Una cookie HttpOnly de recuperacion, limitada a 120 segundos y a `/api/auth`, impide ciclos: si el segundo callback vuelve a llegar sin vinculacion, el proceso falla cerrado y presenta el error. La cookie se elimina al completar el login o mostrar el error.

## 4. Que ocurre al expirar cada parte

### Expira el access token

Auth-Service intenta usar el refresh token cuando el access token entra en el margen de renovacion. Si Keycloak acepta el refresh, reemplaza los tokens en Redis y conserva el `sid`.

### Keycloak responde `invalid_grant`

Auth-Service elimina la sesion completa de Redis y devuelve `SESSION_INVALID`. El Hub limpia `sid`, `profile` y la cookie de binding al redirigir por `/api/auth/session/invalid`.

### Expira Redis

La cookie puede seguir visible hasta su `maxAge`, pero ya no concede acceso. La siguiente peticion protegida recibe `SESSION_INVALID` y el Hub limpia las cookies.

### Expira la cookie

El navegador deja de enviarla y la interfaz inicia el flujo de login. La clave de Redis puede permanecer hasta su TTL, pero queda inutilizable porque ya no se conoce el `sid`.

## 5. Logout esperado

El logout normal debe iniciar en:

```text
/api/auth/logout
```

El flujo:

1. El Hub envia el `sid` al Gateway.
2. Gateway solicita a Auth-Service revocar el refresh token.
3. Auth-Service elimina el `sid` de Redis.
4. Auth-Service crea la URL de logout de Keycloak.
5. El Hub limpia `sid`, `profile` y `oidc_binding`.
6. Keycloak termina la sesion SSO y retorna al post logout redirect permitido.

Si Keycloak esta temporalmente indisponible, Auth-Service sigue eliminando Redis y el Hub limpia las cookies. La revocacion OIDC se reintenta mediante el siguiente login, si corresponde.

## 6. Back-channel logout

Auth-Service valida el logout token firmado por Keycloak usando el issuer configurado, el JWKS del realm, el algoritmo `RS256`, la audiencia `hub-interface`, el evento OIDC de back-channel logout y la ausencia de `nonce`.

Gateway expone el endpoint público:

```text
POST /api/auth/backchannel-logout
Content-Type: application/x-www-form-urlencoded

logout_token=<JWT emitido por Keycloak>
```

Auth-Service mantiene índices Redis internos por `sid` OIDC y por `sub`:

- durante el Authorization Code exchange, el `sid` se obtiene únicamente de los access/ID tokens ya verificados;
- si ambos tokens incluyen `sid`, sus valores deben coincidir; una discrepancia invalida el login;
- `WebSession.primary.keycloakSessionId` conserva ese identificador y permite crear el índice `oidc:sid` junto con el índice `oidc:sub`;
- durante refresh, un `sid` verificado puede completar una sesión anterior que todavía no lo tenga, pero nunca puede reemplazar uno diferente;
- si el logout token contiene `sid`, se elimina únicamente la sesión web asociada;
- si el logout token no contiene `sid` pero contiene `sub`, se eliminan todas las sesiones web del usuario;
- nunca se usa `sub` como fallback cuando un logout token válido contiene `sid`, porque eso cerraría otras sesiones del usuario;
- nunca se confía en un token sin firma válida, emisor, audiencia, `jti`, evento o identificador de sesión.

### Estructuras `SET` visibles en Redis

Al crear una sesión web, Redis puede mostrar tres tipos de claves bajo el prefijo del ambiente:

```text
muserpol-web:dev:session:<sid-web>       STRING
muserpol-web:dev:oidc:sid:<hash>          SET
muserpol-web:dev:oidc:sub:<hash>          SET
```

La clave `session` es la sesión real. Su valor es un JSON interno que contiene los tokens y la información necesaria para renovar y autorizar la sesión; nunca debe exponerse en logs.

Las dos claves con tipo `SET` son índices auxiliares:

| Clave Redis       | Miembros del conjunto  | Uso                                                                                      |
| ----------------- | ---------------------- | ---------------------------------------------------------------------------------------- |
| `oidc:sid:<hash>` | Uno o varios `sid-web` | Encontrar la sesión web asociada al `sid` de Keycloak recibido en el logout token.       |
| `oidc:sub:<hash>` | Uno o varios `sid-web` | Encontrar todas las sesiones web del usuario cuando el logout token solo contiene `sub`. |

El `<hash>` se calcula internamente con SHA-256. No es un token ni una credencial: evita guardar directamente en el nombre de la clave el `sid` de Keycloak o el identificador del usuario. El miembro del `SET` sí es el identificador opaco de la sesión web, necesario para localizar la clave `session` y eliminarla.

Estos índices no conceden autenticación por sí mismos. Si se elimina un `SET`, la sesión web puede seguir existiendo hasta que expire o sea eliminada por otro mecanismo; si se elimina la clave `session`, los índices solo contienen una referencia obsoleta. Auth-Service elimina ambas cosas durante el logout y asigna a los índices un TTL coherente con la sesión. El TTL se renueva cuando la sesión tiene actividad y los índices desaparecen automáticamente cuando alcanzan su expiración.

Para inspeccionarlos sin revelar valores sensibles:

```text
TYPE muserpol-web:dev:oidc:sid:<hash>
SCARD muserpol-web:dev:oidc:sid:<hash>
TTL muserpol-web:dev:oidc:sid:<hash>
```

Evita usar `SMEMBERS` en producción si no es necesario, porque devuelve los `sid-web` asociados. No borres manualmente los índices durante una prueba; elimina la sesión mediante el logout normal o el back-channel para validar el flujo completo.

Ahora sí se puede configurar en Keycloak el **Backchannel Logout URL** del cliente `hub-interface`:

```text
https://<gateway-public-host>/api/auth/backchannel-logout
```

En desarrollo con la dirección actual:

```text
http://192.168.2.241:3000/api/auth/backchannel-logout
```

Activa **Backchannel Logout Session Required** si aparece en la versión de Keycloak. No actives **Frontchannel Logout** como sustituto: el mecanismo implementado es back-channel.

El back-channel es servidor a servidor y no puede borrar directamente cookies del navegador. Cuando Auth-Service elimina la WebSession en Redis, las cookies opacas `sid` y `profile` dejan de conceder acceso. En la siguiente navegación o Server Action, Gateway devuelve `SESSION_INVALID`; el frontend redirige al handler interno del Hub, que elimina ambas cookies antes de iniciar un nuevo flujo si corresponde.

La detección por `invalid_grant` se conserva como respaldo. Si Keycloak no entrega un evento al expirar una sesión, el siguiente refresh del token principal invalida la WebSession completa. No se usa introspección en cada petición porque aumentaría latencia y dependencia de Keycloak.

### Transición de sesiones anteriores

Una WebSession creada por una versión que no persistía `primary.keycloakSessionId` carece inicialmente del índice `oidc:sid`. Un refresh exitoso con tokens verificados completa el campo y crea el índice. Para una activación inmediata y determinista del back-channel después de desplegar esta corrección, se debe solicitar un nuevo login o invalidar de forma controlada las sesiones anteriores; no se debe usar `sub` como fallback para un logout token que contiene `sid`.

## 7. Variables del launcher

En `Auth-Service/.env.compose` y en su plantilla deben existir:

```env
OIDC_ISSUER=http://keycloak:8080/realms/muserpol
OIDC_INTERNAL_BASE_URL=http://keycloak:8080
OIDC_HUB_CLIENT_SECRET=<secreto>
OIDC_HUB_CALLBACK_URL=http://HOST:3001/api/auth/callback
OIDC_HUB_POST_LOGOUT_REDIRECT_URL=http://HOST:3001/
```

En una producción con HTTPS, usar URLs públicas HTTPS y `AUTH_COOKIE_SECURE=true` en todas las interfaces. Si la intranet opera únicamente con HTTP, conservar URLs públicas HTTP, establecer `AUTH_COOKIE_SECURE=false` y `WEB_AUTH_ALLOW_INSECURE_HTTP=true` en Login-Hub-Interface y agregar `WEB_AUTH_ALLOW_INSECURE_HTTP=true` a `Auth-Service/.env.compose`. El override solo evita el rechazo de configuración: no cifra credenciales, authorization codes, tokens ni cookies en tránsito.

Los defaults opcionales son `hub`, `hub-interface`, `redis:6379`, `muserpol-web`, pending de 600 segundos, sesion absoluta de 28800 segundos, idle de 7200 segundos y margen de refresh de 120 segundos. Para cambiar uno se agrega su variable documentada a `Auth-Service/.env.compose` y se recrea Auth-Service. Cambiar host, puerto o prefijo de Redis durante sesiones activas puede hacer inaccesibles las sesiones existentes; debe planificarse como una invalidacion de sesiones. Reducir TTL afecta las siguientes escrituras y renovaciones de sesion.

## 8. Verificacion operativa

1. Iniciar sesion y confirmar que Redis contiene una clave con prefijo `muserpol-web:<environment>:session:`.
2. Confirmar el TTL con `TTL <clave>`; debe ser menor o igual a 7200 segundos al crear la sesion.
3. Esperar o simular la expiracion del access token y realizar una peticion. Debe renovarse sin cambiar el `sid`.
4. Revocar la sesion desde Keycloak y provocar una renovacion. Debe recibirse `SESSION_INVALID` y debe desaparecer la clave Redis.
5. Abrir nuevamente la aplicacion. El Hub debe borrar `sid` y `profile` y comenzar un login nuevo.
6. Ejecutar el logout normal y comprobar que Redis, cookies y la sesion SSO quedan invalidados.
7. Cerrar la sesión desde Keycloak y comprobar que el endpoint back-channel responde `204` y elimina el `sid` indexado en Redis.

No registrar access tokens, refresh tokens, secretos de cliente ni el contenido completo de las cookies en logs.
