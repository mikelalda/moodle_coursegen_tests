<#
Instala Moodle (admin/cli/install.php) dentro del contenedor moodle, usando
los valores definidos en .env. Ejecutar solo una vez, despues de
'docker compose up -d' y con la base de datos ya arriba.
#>

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Push-Location $root
try {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*)\s*$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }

    docker compose exec -T moodle php admin/cli/install.php `
        --non-interactive `
        --agree-license `
        --lang=es `
        --wwwroot=$env:MOODLE_WWWROOT `
        --dataroot=/var/www/moodledata `
        --dbtype=mariadb `
        --dbhost=db `
        --dbname=$env:MOODLE_DB_NAME `
        --dbuser=$env:MOODLE_DB_USER `
        --dbpass=$env:MOODLE_DB_PASSWORD `
        --fullname=$env:MOODLE_SITE_NAME `
        --shortname=$env:MOODLE_SHORTNAME `
        --adminuser=$env:MOODLE_ADMIN_USER `
        --adminpass=$env:MOODLE_ADMIN_PASSWORD `
        --adminemail=$env:MOODLE_ADMIN_EMAIL

    # En Windows, los binds de Docker Desktop dejan config.php como root:root 0640,
    # ilegible para el proceso www-data de Apache. Lo corregimos tras instalar.
    docker compose exec -T moodle chmod 644 /var/www/html/config.php

    Write-Host ""
    Write-Host "Instalacion completada. Sitio disponible en $env:MOODLE_WWWROOT"
    Write-Host "Usuario admin: $env:MOODLE_ADMIN_USER"
}
finally {
    Pop-Location
}
