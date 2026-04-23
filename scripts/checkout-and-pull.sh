#!/bin/bash

set -e

# Obtener submódulos desde .gitmodules
submodules=($(grep 'path = ' .gitmodules | awk '{print $3}'))

# ─── Seleccionar remoto ────────────────────────────────────────────
echo ""
echo "🌐 ¿Desde qué remoto quieres traer los cambios?"
echo "  1. origin"
echo "  2. upstream"

read -p $'\nSeleccione el remoto (por número): ' remote_selection

case "$remote_selection" in
  1) remote="origin" ;;
  2) remote="upstream" ;;
  *) echo "❌ Opción inválida."; exit 1 ;;
esac

echo "✔️  Remoto seleccionado: $remote"

# ─── Seleccionar submódulo ─────────────────────────────────────────
echo ""
echo "📦 Submódulos disponibles:"
for i in "${!submodules[@]}"; do
  echo "  $((i+1)). ${submodules[$i]}"
done
echo "  0. Todos"s

read -p $'\nSeleccione un submódulo para actualizar (por número): ' selection

if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 0 ] && [ "$selection" -le "${#submodules[@]}" ]; then
  if [ "$selection" -eq 0 ]; then
    selected=("${submodules[@]}")
  else
    selected=("${submodules[$((selection-1))]}")
  fi
else
  echo "❌ Opción inválida."
  exit 1
fi

# ─── Seleccionar rama ──────────────────────────────────────────────
read -p $'\n🔀 Ingrese el nombre de la rama a usar: ' branch

if [ -z "$branch" ]; then
  echo "❌ No se proporcionó ninguna rama."
  exit 1
fi

# ─── Proyecto principal ────────────────────────────────────────────
echo -e "\n📁 Cambiando rama en el proyecto principal..."
git fetch "$remote"
git checkout "$branch" || { echo "❌ La rama '$branch' no existe en el proyecto principal"; exit 1; }
git pull "$remote" "$branch"

# ─── Submódulos ───────────────────────────────────────────────────
echo -e "\n🔄 Cambiando a rama '$branch' en submódulos seleccionados..."
for sub in "${selected[@]}"; do
  echo "📦 $sub"
  (
    cd "$sub"
    git fetch "$remote"
    git checkout "$branch" || { echo "⚠️  La rama '$branch' no existe en $sub"; exit 1; }
    git pull "$remote" "$branch"
  )
done

echo -e "\n✅ Checkout y actualización completados desde '$remote' en rama '$branch'."