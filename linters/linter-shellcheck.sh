#!/bin/sh

################################################################################
#
#   Lynis SDK — linters/linter-shellcheck.sh v1.1.0
#
# Cambios v1.1.0:
#   - LYNIS_DIR ahora usa LYNIS_PATH del entorno del devkit (no ruta hardcodeada)
#   - Instrucciones de instalación multi-distro (Debian, RHEL/Fedora, macOS, manual)
#   - --format=gcc para integración con IDEs y pipelines CI/CD
#   - Mensajes más claros cuando shellcheck no está disponible
#
################################################################################

# Lynis workflow (referencia):
# lynis → include/consts → include/functions → db/languages/en
# → include/parameters → include/osdetection → include/binaries
# → plugins (fase 1) → tests → tests_custom → helper
# → plugins (fase 2) → include/report → include/tool_tips → include/data_upload

# ---------------------------------------------------------------------------
# Verificar que shellcheck está instalado
# ---------------------------------------------------------------------------
if ! command -v shellcheck > /dev/null 2>&1; then
    printf 'Error: shellcheck no encontrado en PATH.\n\n'
    printf 'Instrucciones de instalación:\n'
    printf '  Debian/Ubuntu:  apt-get install shellcheck\n'
    printf '  RHEL/CentOS:    yum install ShellCheck\n'
    printf '  Fedora:         dnf install ShellCheck\n'
    printf '  macOS (brew):   brew install shellcheck\n'
    printf '  Manual (amd64): wget -qO- "https://storage.googleapis.com/shellcheck/shellcheck-latest.linux.x86_64.tar.xz" | tar -xJv\n'
    printf '  Cabal:          cabal update && cabal install shellcheck\n'
    printf '\n'
    exit 1
fi

# ---------------------------------------------------------------------------
# Ruta al directorio de Lynis:
#   1. Usar LYNIS_PATH si está disponible (inyectado por lynis-devkit)
#   2. Fallback a la ruta relativa clásica ../lynis
# ---------------------------------------------------------------------------
LYNIS_DIR="${LYNIS_PATH:-../lynis}"

if [ ! -d "${LYNIS_DIR}" ]; then
    printf 'Error: directorio de Lynis no encontrado: %s\n' "${LYNIS_DIR}" >&2
    printf 'Configurar lynis-directory en el archivo config o exportar LYNIS_PATH\n' >&2
    exit 1
fi

printf 'shellcheck versión: '
shellcheck --version | grep '^version:' | awk '{ print $2 }'
printf 'Directorio Lynis:   %s\n' "${LYNIS_DIR}"
printf '\n'

# ---------------------------------------------------------------------------
# Tests de shellcheck excluidos y motivos documentados
# ---------------------------------------------------------------------------
# SC1090: Can't follow non-constant source — aceptable con archivos incluidos dinámicamente
# SC2006: Use $(...) notation instead of backticks — reportado por check-functions.sh
# SC2012: Use find instead of ls to better handle non-alphanumeric filenames — ya conocido
# SC2016: Expressions don't expand in single quotes — intencionado en varios sitios
# SC2028: echo may not expand escape sequences — se usa printf donde importa
# SC2034: VAR appears unused — muchas variables son exportadas a tests incluidos
# SC2039: In POSIX sh, X is not supported — revisado caso a caso
# SC2063: grep -E is not supported in classic sh — falsos positivos
# SC2086: Double quote to prevent globbing — revisado caso a caso
# SC2166: Prefer [ p ] && [ q ] — estilo aceptado en Lynis
# SC2181: Check exit code directly — en Lynis se usa $? intencionadamente
excluded_tests="SC1090,SC2006,SC2012,SC2016,SC2028,SC2034,SC2039,SC2063,SC2086,SC2166,SC2181"

# ---------------------------------------------------------------------------
# Ejecutar shellcheck
#
# Opciones:
#   --check-sourced  : analiza también los archivos incluidos con '.'
#   --source-path    : rutas de búsqueda para archivos incluidos
#   --shell=sh       : POSIX sh estricto
#   --format=gcc     : formato compatible con IDEs (CLion, VSCode, etc.) y CI
#   --exclude        : tests desactivados (documentados arriba)
# ---------------------------------------------------------------------------
printf 'Ejecutando shellcheck...\n'

shellcheck \
    --check-sourced \
    --source-path="${LYNIS_DIR}/db:${LYNIS_DIR}/include" \
    --shell=sh \
    --format=gcc \
    --exclude="${excluded_tests}" \
    "${LYNIS_DIR}/lynis" \
    "${LYNIS_DIR}/include/"*

_sc_rc=$?
if [ "${_sc_rc}" -eq 0 ]; then
    printf '\n[OK] shellcheck no encontró problemas.\n'
else
    printf '\n[!] shellcheck encontró advertencias/errores (código: %d).\n' "${_sc_rc}"
fi

exit "${_sc_rc}"

# EOF
