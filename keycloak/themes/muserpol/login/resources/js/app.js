
const pwd = document.querySelector("#password") || document.querySelector("input[type='password']");
if (pwd) {
  pwd.addEventListener("keyup", (e) => {
    const isCaps = e.getModifierState && e.getModifierState("CapsLock");
    let hint = document.getElementById("caps-hint");
    if (!hint) {
      hint = document.createElement("div");
      hint.id = "caps-hint";
      hint.className = "kc-help-text";
      pwd.parentElement.appendChild(hint);
    }
    hint.textContent = isCaps ? "Bloq Mayús activado" : "";
  });
}

const toggle = document.getElementById("kc-totp-secret-key-toggle");
if (toggle) {
  toggle.addEventListener("click", (e) => {
    e.preventDefault();
    const box = document.getElementById("kc-totp-secret-key");
    box.style.display = box.style.display === "none" ? "block" : "none";
  });
}
