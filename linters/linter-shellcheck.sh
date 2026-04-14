#!/bin/sh
#
# Lynis Development Kit -- linters/linter-shellcheck.sh
# Version mejorada 1.1.0
#
# Cambios:
#   - Usa LYNIS_DIR="${LYNIS_PATH:-../lynis}" del entorno (no ruta hardcodeada)
#   - Muestra version de shellcheck al inicio
#   - Instrucciones de instalacion para Debian, RHEL, Fedora, Arch, macOS
#   - --format=gcc para integracion con IDEs y CI/CD
#   - Conteo de archivos analizados e issues encontrados

LYNIS_DIR="${LYNIS_PATH:-../lynis}"
SDK_DIR="."
SHELLCHECK_FORMAT="${SHELLCHECK_FORMAT:-gcc}"
SC_ERRORS=0
SC_FILES=0

# -- Verificar shellcheck disponible ------------------------------------------
if ! command -v shellcheck > /dev/null 2>&1; then
    printf "${RED}[ERROR]${NORMAL} shellcheck no encontrado en el PATH.\n" >&2
    printf "\nInstrucciones de instalacion:\n"
    printf "  Debian/Ubuntu : sudo apt-get install shellcheck\n"
    printf "  RHEL/CentOS 8 : sudo dnf install ShellCheck\n"
    printf "  Fedora        : sudo dnf install ShellCheck\n"
    printf "  Arch Linux    : sudo pacman -S shellcheck\n"
    printf "  macOS (brew)  : brew install shellcheck\n"
    printf "  Manual (x86_64):\n"
    printf "    wget https://github.com/koalaman/shellcheck/releases/latest/download/shellcheck-stable.linux.x86_64.tar.xz\n"
    printf "    tar -xf shellcheck-stable.linux.x86_64.tar.xz\n"
    printf "    sudo mv shellcheck-stable/shellcheck /usr/local/bin/\n"
    SDKExitFatal "Instale shellcheck y vuelva a ejecutar"
fi

SC_VERSION=$(shellcheck --version | grep -E "^version:" | awk '{print $2}')
_info "shellcheck version: ${SC_VERSION}  formato: ${SHELLCHECK_FORMAT}"

# -- Analisis de un archivo ---------------------------------------------------
_sc_check() {
    local file="$1"
    SC_FILES=$((SC_FILES+1))
    if shellcheck --format="${SHELLCHECK_FORMAT}" --shell=sh "${file}" 2>&1; then
        return 0
    else
        SC_ERRORS=$((SC_ERRORS+1))
        return 1
    fi
}

Assert() {
    local failed=0

    # -- Analizar archivos del SDK -----------------------------------------
    printf "\n${SECTION}=== Analizando SDK ===${NORMAL}\n"
    while IFS= read -r FILE; do
        if [ -z "${FILE}" ]; then continue ; fi
        printf "  Archivo: %s\n" "${FILE}"
        _sc_check "${FILE}" || failed=$((failed+1))
    done << FILELIST
$(find "${SDK_DIR}/checks" "${SDK_DIR}/unit-tests" "${SDK_DIR}/linters" \
       -name "*.sh" -type f 2>/dev/null | sort)
FILELIST

    for f in ./lynis-devkit ./include/devkit-functions; do
        if [ -f "${f}" ]; then
            printf "  Archivo: %s\n" "${f}"
            _sc_check "${f}" || failed=$((failed+1))
        fi
    done

    # -- Analizar archivos de Lynis (si el directorio existe) -------------
    if [ -d "${LYNIS_DIR}" ]; then
        printf "\n${SECTION}=== Analizando Lynis en: %s ===${NORMAL}\n" "${LYNIS_DIR}"
        while IFS= read -r FILE; do
            if [ -z "${FILE}" ]; then continue ; fi
            printf "  Archivo: %s\n" "${FILE}"
            _sc_check "${FILE}" || failed=$((failed+1))
        done << FILELIST
$(find "${LYNIS_DIR}/include" -type f 2>/dev/null | sort)
FILELIST
        if [ -f "${LYNIS_DIR}/lynis" ]; then
            printf "  Archivo: %s/lynis\n" "${LYNIS_DIR}"
            _sc_check "${LYNIS_DIR}/lynis" || failed=$((failed+1))
        fi
    else
        _warn "Directorio Lynis no encontrado: ${LYNIS_DIR}"
        _warn "Defina LYNIS_PATH o coloque 'lynis' en ../lynis para analisis completo"
    fi

    printf "\n"
    printf "  Archivos analizados : %d\n" "${SC_FILES}"
    printf "  Archivos con issues : %d\n" "${failed}"

    if [ "${failed}" -eq 0 ]; then
        SDKPrintOK
    else
        SDKPrintFailed
    fi

    return "${failed}"
}
# EOF
