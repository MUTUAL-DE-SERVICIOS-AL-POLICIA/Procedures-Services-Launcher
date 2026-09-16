#!/bin/bash

set -e

# ─── Obtener submódulos desde .gitmodules ───────────────────────────
submodules=($(grep 'path = ' .gitmodules | awk '{print $3}'))

# ─── Seleccionar remoto ────────────────────────────────────────────
echo ""
echo "🌐 ¿A qué remoto quieres subir los cambios?"
echo "  1. origin"
echo "  2. upstream"

read -p $'\nSeleccione el remoto (por número): ' remote_selection

case "$remote_selection" in
  1) remote="origin" ;;
  2) remote="upstream" ;;
  *)
    echo "❌ Opción inválida."
    exit 1
    ;;
esac

echo "✔️ Remoto seleccionado: $remote"


# ─── Seleccionar rama ──────────────────────────────────────────────
echo ""
echo "🔀 ¿Qué rama quieres subir?"
echo "  1. dev"
echo "  2. testing"
echo "  3. main"

read -p $'\nSeleccione la rama (por número): ' branch_selection

case "$branch_selection" in
  1) branch="dev" ;;
  2) branch="testing" ;;
  3) branch="main" ;;
  *)
    echo "❌ Opción inválida."
    exit 1
    ;;
esac

echo "✔️ Rama seleccionada: $branch"


# ─── Función para hacer push ───────────────────────────────────────
push_repository() {

  local repo_path="$1"
  local repo_name="$2"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 $repo_name"
  echo "📁 $repo_path"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  (
    cd "$repo_path"

    echo "🔍 Verificando rama '$branch'..."

    # Verificar que la rama exista localmente
    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
      echo "❌ La rama '$branch' no existe localmente en $repo_name."
      exit 1
    fi

    git checkout "$branch"

    echo "🔍 Verificando cambios..."

    # Mostrar estado
    git status --short

    # Verificar si existen cambios sin commit
    if ! git diff --quiet || ! git diff --cached --quiet; then
      echo ""
      echo "⚠️  Hay cambios sin commit en $repo_name."
      echo "❌ No se realizará el push."
      exit 1
    fi

    echo "🔄 Actualizando referencias del remoto..."

    git fetch "$remote"

    echo "⬆️  Subiendo '$branch' → '$remote/$branch'..."

    git push "$remote" "$branch"

    echo "✅ Push completado: $repo_name"
  )
}


# ─── Proyecto principal ────────────────────────────────────────────
echo ""
echo "🚀 INICIANDO PUSH DE TODOS LOS REPOSITORIOS"
echo "🌐 Remoto: $remote"
echo "🔀 Rama:   $branch"


push_repository "." "Proyecto principal"


# ─── Submódulos ───────────────────────────────────────────────────
echo ""
echo "🔄 Procesando submódulos..."

for sub in "${submodules[@]}"; do
  push_repository "$sub" "$sub"
done


# ─── Final ─────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TODOS LOS PUSH FUERON COMPLETADOS"
echo "🌐 Remoto: $remote"
echo "🔀 Rama:   $branch"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"