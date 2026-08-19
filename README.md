# Moodle 4.5 en Docker — entorno de pruebas para plugins

Entorno local con Moodle 4.5 (`MOODLE_405_STABLE`) + MariaDB, pensado para
desarrollar y probar plugins (módulos) sueltos sin tener que tocar el código
núcleo de Moodle.

## Estructura

```
moodle_container/
├── docker-compose.yml        # Servicios: moodle, db (MariaDB), adminer
├── docker-compose.override.yml  # Generado automaticamente (mounts de plugins)
├── .env                       # Credenciales, puertos, datos de instalacion
├── moodle/                    # Codigo fuente de Moodle (clonado de git, rama 4.5)
├── moodledata/                # moodledata persistente (fuera de moodle/)
├── modules/                   # <- AQUI VAN TUS PLUGINS, ver modules/README.md
└── scripts/
    ├── sync-plugins.sh        # Linux: detecta plugins en modules/ y genera el override
    ├── install-moodle.sh      # Linux: instala Moodle por CLI (solo la primera vez)
    ├── Sync-Plugins.ps1       # Windows/PowerShell: equivalente de sync-plugins.sh
    └── Install-Moodle.ps1     # Windows/PowerShell: equivalente de install-moodle.sh
```

## Primer arranque

Linux:

```bash
git submodule update --init --recursive
docker compose up -d
./scripts/install-moodle.sh
```

Windows (PowerShell):

```powershell
docker compose up -d
.\scripts\Install-Moodle.ps1
```

Sitio en http://localhost:8080 (usuario `admin`, contraseña en `.env`).
Adminer (gestor de la BD) en http://localhost:8081 (servidor `db`, usuario/clave de `.env`).

## Añadir un plugin desde una carpeta del workspace

Los plugins se colocan en `modules/` replicando la ruta que tendrían dentro
de Moodle. El tipo de plugin lo determina la carpeta, no un nombre libre:

| Tipo de plugin      | Ruta dentro de `modules/`        |
|----------------------|-----------------------------------|
| Actividad (mod)      | `modules/mod/<nombre>`            |
| Bloque                | `modules/blocks/<nombre>`         |
| Plugin local          | `modules/local/<nombre>`          |
| Proveedor de IA       | `modules/ai/provider/<nombre>`    |
| Tema                  | `modules/theme/<nombre>`          |
| Filtro                | `modules/filter/<nombre>`         |
| Herramienta de admin  | `modules/admin/tool/<nombre>`     |
| Tipo de pregunta      | `modules/question/type/<nombre>`  |
| Método de autenticación | `modules/auth/<nombre>`         |

Cualquier carpeta que contenga un `version.php` se detecta automáticamente
como plugin, sin importar el tipo, así que esta lista no es cerrada.

Pasos:

1. Copia o enlaza la carpeta del plugin dentro de la ruta correspondiente en
   `modules/` (debe contener su `version.php`).
2. Ejecuta `./scripts/sync-plugins.sh` (o `.\scripts\Sync-Plugins.ps1` en
   PowerShell) — regenera `docker-compose.override.yml` con un bind mount por
   cada plugin encontrado.
3. Aplica los cambios: `docker compose up -d`.
4. Entra en `http://localhost:8080/admin/index.php` para completar la
   instalación/actualización de la base de datos del plugin nuevo (Moodle lo
   detecta solo).

Para quitar un plugin, borra su carpeta de `modules/` y repite los pasos 2-3.

## Comandos útiles

```bash
docker compose exec moodle php admin/cli/purge_caches.php
docker compose exec moodle php admin/cli/upgrade.php --non-interactive
docker compose logs -f moodle
docker compose down          # parar (conserva datos)
docker compose down -v       # parar y borrar tambien la base de datos
```

## Notas

- `moodle/` es un submódulo apuntando a `MOODLE_405_STABLE` del repo oficial,
  declarado como `shallow` para que se clone con `--depth 1` (Moodle es grande).
  Su propio `.gitignore` ya excluye `config.php`, así que el estado del repo
  padre no se ensucia al instalar.
- `moodledata/` y la base de datos (`db_data` volume) persisten entre
  reinicios; bórralos si quieres empezar de cero.
- En Linux los bind mounts conservan el UID del host: `install-moodle.sh` deja
  `moodledata/` en modo `0777` (el mismo valor por defecto que usa Moodle en
  `$CFG->directorypermissions`) para que Apache (`www-data`) pueda escribir, y
  devuelve `moodle/config.php` al usuario del host tras la instalacion.
- La imagen usada (`moodlehq/moodle-php-apache`) es la oficial de Moodle HQ
  para entornos de desarrollo/pruebas, no incluye Moodle preinstalado: el
  código vive en `moodle/` montado como bind mount.
