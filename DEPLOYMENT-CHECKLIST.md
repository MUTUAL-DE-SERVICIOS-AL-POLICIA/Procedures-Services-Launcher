# Checklist para un ambiente de pruebas

Este procedimiento prepara un ambiente nuevo. Cuando se necesite conservar la configuración ya validada de Keycloak, permite restaurar una copia controlada de su esquema únicamente sobre un destino vacío.

## 1. Versiones y submódulos

1. Clonar ambos launchers.
2. Inicializar submódulos con las revisiones registradas por cada launcher.
3. Comprobar que cada submódulo está en la rama o commit aprobado.
4. No usar `git submodule update --remote` durante un despliegue reproducible.

## 2. Configuración

### Backend

1. Copiar `.env.template` a `.env` y completarlo para el ambiente.
2. En producción establecer `ENVIRONMENT=prod` y revisar todos los valores compartidos.
3. Copiar cada `.env.compose.template` necesaria a `.env.compose` y revisar sus integraciones para el ambiente; no reutilizar valores de desarrollo.
4. El Compose carga `.env` primero y luego el `.env.compose` específico de cada servicio.
5. Definir PostgreSQL, NATS, Redis y Keycloak.
6. En Auth-Service, definir OIDC, cliente Hub, catálogo y TTL.
7. Mantener `DB_SYNCHRONIZE=false` en un ambiente compartido.
8. Guardar secretos fuera de Git.

### Frontend

1. Copiar la plantilla del launcher frontend a `.env` y completarla para el ambiente.
2. En producción establecer los hosts, puertos y orígenes públicos reales en ese mismo `.env`.
3. Configurar Gateway, Hub público y los orígenes públicos de herramientas.
4. En un despliegue HTTP establecer `AUTH_COOKIE_SECURE=false`; la cookie no queda protegida frente a captura dentro de la red.
5. En HTTPS establecer `AUTH_COOKIE_SECURE=true`.
6. Los `.env` de submódulos solo son necesarios para ejecución standalone.

## 3. Base de datos

- Crear o seleccionar las bases y schemas requeridos por los microservicios.
- Ejecutar `migration:show` en Beneficiary-Service, Sales-Service y Collections-Service para identificar el estado real de cada esquema.
- Ejecutar únicamente las migraciones pendientes y documentadas por cada servicio.
- No ejecutar seeders sin revisar si son idempotentes y qué datos escriben.
- No usar `synchronize=true` para preparar producción.
- Keycloak administra exclusivamente su propio schema.
- No ejecutar migraciones de aplicación ni seeders sobre el schema de Keycloak.
- Una restauración inicial del schema Keycloak solo se realiza sobre un destino vacío y siguiendo [KEYCLOAK-CONFIGURATION.md](./KEYCLOAK-CONFIGURATION.md).

## 4. Keycloak

Seguir [KEYCLOAK-CONFIGURATION.md](./KEYCLOAK-CONFIGURATION.md).

Antes de habilitar el flujo:

- realm existente y habilitado;
- federación LDAP verificada;
- cliente `hub-interface`;
- clientes de herramientas;
- token exchange permitido;
- redirect, post logout y backchannel exactos;
- mappers de identidad, grupos y client roles;
- Authorization Services y permisos acordados.

Una importación completa de realm no es un mecanismo de actualización seguro para una base existente. Primero se valida y se prepara un plan; solo después se aplican cambios administrativos idempotentes.

Si el ambiente se inicializa desde un dump del schema Keycloak:

- usar la misma versión de imagen en origen y destino;
- proteger y eliminar de forma segura el archivo temporal después de verificar la restauración;
- cambiar las URL que dependan del host del ambiente;
- revisar LDAP y rotar credenciales o secretos propios del ambiente;
- cerrar las sesiones heredadas antes de iniciar las pruebas;
- ejecutar `node Auth-Service/keycloak/scripts/validate-local-web-auth.mjs`, o el validador principal si Hub y Gateway tienen hosts diferentes.

## 5. Validación de Compose

Sin levantar servicios:

```sh
docker compose config --quiet
docker compose -f docker-compose.prod.yml config --quiet
```

La segunda validación solo demuestra interpolación y sintaxis. No confirma que la topología de producción tenga Redis y Keycloak disponibles.

## 6. Orden de arranque para pruebas

1. PostgreSQL.
2. NATS.
3. Redis.
4. Keycloak.
5. Auth-Service.
6. Gateway-Service.
7. Microservicios funcionales necesarios.
8. Hub.
9. Interfaces de herramientas.

Esperar que cada dependencia esté lista antes de iniciar pruebas funcionales. El orden no reemplaza health checks ni readiness en una plataforma de orquestación.

## 7. Pruebas mínimas

- login OIDC mediante code y state;
- callback y creación de SID;
- contexto del Hub;
- tarjetas según `launch`;
- lanzamiento de cada herramienta;
- contexto y permisos de la herramienta;
- una operación de lectura representativa;
- una operación de escritura representativa cuando exista entorno aislado;
- logout global;
- backchannel logout;
- refresh después de expirar el access token;
- denegación después de revocar un permiso;
- indisponibilidad temporal de Auth sin borrar cookies indebidamente.

No registrar SID, tokens, secretos, cookies completas ni datos personales.

## 8. Infraestructura incluida en producción

El Compose backend de producción incluye Redis y Keycloak:

- Redis usa un volumen persistente y no publica su puerto al host.
- Keycloak permanece fijado en la versión declarada por Compose.
- Keycloak escucha HTTP. Con proxy inverso se publica en loopback; para acceso HTTP directo por intranet se configura `KEYCLOAK_BIND_ADDRESS=0.0.0.0`.
- `KC_HOSTNAME` debe ser la URL pública exacta, incluido `http://` o `https://` y el puerto cuando corresponda.
- El proxy debe reemplazar los encabezados reenviados; `KC_PROXY_HEADERS=xforwarded` habilita su interpretación.
- Los temas se incorporan a la imagen construida desde `Auth-Service/keycloak`.

Antes del primer arranque:

1. realizar respaldo verificable de la base y del schema de Keycloak;
2. comprobar que la versión de la imagen coincide con la versión que creó o migró el schema;
3. configurar el proxy TLS o documentar la aceptación del riesgo si el acceso será HTTP directo;
4. cambiar las credenciales bootstrap;
5. configurar respaldo del volumen `web-redis-data`;
6. validar el Compose sin iniciarlo.

El arranque normal de Keycloak puede ejecutar migraciones propias cuando cambia su versión. Por eso una actualización de imagen debe tratarse como una migración planificada y nunca como una recreación rutinaria.
