# ENVDOC

Guia de referencia para las variables de entorno que usa el launcher con Docker Compose.
Aqui se documenta:

- Que archivos de entorno carga Docker Compose
- Que variable usa cada servicio
- Donde se consume en el codigo
- Para que sirve
- Un ejemplo de valor por variable


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

<a id="1-archivos-de-entorno-que-intervienen"></a>
## 1. Archivos de entorno que intervienen

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Archivo</th>
      <th width="22%">Alcance</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>.env</code></td>
      <td>Launcher completo (raiz)</td>
      <td>Actua como capa base del stack. Docker Compose lo lee para interpolar variables del YAML y para inyectar valores compartidos en varios contenedores, por ejemplo credenciales de base de datos, NATS o puertos publicados.</td>
    </tr>
    <tr>
      <td><code>./&lt;Servicio&gt;/.env.compose</code></td>
      <td>Un microservicio dentro del launcher</td>
      <td>Completa o sobrescribe la configuracion heredada del <code>.env</code> raiz solo para ese contenedor. Aqui viven valores propios del servicio, como <code>DB_SCHEMA</code>, rutas FTP, LDAP o integraciones externas.</td>
    </tr>
    <tr>
      <td><code>./&lt;Servicio&gt;/.env.compose.template</code></td>
      <td>Un microservicio dentro del launcher</td>
      <td>Sirve como plantilla de referencia para construir el <code>.env.compose</code> real. En esta documentacion se toma como fuente principal para describir los valores de ejemplo del launcher.</td>
    </tr>
    <tr>
      <td><code>./&lt;Servicio&gt;/.env.template</code></td>
      <td>Servicio individual</td>
      <td>Es una referencia para ejecutar el microservicio por separado, fuera del launcher raiz. Puede tener ejemplos distintos a <code>.env.compose.template</code> porque responde al modo standalone del servicio y no al Compose principal.</td>
    </tr>
  </tbody>
</table>

<a id="2-orden-de-carga-en-docker-compose"></a>
## 2. Orden de carga en Docker Compose

En `docker-compose.yml` y `docker-compose.prod.yml`, cada microservicio carga:

1. `.env`
2. `./<Servicio>/.env.compose`

Los archivos `docker-compose.yml` y `docker-compose.prod.yml` se encargan de cargar las variables de entorno para cada microservicio, tanto en modo desarrollo como en produccion.

Esto implica lo siguiente:

- el `.env` raiz inyecta variables compartidas como `DB_*`, `NATS_SERVERS` y `ENVIRONMENT`
- el `.env.compose` del servicio agrega sus variables propias, por ejemplo `DB_SCHEMA`, LDAP, FTP o integraciones externas
- si una clave existe en ambos archivos, prevalece el valor del `.env.compose` del microservicio dentro del contenedor

<a id="21-confirmacion-por-proyecto"></a>
## 2.1 Confirmacion por proyecto

Se verificaron los `.env.compose.template` de estos microservicios del launcher:

- `Gateway-Service`
- `Auth-Service`
- `Beneficiary-Service`
- `Global-Service`
- `Kiosk-Service`
- `App-Mobile-Service`
- `Records-Service`
- `Loans-Service`
- `Contributions-Service`

<a id="3-variables-compartidas-del-env-raiz"></a>
## 3. Variables compartidas del `.env` raiz

Estas variables no pertenecen a un solo microservicio; se reutilizan en varios contenedores del launcher.

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Variable</th>
      <th width="22%">Valor de ejemplo</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>CLIENT_GATEWAY_PORT</code></td>
      <td><code>3000</code><br><code>8080</code></td>
      <td>Publica el puerto del contenedor del gateway hacia el host. Es el numero que usara el navegador, Postman o cualquier cliente externo para entrar al stack; cambiarlo modifica el puerto expuesto por Docker Compose, no el puerto interno del proceso NestJS.</td>
    </tr>
    <tr>
      <td><code>DB_PASSWORD</code></td>
      <td><code>123456</code><br><code>secure_pass</code></td>
      <td>Se pasa a TypeORM para autenticarse contra PostgreSQL. Si el valor es incorrecto, el servicio no podra abrir la conexion inicial, resolver repositorios ni ejecutar consultas, migraciones o seeders que dependan de la base.</td>
    </tr>
    <tr>
      <td><code>DB_DATABASE</code></td>
      <td><code>microservice3</code><br><code>app_db</code></td>
      <td>Selecciona la base de datos fisica dentro del servidor PostgreSQL. Varios microservicios pueden compartir esa base y aislarse por schema; si esta variable apunta a otra base, el servicio buscara sus tablas en un lugar completamente distinto.</td>
    </tr>
    <tr>
      <td><code>DB_HOST</code></td>
      <td><code>localhost</code><br><code>postgres</code></td>
      <td>Indica a que host o nombre de servicio Docker debe conectarse TypeORM. En Compose normalmente es el alias del contenedor de PostgreSQL; si no resuelve o apunta a otro host, la app fallara por timeout o por rechazo de conexion.</td>
    </tr>
    <tr>
      <td><code>DB_PORT</code></td>
      <td><code>5433</code><br><code>5432</code></td>
      <td>Define el puerto TCP usado para abrir la sesion con PostgreSQL. El valor se parsea como numero y debe coincidir con el puerto disponible en el host indicado por <code>DB_HOST</code>.</td>
    </tr>
    <tr>
      <td><code>DB_USERNAME</code></td>
      <td><code>postgres</code><br><code>admin</code></td>
      <td>Es el usuario con el que el servicio se autentica contra la base de datos. Ademas de poder conectarse, debe tener permisos suficientes sobre la base y el schema usados por el microservicio; de lo contrario habra errores al leer o escribir tablas.</td>
    </tr>
    <tr>
      <td><code>DB_SYNCHRONIZE</code></td>
      <td><code>false</code><br><code>true</code></td>
      <td>Controla si TypeORM intenta sincronizar automaticamente las entidades con la estructura real de la base al arrancar. En desarrollo puede ahorrar trabajo, pero en entornos sensibles un valor incorrecto puede provocar cambios de esquema no deseados o esconder diferencias que deberian resolverse con migraciones.</td>
    </tr>
    <tr>
      <td><code>NATS_SERVERS</code></td>
      <td><code>"nats://192.168.2.90:4222"</code><br><code>"nats://localhost:4222"</code></td>
      <td>Lista uno o varios brokers NATS usados por la comunicacion entre microservicios. Se parsea como lista separada por comas y alimenta los clientes RPC/eventos; si ninguno de los endpoints responde, las integraciones internas del sistema quedan indisponibles.</td>
    </tr>
    <tr>
      <td><code>ENVIRONMENT</code></td>
      <td><code>dev</code><br><code>prod</code></td>
      <td>Activa comportamiento dependiente del ambiente, por ejemplo Swagger en el gateway cuando vale <code>dev</code>. No suele cambiar la logica de negocio central, pero si aspectos operativos, de debugging y de exposicion de herramientas.</td>
    </tr>
  </tbody>
</table>

<a id="3.1-variables-de-gateway-service"></a>
## 3.1. Variables de `Gateway-Service`

Archivo documentado: `Gateway-Service/.env.compose.template`

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Variable</th>
      <th width="22%">Valor de ejemplo</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>PORT</code></td>
      <td><code>3000</code><br><code>8080</code></td>
      <td>Es el puerto interno en el que el proceso NestJS del gateway ejecuta <code>listen()</code>. Debe coincidir con la configuracion esperada por el contenedor; si el proceso arranca en otro puerto, Docker puede quedar publicando un puerto que no tiene nadie escuchando.</td>
    </tr>
    <tr>
      <td><code>FRONTENDS_SERVERS</code></td>
      <td><code>"http://localhost:3001,<wbr>http://localhost:3002"</code><br><code>"https://app.com,<wbr>https://admin.com"</code></td>
      <td>Se parsea como lista separada por comas y se usa para configurar CORS del gateway. Define que frontends pueden consumir el API desde el navegador; si un origen no esta incluido, el browser bloqueara la solicitud aunque el backend este funcionando.</td>
    </tr>
    <tr>
      <td><code>PVT_BE_API_SERVER</code></td>
      <td><code>"http://localhost:8000"</code><br><code>"https://api.pvt.com"</code></td>
      <td>Es la URL base de la integracion PVT BE. El codigo le concatena <code>/api/v1</code>, asi que esta variable debe contener solo la raiz del servicio y no repetir ese sufijo; si se configura mal, todas las llamadas hacia esa integracion saldran a endpoints incorrectos.</td>
    </tr>
    <tr>
      <td><code>PVT_BACKEND_API_SERVER</code></td>
      <td><code>"http://localhost:8001"</code><br><code>"https://backend.pvt.com"</code></td>
      <td>Es la URL base del backend PVT usado por consultas de prestamos y otras operaciones. El gateway le concatena <code>/api</code>, por lo que el valor debe representar la raiz del servidor y no una ruta ya completada.</td>
    </tr>
    <tr>
      <td><code>PVT_HASH_SECRET</code></td>
      <td><code>"secret"</code><br><code>"super_secret_key"</code></td>
      <td>Secreto que el gateway usa para validar tokens hash de ciertas peticiones integradas con PVT. Si no coincide con el emisor del hash, el guard rechazara la peticion aunque el resto de la configuracion sea correcta.</td>
    </tr>
    <tr>
      <td><code>FTP_HOST</code></td>
      <td><code>192.168.2.100</code><br><code>ftp.server.com</code></td>
      <td>Host del servidor FTP al que el gateway se conecta para subir, descargar, listar, borrar y renombrar archivos. Si este host no resuelve o no acepta la conexion, todas las operaciones documentales del gateway fallaran.</td>
    </tr>
    <tr>
      <td><code>FTP_USERNAME</code></td>
      <td><code>test_pruebas</code><br><code>admin</code></td>
      <td>Usuario con el que el gateway autentica la sesion FTP. Debe tener permisos sobre el arbol que cuelga de <code>FTP_ROOT</code>; sin esos permisos puede haber conexion exitosa pero fallos al crear carpetas, mover o leer archivos.</td>
    </tr>
    <tr>
      <td><code>FTP_PASSWORD</code></td>
      <td><code>test</code><br><code>secure123</code></td>
      <td>Contrasena del usuario FTP. Forma parte de la autenticacion inicial al abrir la sesion y, si es invalida, el gateway no podra usar ningun flujo que dependa de almacenamiento remoto.</td>
    </tr>
    <tr>
      <td><code>FTP_ROOT</code></td>
      <td><code>"/test_pruebas"</code><br><code>"/data/files"</code></td>
      <td>Ruta raiz sobre la que el gateway concatena las rutas remotas recibidas desde otros servicios. Funciona como prefijo comun para <code>upload</code>, <code>download</code>, <code>list</code>, <code>remove</code> y <code>rename</code>; conviene normalizarla como path interno que empiece con <code>/</code> y no termine con <code>/</code> para evitar separadores duplicados.</td>
    </tr>
    <tr>
      <td><code>FTP_SSL</code></td>
      <td><code>false</code><br><code>true</code></td>
      <td>Indica si la conexion FTP debe abrirse en modo seguro. Afecta el parametro <code>secure</code> del cliente <code>basic-ftp</code>; si no coincide con la configuracion del servidor remoto, la conexion puede ser rechazada antes de autenticar.</td>
    </tr>
    <tr>
      <td><code>SMS_SERVER_URL</code></td>
      <td><code>"http://172.16.1.20/goip/en"</code><br><code>"https://sms.provider.com/api"</code></td>
      <td>Es la URL base del proveedor SMS. El servicio la usa como prefijo literal para construir llamadas a <code>dosend.php</code> y <code>resend.php</code>, asi que el formato exacto del valor importa y debe probarse con el proveedor real para evitar URLs mal concatenadas.</td>
    </tr>
    <tr>
      <td><code>SMS_SERVER_ROOT</code></td>
      <td><code>"root"</code><br><code>"user1"</code></td>
      <td>Usuario o identificador esperado por el proveedor SMS en el parametro <code>USERNAME</code>. Es parte de la credencial funcional de la peticion, no solo un dato decorativo.</td>
    </tr>
    <tr>
      <td><code>SMS_SERVER_PASSWORD</code></td>
      <td><code>"TEST1234"</code><br><code>"pass123"</code></td>
      <td>Contrasena que el gateway envia al proveedor SMS junto con el usuario. Si es incorrecta, el proveedor puede responder error o negar el envio aunque la URL y el resto de parametros sean validos.</td>
    </tr>
    <tr>
      <td><code>SMS_PROVIDER</code></td>
      <td><code>"1"</code><br><code>"2"</code></td>
      <td>Identificador del canal o proveedor SMS que se manda como <code>smsprovider</code>. Permite seleccionar una ruta de salida concreta cuando el proveedor maneja multiples modems o canales.</td>
    </tr>
    <tr>
      <td><code>WHATSAPP_SERVER_URL</code></td>
      <td><code>"http://localhost:3100"</code><br><code>"https://wa.service.com"</code></td>
      <td>Es la URL base del integrador de WhatsApp. El gateway publica sobre <code>/whatsapp/send</code>; si esta variable esta vacia o apunta a otro servicio, el envio por WhatsApp fallara aunque el endpoint del gateway siga disponible.</td>
    </tr>
    <tr>
      <td><code>CITIZENSHIP_DIGITAL_CLIENT_URL</code></td>
      <td><code>"https://proveedor.bo"</code><br><code>"https://auth.service.com"</code></td>
      <td>URL base del proveedor OAuth de ciudadania digital. A partir de ella el gateway arma llamadas a <code>/token</code>, <code>/me</code> y <code>/session/end</code>, por lo que debe apuntar a la raiz correcta del proveedor.</td>
    </tr>
    <tr>
      <td><code>CITIZENSHIP_DIGITAL_CLIENT_ID</code></td>
      <td><code>"YYYYYYYYYYYYYYYY"</code><br><code>"ABC123XYZ"</code></td>
      <td>Identificador oficial del cliente registrado ante el proveedor de ciudadania digital. Se envia en el flujo OAuth para que el proveedor sepa que aplicacion esta pidiendo el token y los datos del usuario.</td>
    </tr>
    <tr>
      <td><code>CITIZENSHIP_DIGITAL_REDIRECT_URI</code></td>
      <td><code>"com.app.pvt:/oauth2redirect"</code><br><code>"https://app.com/callback"</code></td>
      <td>URI de retorno usada al intercambiar el <code>authorization_code</code>. Debe coincidir exactamente con la registrada en el proveedor; una discrepancia rompe el flujo OAuth aun cuando el usuario autentique correctamente.</td>
    </tr>
    <tr>
      <td><code>CITIZENSHIP_DIGITAL_SCOPES</code></td>
      <td><code>"openid profile fecha_nacimiento email celular offline_access"</code><br><code>"openid email"</code></td>
      <td>Conjunto de permisos o claims que el gateway solicita al proveedor de identidad. Define que datos del ciudadano pueden devolverse al sistema y que tipo de acceso complementario, como <code>offline_access</code>, se pide durante la autenticacion.</td>
    </tr>
  </tbody>
</table>

<a id="3.2-variables-de-auth-service"></a>
## 3.2. Variables de `Auth-Service`

Archivo documentado: `Auth-Service/.env.compose.template`

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Variable</th>
      <th width="22%">Valor de ejemplo</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>DB_SCHEMA</code></td>
      <td><code>auth</code><br><code>public</code></td>
      <td>Define el schema PostgreSQL sobre el que corre <code>Auth-Service</code>. Permite aislar tablas de autenticacion dentro de una base compartida; si apunta al schema equivocado, TypeORM buscara usuarios, sesiones o entidades de auth en otra zona de la base.</td>
    </tr>
    <tr>
      <td><code>LDAP_AUTHENTICATION</code></td>
      <td><code>true</code><br><code>false</code></td>
      <td>Bandera operativa pensada para habilitar o deshabilitar la autenticacion LDAP. Aunque el codigo actual no muestra un consumo fuerte de esta clave en todos los flujos, su sentido es controlar si la fuente de identidad externa LDAP debe considerarse activa.</td>
    </tr>
    <tr>
      <td><code>LDAP_HOST</code></td>
      <td><code>localhost</code><br><code>ldap.server.com</code></td>
      <td>Host del servidor LDAP al que se conectara la estrategia de autenticacion. Si no resuelve o no responde, el servicio no podra validar credenciales contra el directorio externo.</td>
    </tr>
    <tr>
      <td><code>LDAP_PORT</code></td>
      <td><code>389</code><br><code>636</code></td>
      <td>Puerto TCP del servidor LDAP. Debe coincidir con el protocolo y la configuracion del directorio; un puerto incorrecto produce fallos de conexion antes de llegar a la busqueda o validacion del usuario.</td>
    </tr>
    <tr>
      <td><code>LDAP_ADMIN_PREFIX</code></td>
      <td><code>cn</code><br><code>uid</code></td>
      <td>Prefijo del identificador usado para construir el <code>bindDN</code> del administrador LDAP. Forma parte de la sintaxis del DN y debe coincidir con la estructura real del directorio, por ejemplo <code>cn=admin</code> o <code>uid=admin</code>.</td>
    </tr>
    <tr>
      <td><code>LDAP_ADMIN_USERNAME</code></td>
      <td><code>root</code><br><code>admin</code></td>
      <td>Nombre del usuario administrador que se usa en el bind tecnico al servidor LDAP. Es la parte variable que se combina con el prefijo y la base DN para formar el usuario con el que el servicio abre la sesion en el directorio.</td>
    </tr>
    <tr>
      <td><code>LDAP_ADMIN_PASSWORD</code></td>
      <td><code>password</code><br><code>secure_pass</code></td>
      <td>Contrasena del usuario administrador LDAP. Sin ella el servicio no puede hacer bind contra el directorio y, por tanto, tampoco consultar o validar usuarios desde LDAP.</td>
    </tr>
    <tr>
      <td><code>LDAP_ACCOUNT_PREFIX</code></td>
      <td><code>uid</code><br><code>cn</code></td>
      <td>Prefijo pensado para la forma en que se identifican las cuentas de usuario final en el directorio. Aunque no siempre se consume de manera explicita en todos los flujos del codigo, documenta la convencion con la que deberian construirse o buscarse los DNs de usuario.</td>
    </tr>
    <tr>
      <td><code>LDAP_ACCOUNT_SUFFIX</code></td>
      <td><code>"o=users"</code><br><code>"ou=people"</code></td>
      <td>Rama organizacional donde viven las cuentas LDAP del usuario final. Sirve para completar la ruta del arbol LDAP; si no coincide con la estructura real, el servicio buscara usuarios en la rama equivocada y no encontrara resultados.</td>
    </tr>
    <tr>
      <td><code>LDAP_BASEDN</code></td>
      <td><code>"dc=example,dc=com"</code><br><code>"dc=company,dc=com"</code></td>
      <td>Base DN usada para bind y para busquedas dentro del directorio. Es uno de los datos mas sensibles del setup LDAP, porque define desde que punto del arbol se buscan identidades; si es incorrecto, el servicio puede conectar pero no hallar usuarios.</td>
    </tr>
    <tr>
      <td><code>JWT_SECRET</code></td>
      <td><code>"your_jwt_secret"</code><br><code>"super_secret_key"</code></td>
      <td>Secreto criptografico con el que se firman y verifican los JWT del servicio. Cambiarlo invalida los tokens ya emitidos y obliga a que emisor y validador usen exactamente el mismo valor para aceptar los tokens nuevos.</td>
    </tr>
    <tr>
      <td><code>API_KEY</code></td>
      <td><code>"internal-service-key"</code><br><code>"api_key_123"</code></td>
      <td>Llave interna usada para verificar integraciones de confianza entre servicios o consumidores autorizados. Su objetivo es añadir una capa de control simple para llamadas internas que no dependen del login de un usuario final.</td>
    </tr>
    <tr>
      <td><code>USER_TEST_DEVICE</code></td>
      <td><code>99999</code><br><code>12345</code></td>
      <td>Identificador de dispositivo o usuario reservado para pruebas. Se usa junto con <code>USER_TEST_ACCESS</code> para habilitar accesos controlados sin depender del flujo normal de autenticacion.</td>
    </tr>
    <tr>
      <td><code>USER_TEST_ACCESS</code></td>
      <td><code>false</code><br><code>true</code></td>
      <td>Activa o desactiva el bypass de acceso para el dispositivo o usuario de pruebas. Cuando vale <code>true</code>, el servicio puede permitir ingreso directo en escenarios de QA o soporte; cuando vale <code>false</code>, ese atajo queda bloqueado.</td>
    </tr>
  </tbody>
</table>

<a id="3.2-variables-de-beneficiary-service"></a>
<a id="3.3-variables-de-beneficiary-service"></a>
## 3.3. Variables de `Beneficiary-Service`

Archivo documentado: `Beneficiary-Service/.env.compose.template`

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Variable</th>
      <th width="22%">Valor de ejemplo</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>DB_SCHEMA</code></td>
      <td><code>beneficiaries</code><br><code>public</code></td>
      <td>Define el schema PostgreSQL propio del servicio de beneficiarios. Gracias a este valor, las entidades del modulo quedan separadas de otros dominios aunque compartan la misma base fisica.</td>
    </tr>
    <tr>
      <td><code>PATH_FTP_FINGERPRINTS</code></td>
      <td><code>"/Person/Fingerprints"</code><br><code>"/Users/Biometrics"</code></td>
      <td>Ruta base donde se guardan y consultan huellas digitales. El servicio le agrega subcarpetas como <code>/${personId}/</code> y luego el nombre del archivo WSQ; si la base esta mal formada, las huellas se registraran o buscaran en una ubicacion distinta.</td>
    </tr>
    <tr>
      <td><code>PATH_FTP_DOCUMENTS</code></td>
      <td><code>"/Affiliate/Documents"</code><br><code>"/Users/Documents"</code></td>
      <td>Ruta base de los documentos del afiliado. El servicio construye sobre ella paths del tipo <code>/${affiliateId}/archivo.pdf</code>, por lo que esta variable define el punto del arbol FTP en el que se organizan los documentos administrativos del afiliado.</td>
    </tr>
    <tr>
      <td><code>PATH_FTP_FILE_DOSSIERS</code></td>
      <td><code>"/Affiliate/FileDossiers"</code><br><code>"/Users/Dossiers"</code></td>
      <td>Ruta base para expedientes o dossiers del afiliado. Funciona igual que la de documentos, pero para otro conjunto documental; el codigo le agrega carpetas por afiliado y luego nombres de archivos asociados al expediente.</td>
    </tr>
    <tr>
      <td><code>PATH_FTP_IMPORT_DOCUMENTS_PVTBE</code></td>
      <td><code>"/documentos_pvtbe"</code><br><code>"/imports/pvtbe"</code></td>
      <td>Ruta FTP desde la que se toman o analizan documentos importados desde PVTBE. No solo identifica una carpeta remota, sino el origen operativo de un flujo de importacion que luego se cruza con la estructura documental del afiliado.</td>
    </tr>
  </tbody>
</table>

<a id="3.3-servicios-cuyo-envcompose-solo-define-dbschema"></a>
Los siguientes microservicios comparten un patron simple: su `.env.compose.template` solo agrega `DB_SCHEMA`, pero aun asi conviene documentarlos por separado porque ese valor define el namespace real de tablas que TypeORM usara dentro de PostgreSQL.

<a id="3.4-variables-de-global-service"></a>
## 3.4. Variables de `Global-Service`

Archivo documentado: `Global-Service/.env.compose.template`

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Variable</th>
      <th width="22%">Valor de ejemplo</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>DB_SCHEMA</code></td>
      <td><code>global</code><br><code>public</code></td>
      <td>Define el schema PostgreSQL del servicio global. En la practica separa catalogos, maestros o entidades comunes del resto del sistema para que TypeORM apunte al espacio correcto al consultar y persistir informacion.</td>
    </tr>
  </tbody>
</table>

Nota tecnica: `src/config/envs.ts` si define `DB_SCHEMA` con default `global`, pero declararlo en `.env.compose.template` evita depender de defaults implicitos.

<a id="3.5-variables-de-kiosk-service"></a>
## 3.5. Variables de `Kiosk-Service`

Archivo documentado: `Kiosk-Service/.env.compose.template`

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Variable</th>
      <th width="22%">Valor de ejemplo</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>DB_SCHEMA</code></td>
      <td><code>kiosk</code><br><code>beneficiaries</code></td>
      <td>Define el schema PostgreSQL del servicio de kiosco. Es la pieza que separa las tablas del kiosco del resto de modulos cuando todos viven en la misma base fisica; si se deja otro schema, el servicio puede terminar leyendo tablas que no le pertenecen.</td>
    </tr>
  </tbody>
</table>

Nota tecnica: `src/config/envs.ts` deja `beneficiaries` como default, asi que en este servicio es especialmente importante fijar `DB_SCHEMA` de forma explicita en `.env.compose.template`.

<a id="3.6-variables-de-app-mobile-service"></a>
## 3.6. Variables de `App-Mobile-Service`

Archivo documentado: `App-Mobile-Service/.env.compose.template`

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Variable</th>
      <th width="22%">Valor de ejemplo</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>DB_SCHEMA</code></td>
      <td><code>app_mobile</code><br><code>public</code></td>
      <td>Define el schema PostgreSQL reservado para el servicio movil. Gracias a esta clave, las entidades del dominio mobile quedan agrupadas bajo un mismo namespace y no se mezclan con tablas de otros microservicios.</td>
    </tr>
  </tbody>
</table>

Nota tecnica: `src/config/envs.ts` exporta `dbSchema`, pero Joi no lo valida como requerido; por eso el `.env.compose.template` sigue siendo la referencia practica para este valor.

<a id="3.7-variables-de-records-service"></a>
## 3.7. Variables de `Records-Service`

Archivo documentado: `Records-Service/.env.compose.template`

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Variable</th>
      <th width="22%">Valor de ejemplo</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>DB_SCHEMA</code></td>
      <td><code>records</code><br><code>public</code></td>
      <td>Define el schema PostgreSQL del servicio de records. Todas las operaciones de TypeORM sobre historiales, trazas o entidades del modulo se resolveran dentro de ese schema, no en cualquier otro namespace de la base.</td>
    </tr>
  </tbody>
</table>

Nota tecnica: `src/config/envs.ts` no marca `DB_SCHEMA` ni el resto del bloque DB como requerido, aunque `data-source.ts` si necesita esos valores para inicializar TypeORM.

<a id="3.8-variables-de-loans-service"></a>
## 3.8. Variables de `Loans-Service`

Archivo documentado: `Loans-Service/.env.compose.template`

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Variable</th>
      <th width="22%">Valor de ejemplo</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>DB_SCHEMA</code></td>
      <td><code>loans</code><br><code>public</code></td>
      <td>Define el schema PostgreSQL del servicio de prestamos. Es el valor que delimita donde TypeORM debe buscar y mantener las tablas de este dominio financiero dentro de la base compartida.</td>
    </tr>
  </tbody>
</table>

Nota tecnica: `src/config/envs.ts` valida `NATS_SERVERS`, pero no exige el bloque DB completo; aun asi `data-source.ts` usa `dbSchema` y el resto de credenciales para conectarse.

<a id="3.9-variables-de-contributions-service"></a>
## 3.9. Variables de `Contributions-Service`

Archivo documentado: `Contributions-Service/.env.compose.template`

<table width="100%">
  <thead>
    <tr>
      <th width="24%">Variable</th>
      <th width="22%">Valor de ejemplo</th>
      <th width="54%">Funcion</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>DB_SCHEMA</code></td>
      <td><code>contributions</code><br><code>public</code></td>
      <td>Define el schema PostgreSQL del servicio de contribuciones. Su rol es reservar el namespace donde viven las tablas del modulo para que la conexion de TypeORM no se mezcle con esquemas ajenos.</td>
    </tr>
  </tbody>
</table>

Nota tecnica: `src/config/envs.ts` tampoco obliga `DB_SCHEMA`, pero `data-source.ts` lo usa al crear la conexion, asi que documentarlo explicitamente ayuda a evitar errores silenciosos.

Ir al [README.md](./README.md)
