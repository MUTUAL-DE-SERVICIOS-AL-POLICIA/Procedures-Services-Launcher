#!/bin/bash

set -e

# Obtener submódulos desde .gitmodules
submodules=($(grep 'path = ' .gitmodules | awk '{print $3}'))

# Mostrar submódulos
echo ""
echo "Submódulos disponibles:"
for i in "${!submodules[@]}"; do
  echo "  $((i+1)). ${submodules[$i]}"
done
echo "  0. Todos"

# Solicitar opción
read -p $'\nSeleccione un submódulo para actualizar (por número): ' selection

# Validar opción
if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 0 ] && [ "$selection" -le "${#submodules[@]}" ]; then
  if [ "$selection" -eq 0 ]; then
    selected=("${submodules[@]}")
    build_all=true
  else
    selected=("${submodules[$((selection-1))]}")
    build_all=false
  fi
else
  echo "❌ Opción inválida."
  exit 1
fi

# Preguntar si se debe usar docker-compose.prod.yml
read -p $'\n¿Usar archivo de producción (docker-compose.prod.yml)? [s/N]: ' use_prod

# Establecer comando base de docker compose
if [[ "$use_prod" =~ ^[sS]$ ]]; then
  dc="docker compose -f docker-compose.prod.yml"
else
  dc="docker compose"
fi

# Pedir nombre de la rama
read -p $'\n🔀 Ingrese el nombre de la rama a usar: ' branch

if [ -z "$branch" ]; then
  echo "❌ No se proporcionó ninguna rama."
  exit 1
fi

# Cambiar de rama en el proyecto principal
echo -e "\n📁 Cambiando rama en el proyecto principal..."
git fetch origin
git checkout "$branch" || { echo "❌ La rama '$branch' no existe en el proyecto principal"; exit 1; }
git pull origin "$branch"

# Actualizar submódulos seleccionados
echo -e "\n🔄 Cambiando a rama '$branch' y actualizando submódulos..."
for sub in "${selected[@]}"; do
  echo "📦 $sub"
  (
    cd "$sub"
    git fetch origin
    git checkout "$branch" || { echo "⚠️  La rama '$branch' no existe en $sub"; exit 1; }
    git pull origin "$branch"
  )
done

# Construir solo si es uno
if [ "$build_all" = false ]; then
  sub="${selected[0]}"
  service=$(echo "$sub" | tr '[:upper:]' '[:lower:]')

  echo -e "\n🧱 Ejecutando 'yarn build' en el contenedor: $service"
  $dc exec "$service" yarn build

  echo -e "\n🔁 Reiniciando contenedor: $service"
  $dc restart "$service"

else
  echo -e "\n🧱 Ejecutando 'yarn build' en TODOS los servicios activos..."
  running_services=($($dc ps --services --filter status=running))
  for service in "${running_services[@]}"; do
    echo "🔧 $service"
    $dc exec "$service" yarn build
    $dc restart "$service"
  done
fi

echo -e "\n✅ Proceso completo en rama '$branch'."
