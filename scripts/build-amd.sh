#!/usr/bin/env bash
#
# Compila los modulos JavaScript AMD (amd/src -> amd/build) de uno o varios
# plugins de modules/ con el Grunt del propio Moodle, sin Node en el host: lo
# ejecuta en un contenedor node con la version que pide moodle/.nvmrc.
#
# Las dependencias npm de Moodle se instalan una sola vez en el volumen Docker
# "moodle_node_modules" (no ensucian moodle/). Grunt pasa tambien ESLint: si
# hay errores, el build no se escribe.
#
#     scripts/build-amd.sh                       # local/coursegen
#     scripts/build-amd.sh local/coursegen local/assign_ai
#
# Despues, purga las caches de Moodle para que sirva el JS nuevo:
#     docker compose exec moodle php admin/cli/purge_caches.php

set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
node_image="node:22.12-bookworm"   # moodle/package.json: "node": ">=22.11.0 <23"
plugins=("${@:-local/coursegen}")

# Primera vez: dependencias de Moodle en el volumen.
if ! docker run --rm -v moodle_node_modules:/nm "$node_image" test -x /nm/.bin/grunt; then
    echo "Instalando las dependencias npm de Moodle en el volumen moodle_node_modules..."
    docker run --rm -v "$root/moodle:/moodle" -v moodle_node_modules:/moodle/node_modules \
        -w /moodle "$node_image" npm ci --no-audit --no-fund --ignore-scripts
fi

for plugin in "${plugins[@]}"; do
    plugin="${plugin#/}"
    if [[ ! -d "$root/modules/$plugin/amd/src" ]]; then
        echo "No existe modules/$plugin/amd/src" >&2
        exit 1
    fi
    echo "== $plugin"
    # El plugin se monta en su ruta dentro de Moodle, como en docker-compose.override.yml.
    docker run --rm \
        -v "$root/moodle:/moodle" \
        -v "$root/modules/$plugin:/moodle/$plugin" \
        -v moodle_node_modules:/moodle/node_modules \
        -w "/moodle/$plugin" "$node_image" \
        sh -c "npx grunt amd && chown -R $(id -u):$(id -g) amd/build"
done
