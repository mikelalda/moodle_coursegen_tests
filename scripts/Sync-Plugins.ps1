<#
Escanea modules/ buscando carpetas de plugin (cualquier directorio que contenga
un version.php, marcador estandar de plugin de Moodle) y genera
docker-compose.override.yml con un bind mount por plugin, replicando su ruta
relativa dentro del codigo de Moodle (./modules/local/foo -> /var/www/html/local/foo).

Tras anadir o quitar carpetas en modules/, ejecuta este script y luego:
    docker compose up -d
#>

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$modulesDir = Join-Path $root "modules"
$overrideFile = Join-Path $root "docker-compose.override.yml"

if (-not (Test-Path $modulesDir)) {
    Write-Host "No existe la carpeta modules/."
    exit 1
}

$versionDirs = Get-ChildItem -Path $modulesDir -Recurse -Filter "version.php" -File -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Directory } |
    Sort-Object FullName -Unique

# Conserva solo las raices de plugin de nivel superior: descarta cualquier
# version.php anidado dentro de otro plugin (subplugins, fixtures de tests),
# ya que su bind mount quedaria solapado por el del plugin padre.
$pluginDirs = $versionDirs | Where-Object {
    $current = $_
    -not ($versionDirs | Where-Object {
        $_.FullName -ne $current.FullName -and
        $current.FullName.StartsWith($_.FullName + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
    })
}

if (-not $pluginDirs) {
    Write-Host "No se encontro ningun plugin (ningun version.php) bajo modules/."
    if (Test-Path $overrideFile) {
        Remove-Item $overrideFile
        Write-Host "Se elimino docker-compose.override.yml existente."
    }
    exit 0
}

$lines = @("services:", "  moodle:", "    volumes:")

foreach ($dir in $pluginDirs) {
    $relPath = $dir.FullName.Substring($modulesDir.Length + 1) -replace '\\', '/'
    $lines += "      - ./modules/${relPath}:/var/www/html/${relPath}"
    Write-Host "Plugin detectado: $relPath"
}

($lines -join "`n") + "`n" | Set-Content -Path $overrideFile -Encoding utf8 -NoNewline

Write-Host ""
Write-Host "Generado docker-compose.override.yml con $($pluginDirs.Count) plugin(s)."
Write-Host "Ejecuta 'docker compose up -d' para aplicar los cambios, y luego visita /admin para instalarlos."
