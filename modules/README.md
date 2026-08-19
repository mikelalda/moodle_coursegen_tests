# Carpeta de plugins

Coloca aquí los plugins que quieras probar, replicando la ruta que tendrían
dentro de Moodle (ver tabla en el README principal). Ejemplos ya creados como
guía:

```
modules/local/
modules/blocks/
modules/mod/
modules/ai/provider/
modules/theme/
modules/filter/
modules/question/
modules/qtype/
modules/availability/
modules/admin/tool/
modules/auth/
```

Cualquier carpeta (en cualquier nivel) que contenga un `version.php` se
detecta como plugin al ejecutar `scripts/sync-plugins.sh` (o
`scripts/Sync-Plugins.ps1` en PowerShell). No es necesario
que uses exactamente estas carpetas de ejemplo: puedes crear otras rutas
válidas de Moodle (p. ej. `modules/qbehaviour/<nombre>`,
`modules/enrol/<nombre>`, `modules/repository/<nombre>`...).

Después de añadir o quitar plugins:

```bash
../scripts/sync-plugins.sh
docker compose up -d
```
