#!/usr/bin/env bash
#
# Conecta Moodle con la API del generador de cursos (moodle-ai-provider).
#
# Arregla el error "Error cURL de la API de birtai: Esta URL está bloqueada",
# que tiene tres causas a la vez:
#   1. Moodle solo permite salir por los puertos 80 y 443; la API usa el 8001.
#   2. Moodle bloquea 'localhost' y 127.0.0.0/8 en sus peticiones cURL.
#   3. Dentro del contenedor de Moodle, 'localhost' es el propio Moodle, no la
#      API: hay que llamarla por el nombre de su contenedor.
#
# Se puede volver a ejecutar tantas veces como haga falta (es idempotente).

set -euo pipefail

MOODLE_CONTAINER="${MOODLE_CONTAINER:-moodle_test-moodle-1}"
API_CONTAINER="${API_CONTAINER:-moodle-ai-provider}"
API_URL="http://${API_CONTAINER}:8001"

cfg() {
  docker exec "$MOODLE_CONTAINER" php /var/www/html/admin/cli/cfg.php "$@"
}

echo "==> Comprobando que los contenedores están arrancados"
for c in "$MOODLE_CONTAINER" "$API_CONTAINER"; do
  if ! docker ps --format '{{.Names}}' | grep -qx "$c"; then
    echo "ERROR: el contenedor '$c' no está en marcha." >&2
    echo "       Arranca los dos stacks y vuelve a lanzar este script." >&2
    exit 1
  fi
done

echo "==> Comprobando que Moodle llega a la API"
if ! docker exec "$MOODLE_CONTAINER" curl -sf -m 10 "${API_URL}/health" > /dev/null; then
  echo "ERROR: Moodle no alcanza ${API_URL}." >&2
  echo "       Revisa que moodle-course-generator/docker-compose.yml incluya la" >&2
  echo "       red externa 'moodle_test_default' y recrea el contenedor con:" >&2
  echo "       docker compose -f moodle-course-generator/docker-compose.yml up -d" >&2
  exit 1
fi

# La subred de la red docker de Moodle se consulta en vivo: si algún día se
# recrea la red, Docker puede asignarle otra distinta.
SUBNET=$(docker network inspect moodle_test_default \
  --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')
echo "==> Red docker de Moodle: ${SUBNET}"

if [ "$SUBNET" != "172.21.0.0/16" ]; then
  echo "AVISO: la subred ya no es 172.21.0.0/16." >&2
  echo "       Ajusta la lista de hosts bloqueados de abajo para dejar fuera ${SUBNET}." >&2
fi

echo "==> 1/3 Permitiendo el puerto 8001 en las peticiones cURL de Moodle"
cfg --name=curlsecurityallowedport --set=$'443\n80\n8001'

echo "==> 2/3 Desbloqueando solo la subred docker de Moodle"
# 172.16.0.0/12 se parte en los trozos que NO contienen 172.21.0.0/16, para no
# abrir de golpe todo el rango privado (la lista existe para frenar SSRF).
cfg --name=curlsecurityblockedhosts --set=$'127.0.0.0/8\n192.168.0.0/16\n10.0.0.0/8\n172.16.0.0/14\n172.20.0.0/16\n172.22.0.0/15\n172.24.0.0/13\n0.0.0.0\nlocalhost\n169.254.169.254\n0000::1'

echo "==> 3/3 Apuntando los plugins a ${API_URL}"
cfg --component=aiprovider_birtai --name=local_api_url --set="$API_URL"
cfg --component=local_coursegen --name=birtai_service_url --set="$API_URL"
cfg --component=local_coursegen --name=birtai_service_url_eu --set="$API_URL"

echo
echo "==> Configuración resultante"
echo "--- puertos permitidos ---"
cfg --name=curlsecurityallowedport
echo "--- hosts bloqueados ---"
cfg --name=curlsecurityblockedhosts
echo "--- URL de la API en los plugins ---"
cfg --component=aiprovider_birtai --name=local_api_url
cfg --component=local_coursegen --name=birtai_service_url

echo
echo "==> Estado de la API (backend de IA en uso)"
docker exec "$MOODLE_CONTAINER" curl -s -m 10 "${API_URL}/health"
echo
echo
echo "Listo. Prueba a generar con IA en Moodle."
