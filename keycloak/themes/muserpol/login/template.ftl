<#-- template.ftl -->
<#macro registrationLayout
  displayInfo=false
  displayMessage=false
  displayWide=false
  showAnotherWay=false
  isAppInitiatedAction=false
  showTryAnotherWayLink=false
  showResetCredentials=false
  bodyClass=""
  displayRequiredFields=false
  showDoLogIn=false
  showSignUpLink=false
  showUsername=false
  showPassword=false
  showBack=false
>


<!DOCTYPE html>
<html lang="${(locale!{'currentLanguageTag':'es'}).currentLanguageTag}">
<head>
  <meta charset="utf-8"/>
  <title>Login MUSERPOL</title>
  <link rel="icon" type="image/png" href="${url.resourcesPath}/img/muserpol-icon.png"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <link rel="stylesheet" href="${url.resourcesPath}/css/login.css"/>
</head>
<body class="kc-body ${bodyClass}">
  <div class="kc-shell">
    <div class="kc-card">
    <!-- Lado visual (sin borde negro ni texto encima) -->
    <aside class="kc-visual">
      <img src="${url.resourcesPath}/img/building.jpg" alt="MUSERPOL"/>
    </aside>

    <!-- Lado formulario -->
    <section class="kc-form-side">
      <div class="kc-form-wrap"><!-- centrado y ancho fijo -->
        <div class="kc-brand">
          <img class="kc-logo" src="${url.resourcesPath}/img/muserpol-logo.png" alt="MUSERPOL"/>
        </div>

        <h1 class="kc-title"><#nested "header"></h1>

        <#if (displayMessage?? && displayMessage)>
          <div id="kc-messages"><#nested "messages"></div>
        </#if>

        <div class="kc-form"><#nested "form"></div>

        <div class="kc-social"><#nested "socialProviders"></div>

        <#if (displayInfo?? && displayInfo)>
          <div class="kc-info"><#nested "info"></div>
        </#if>

        <footer class="kc-footer">
          <span>&copy; <script>document.write(new Date().getFullYear())</script> MUSERPOL</span>
        </footer>
      </div>
    </section>
    </div>
  </div>

  <#nested "scripts">
  <script defer src="${url.resourcesPath}/js/app.js"></script>
</body>
</html>
</#macro>
