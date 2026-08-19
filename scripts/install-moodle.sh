#!/usr/bin/env bash
#
# Instala Moodle (admin/cli/install.php) dentro del contenedor moodle, usando
# los valores definidos en .env. Ejecutar solo una vez, despues de
# 'docker compose up -d' y con la base de datos ya arriba.

set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if [[ ! -f .env ]]; then
    echo "No existe .env en $root." >&2
    exit 1
fi

# Carga .env sin usar 'source': hay valores sin comillas y con espacios
# (p. ej. MOODLE_SITE_NAME=Moodle Docker Test).
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*([^#=[:space:]]+)[[:space:]]*=[[:space:]]*(.*)$ ]] || continue
    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"
    value="${value%"${value##*[![:space:]]}"}"          # quita espacios finales
    if [[ "$value" == \"*\" || "$value" == \'*\' ]]; then
        value="${value:1:${#value}-2}"                  # quita comillas envolventes
    fi
    export "$key=$value"
done < .env

if [[ ! -f moodle/version.php ]]; then
    echo "moodle/ no contiene el codigo fuente de Moodle (falta version.php)." >&2
    echo "Inicializa el submodulo antes de instalar:" >&2
    echo "  git submodule update --init --recursive" >&2
    exit 1
fi

if [[ -f moodle/config.php ]]; then
    echo "Ya existe moodle/config.php: Moodle parece instalado." >&2
    echo "Borralo (y ejecuta 'docker compose down -v') si quieres reinstalar desde cero." >&2
    exit 1
fi

if [[ -z "$(docker compose ps -q moodle 2>/dev/null)" ]]; then
    echo "El servicio 'moodle' no esta arrancado. Ejecuta antes: docker compose up -d" >&2
    exit 1
fi

# En Linux los bind mounts conservan el UID del host, asi que www-data (uid 33
# dentro del contenedor) no puede escribir en ./moodledata, propiedad del
# usuario del host. 0777 es tambien el valor por defecto de
# $CFG->directorypermissions de Moodle. Se hace dentro del contenedor como root
# porque si 'docker compose up -d' creo el directorio, es propiedad de root y un
# chmod desde el host requeriria sudo.
docker compose exec -T -u 0 moodle chmod 0777 /var/www/moodledata

docker compose exec -T moodle php admin/cli/install.php \
    --non-interactive \
    --agree-license \
    --lang=es \
    --wwwroot="$MOODLE_WWWROOT" \
    --dataroot=/var/www/moodledata \
    --dbtype=mariadb \
    --dbhost=db \
    --dbname="$MOODLE_DB_NAME" \
    --dbuser="$MOODLE_DB_USER" \
    --dbpass="$MOODLE_DB_PASSWORD" \
    --fullname="$MOODLE_SITE_NAME" \
    --shortname="$MOODLE_SHORTNAME" \
    --adminuser="$MOODLE_ADMIN_USER" \
    --adminpass="$MOODLE_ADMIN_PASSWORD" \
    --adminemail="$MOODLE_ADMIN_EMAIL"

# El instalador corre como root dentro del contenedor, asi que config.php queda
# en el bind mount con owner root y modo 0640: ilegible para Apache (www-data) e
# ineditable desde el host. Se devuelve al usuario del host y se deja legible.
docker compose exec -T -u 0 moodle \
    chown "$(id -u):$(id -g)" /var/www/html/config.php
docker compose exec -T -u 0 moodle \
    chmod 644 /var/www/html/config.php

echo
echo "Instalacion completada. Sitio disponible en $MOODLE_WWWROOT"
echo "Usuario admin: $MOODLE_ADMIN_USER"
