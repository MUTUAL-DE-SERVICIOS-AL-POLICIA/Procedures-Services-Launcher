<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('totp','userLabel'); section>
  <#if section = "header">
    ${msg("loginTotpTitle")}
  <#elseif section = "form">
    <ol id="kc-totp-settings">
      <li>
        <p>${kcSanitize(msg("loginTotpStep1"))?no_esc}</p>
        <ul id="kc-totp-supported-apps">
          <#list totp.supportedApplications as app>
            <li>${kcSanitize(msg(app))?no_esc}</li>
          </#list>
        </ul>
      </li>

      <li>
        <p>${msg("loginTotpStep2")}</p>
        <img id="kc-totp-secret-qr-code" src="data:image/png;base64, ${totp.totpSecretQrCode}" alt="Figure: Barcode"/>
        <br/>
        <a href="#" id="kc-totp-secret-key-toggle">${msg("loginTotpUnableToScan")}</a>
        <div id="kc-totp-secret-key" style="display:none">
          <p style="font-size:0.85rem;color:#555;margin-bottom:4px;">
            Si no puedes escanear el código QR, ingresa manualmente esta clave en tu aplicación autenticadora
            (FreeOTP, Google Authenticator, etc.) seleccionando la opción <strong>"Ingresar clave manualmente"</strong> o <strong>"Agregar cuenta manualmente"</strong>:
          </p>
          <span style="display:block;font-family:monospace;font-size:1.1rem;letter-spacing:2px;background:#f4f4f4;padding:8px 12px;border-radius:6px;word-break:break-all;">${totp.totpSecretEncoded}</span>
        </div>
      </li>

      <li>
        <p>${msg("loginTotpStep3")}</p>
        <p><strong>${msg("loginTotpStep3DeviceName")}</strong></p>
      </li>
    </ol>

    <form action="${url.loginAction}" class="${properties.kcFormClass!}" id="kc-totp-settings-form" method="post">
      <input type="hidden" id="totpSecret" name="totpSecret" value="${totp.totpSecret}"/>
      <div class="${properties.kcFormGroupClass!}">
        <div class="${properties.kcLabelWrapperClass!}">
          <label for="totp" class="${properties.kcLabelClass!}">${msg("authenticatorCode")}</label>
          <span class="${properties.kcLabelClass!} ${properties.kcLabelPrimaryClass!}">*</span>
        </div>
        <div class="${properties.kcInputWrapperClass!}">
          <input type="text" id="totp" name="totp" autocomplete="off"
                 class="${properties.kcInputClass!}"
                 aria-invalid="<#if messagesPerField.existsError('totp')>true</#if>"/>
          <#if messagesPerField.existsError('totp')>
            <span id="input-error-otp-code" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
              ${kcSanitize(messagesPerField.get('totp'))?no_esc}
            </span>
          </#if>
        </div>
      </div>

      <div class="${properties.kcFormGroupClass!}">
        <div class="${properties.kcLabelWrapperClass!}">
          <label for="userLabel" class="${properties.kcLabelClass!}">${msg("loginTotpDeviceName")}</label>
          <#if totp.otpCredentials?size gte 1>
            <span class="${properties.kcLabelClass!} ${properties.kcLabelPrimaryClass!}">*</span>
          </#if>
        </div>
        <div class="${properties.kcInputWrapperClass!}">
          <input type="text" id="userLabel" name="userLabel" autocomplete="off"
                 class="${properties.kcInputClass!}"
                 aria-invalid="<#if messagesPerField.existsError('userLabel')>true</#if>"/>
          <#if messagesPerField.existsError('userLabel')>
            <span id="input-error-otp-label" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
              ${kcSanitize(messagesPerField.get('userLabel'))?no_esc}
            </span>
          </#if>
        </div>
      </div>

      <#if isAppInitiatedAction??>
        <input type="checkbox" id="logout-sessions" name="logout-sessions" value="on" checked/>
        <label for="logout-sessions">${msg("logoutOtherSessions")}</label>
      </#if>

      <div class="${properties.kcFormGroupClass!}">
        <div id="kc-form-buttons" class="${properties.kcFormButtonsClass!}">
          <input type="submit" class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonLargeClass!}"
                 id="saveTOTPBtn" value="${msg("doSubmit")}"/>
          <#if isAppInitiatedAction??>
            <button type="submit" class="${properties.kcButtonClass!} ${properties.kcButtonDefaultClass!} ${properties.kcButtonLargeClass!}"
                    id="cancelTOTPBtn" name="cancel-aia" value="true">${msg("doCancel")}</button>
          </#if>
        </div>
      </div>
    </form>
  </#if>
</@layout.registrationLayout>
