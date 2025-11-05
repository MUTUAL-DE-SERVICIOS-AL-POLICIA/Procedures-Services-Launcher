#!/bin/bash

set -e

# Preguntar si se debe usar docker-compose.prod.yml
read -p $'\n¿Usar archivo de producción (docker-compose.prod.yml)? [s/N]: ' use_prod

# Establecer comando base de docker compose
if [[ "$use_prod" =~ ^[sS]$ ]]; then
  dc="docker compose -f docker-compose.prod.yml"
else
  dc="docker compose"
fi

# Obtener servicios activos EXCLUYENDO los que empiezan por "nats"
mapfile -t services < <($dc ps --services --filter status=running | grep -vE '^nats')

if [ ${#services[@]} -eq 0 ]; then
  echo "⚠️  No hay servicios en ejecución."
  exit 1
fi

# Mostrar lista de servicios
echo ""
echo "Servicios activos:"
for i in "${!services[@]}"; do
  echo "  $((i+1)). ${services[$i]}"
done
echo "  0. Todos"

# Selección del servicio
read -p $'\nSeleccione un servicio para build y restart (por número): ' selection

if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 0 ] && [ "$selection" -le "${#services[@]}" ]; then
  if [ "$selection" -eq 0 ]; then
    selected=("${services[@]}")
  else
    selected=("${services[$((selection-1))]}")
  fi
else
  echo "❌ Opción inválida."
  exit 1
fi

# Build y restart
for service in "${selected[@]}"; do
  echo -e "\n🧱 Ejecutando build en: $service"
  $dc exec "$service" yarn build

  echo -e "🔁 Reiniciando: $service"
  $dc restart "$service"
done

echo -e "\n✅ Proceso de build y restart completo."
