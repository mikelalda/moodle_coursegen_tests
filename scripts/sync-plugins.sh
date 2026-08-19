#!/usr/bin/env bash
#
# Escanea modules/ buscando carpetas de plugin (cualquier directorio que contenga
# un version.php, marcador estandar de plugin de Moodle) y genera
# docker-compose.override.yml con un bind mount por plugin, replicando su ruta
# relativa dentro del codigo de Moodle (./modules/local/foo -> /var/www/html/local/foo).
#
# Tras anadir o quitar carpetas en modules/, ejecuta este script y luego:
#     docker compose up -d

set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
modules_dir="$root/modules"
override_file="$root/docker-compose.override.yml"

if [[ ! -d "$modules_dir" ]]; then
    echo "No existe la carpeta modules/." >&2
    exit 1
fi

# Directorios que contienen un version.php, ordenados: un padre siempre aparece
# antes que sus descendientes.
mapfile -t version_dirs < <(
    find "$modules_dir" -type f -name version.php -printf '%h\n' | LC_ALL=C sort -u
)

# Conserva solo las raices de plugin de nivel superior: descarta cualquier
# version.php anidado dentro de otro plugin (subplugins, fixtures de tests),
# ya que su bind mount quedaria solapado por el del plugin padre.
plugin_dirs=()
for dir in ${version_dirs[@]+"${version_dirs[@]}"}; do
    nested=false
    for kept in ${plugin_dirs[@]+"${plugin_dirs[@]}"}; do
        if [[ "$dir" == "$kept"/* ]]; then
            nested=true
            break
        fi
    done
    [[ "$nested" == true ]] || plugin_dirs+=("$dir")
done

if [[ ${#plugin_dirs[@]} -eq 0 ]]; then
    echo "No se encontro ningun plugin (ningun version.php) bajo modules/."
    if [[ -f "$override_file" ]]; then
        rm -f "$override_file"
        echo "Se elimino docker-compose.override.yml existente."
    fi
    exit 0
fi

{
    echo "services:"
    echo "  moodle:"
    echo "    volumes:"
    for dir in "${plugin_dirs[@]}"; do
        rel="${dir#"$modules_dir/"}"
        echo "      - ./modules/${rel}:/var/www/html/${rel}"
    done
} > "$override_file"

for dir in "${plugin_dirs[@]}"; do
    echo "Plugin detectado: ${dir#"$modules_dir/"}"
done

echo
echo "Generado docker-compose.override.yml con ${#plugin_dirs[@]} plugin(s)."
echo "Ejecuta 'docker compose up -d' para aplicar los cambios, y luego visita /admin para instalarlos."
