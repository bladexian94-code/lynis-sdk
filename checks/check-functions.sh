#!/bin/sh

################################################################################
#
#   Lynis SDK — checks/check-functions.sh v1.1.0
#
# Checks cubiertos (5 total):
#   1. --skip-reason siempre presente en Register ... --preqs-met
#   2. Espaciado de 'else' en múltiplos de 4
#   3. Contador debe llamarse COUNTER no N
#   4. No usar backticks `` (deprecated, migrar a $())
#   5. Nombres de variables globales en MAYÚSCULAS
#
################################################################################

RETVAL=0
TOTAL=5

Assert() {

    # ------------------------------------------------------------------
    # Check 1: --skip-reason siempre definido en Register con --preqs-met
    # ------------------------------------------------------------------
    printf '[1/%d] Register con --preqs-met siempre tiene --skip-reason\n' "${TOTAL}"
    if [ -d "${LYNIS_PATH}/include" ]; then
        _missing=$(grep -R 'Register ' "${LYNIS_PATH}/include/tests_"* 2>/dev/null \
            | grep -- '--preqs-met' \
            | grep -v -- '--skip-reason' \
            | awk '{ print "  Test " $4 " en " $1 }') || _missing=""
        if [ -n "${_missing}" ]; then
            printf '%s\n' "${_missing}"
            printf '  [!] Los tests anteriores deberían añadir --skip-reason\n'
        else
            printf '  [OK] Todos los Register con --preqs-met tienen --skip-reason\n'
        fi
    else
        printf '  [SKIP] LYNIS_PATH no apunta a directorio válido: %s\n' "${LYNIS_PATH:-no definido}"
    fi

    # ------------------------------------------------------------------
    # Check 2: Espaciado de 'else' en múltiplos de 4
    # ------------------------------------------------------------------
    printf '[2/%d] Espaciado de else en múltiplos de 4 (resultados = revisar)\n' "${TOTAL}"
    if [ -d "${LYNIS_PATH}/include" ]; then
        grep -R 'else' "${LYNIS_PATH}/include/tests_"* 2>/dev/null \
            | grep -v -E 'awk|AWKBINARY' \
            | grep -v 'then' \
            | grep -v '^#' \
            | grep -E -v '#([[:space:]]+)else' \
            | awk -F '//' '{ n = gsub(/ /, "", $1); print $1" "n }' \
            | awk '{ if ($2 %4 > 0) { print "  [!] "$1" (espacios: "$2")}}' || true
    else
        printf '  [SKIP] LYNIS_PATH no válido\n'
    fi

    # ------------------------------------------------------------------
    # Check 3: Contadores deben llamarse COUNTER no N
    # ------------------------------------------------------------------
    printf '[3/%d] Contadores deben llamarse COUNTER (no N)\n' "${TOTAL}"
    if [ -d "${LYNIS_PATH}" ]; then
        _counter_bad=$(grep -R ' N=0' "${LYNIS_PATH}" 2>/dev/null \
            | grep -v '.git' | grep -v '#') || _counter_bad=""
        if [ -n "${_counter_bad}" ]; then
            printf '%s\n' "${_counter_bad}" | awk '{ print "  [!] "$0 }'
        else
            printf '  [OK] No se encontraron contadores llamados N\n'
        fi
    else
        printf '  [SKIP] LYNIS_PATH no válido\n'
    fi

    # ------------------------------------------------------------------
    # Check 4 (NUEVO): No usar backticks — migrar a $()
    # Los backticks están deprecated en POSIX sh moderno y son más difíciles
    # de anidar y leer.
    # ------------------------------------------------------------------
    printf '[4/%d] No usar backticks (deprecated) — usar $() en su lugar\n' "${TOTAL}"
    if [ -d "${LYNIS_PATH}/include" ]; then
        # Busca backticks que no sean en comentarios
        _backtick_count=$(grep -R '`' "${LYNIS_PATH}/include/tests_"* 2>/dev/null \
            | grep -v '^[[:space:]]*#' \
            | wc -l | tr -d ' ') || _backtick_count=0
        if [ "${_backtick_count}" -gt 0 ]; then
            printf '  [!] Se encontraron %s usos de backticks. Migrar a $()\n' "${_backtick_count}"
            grep -R '`' "${LYNIS_PATH}/include/tests_"* 2>/dev/null \
                | grep -v '^[[:space:]]*#' | head -5 \
                | awk '{ print "  ->  "$0 }'
        else
            printf '  [OK] No se encontraron backticks\n'
        fi
    else
        printf '  [SKIP] LYNIS_PATH no válido\n'
    fi

    # ------------------------------------------------------------------
    # Check 5 (NUEVO): Variables globales en MAYÚSCULAS
    # Identifica asignaciones de variables en minúsculas que probablemente
    # deberían ser globales/constantes (excluye variables locales _xxx).
    # ------------------------------------------------------------------
    printf '[5/%d] Variables globales deben usar MAYÚSCULAS\n' "${TOTAL}"
    if [ -d "${LYNIS_PATH}/include" ]; then
        # Busca patrones tipo 'nombre_en_minusculas=' al inicio de línea
        # excluyendo los patrones habituales de variables locales con _ prefijo
        _lower_vars=$(grep -R -E '^[[:space:]]*[a-z][a-z0-9_]+=[^"]' \
            "${LYNIS_PATH}/include/tests_"* 2>/dev/null \
            | grep -v '^[[:space:]]*#' \
            | grep -v '_[a-z]' \
            | grep -v 'awk\|sed\|grep\|find' | head -10) || _lower_vars=""
        if [ -n "${_lower_vars}" ]; then
            printf '  [!] Posibles variables globales en minúsculas (revisar):\n'
            printf '%s\n' "${_lower_vars}" | awk '{ print "  ->  "$0 }'
        else
            printf '  [OK] No se detectaron variables globales en minúsculas\n'
        fi
    else
        printf '  [SKIP] LYNIS_PATH no válido\n'
    fi

    printf '\n'
    return ${RETVAL}
}
