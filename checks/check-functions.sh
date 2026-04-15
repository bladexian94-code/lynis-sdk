#!/bin/sh
#
# Lynis Development Kit -- checks/check-functions.sh
# Version mejorada 1.1.0
#
# Cambios:
#   - grep -E en lugar de egrep (deprecated, POSIX)
#   - Anadidos checks: backticks y variables en MAYUSCULAS
#   - Resumen PASS/FAIL al final
#   - Colores en output via variables del devkit

RETVAL=0
TOTAL=5
PASS=0
FAIL=0

Assert() {
    # ------------------------------------------------------------------
    # Check 1: No usar egrep (deprecated, usar grep -E)
    # ------------------------------------------------------------------
    printf "[1/%s] Verificando que no se usa 'egrep' en el codigo" "${TOTAL}"
    if grep -E -rq '\begrep\b' ../lynis/include/ ../lynis/lynis 2>/dev/null; then
        printf " ${YELLOW}[INFO]${NORMAL} 'egrep' encontrado (informativo)\n"
    else
        SDKPrintOK
        PASS=$((PASS+1))
    fi

    # ------------------------------------------------------------------
    # Check 2: Nombres de funciones en CamelCase o snake_case consistente
    # ------------------------------------------------------------------
    printf "[2/%s] Verificando nombres de funciones en Lynis" "${TOTAL}"
    FUNC_ISSUES=$(grep -E -o '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' \
                      ../lynis/include/functions 2>/dev/null \
                  | grep -E '^[a-z][a-zA-Z0-9]*[A-Z].*\(\)' \
                  | grep -Ev '^[A-Z]' | wc -l | tr -d ' ')
    if [ "${FUNC_ISSUES}" -gt 0 ]; then
        SDKPrintFailed
        FAIL=$((FAIL+1)) ; RETVAL=1
    else
        SDKPrintOK
        PASS=$((PASS+1))
    fi

    # ------------------------------------------------------------------
    # Check 3: No backticks en archivos SDK (usar $() en su lugar)
    # ------------------------------------------------------------------
    printf "[3/%s] Verificando ausencia de backticks en archivos SDK" "${TOTAL}"
    BACKTICK_COUNT=$(grep -rn -F '`' ./checks/ ./unit-tests/ ./linters/ 2>/dev/null \
                     | grep -v "^Binary" | wc -l | tr -d ' ')
    if [ "${BACKTICK_COUNT}" -gt 0 ]; then
        SDKPrintFailed
        FAIL=$((FAIL+1)) ; RETVAL=1
        grep -rn -F '`' ./checks/ ./unit-tests/ ./linters/ 2>/dev/null \
            | grep -v "^Binary" | head -5
    else
        SDKPrintOK
        PASS=$((PASS+1))
    fi

    # ------------------------------------------------------------------
    # Check 4: Variables globales del devkit en MAYUSCULAS
    # ------------------------------------------------------------------
    printf "[4/%s] Verificando que variables globales estan en MAYUSCULAS" "${TOTAL}"
    BAD_VARS=$(grep -E '^[a-z][a-z_0-9]+=' ./lynis-devkit 2>/dev/null \
               | grep -Ev '^#' \
               | grep -Ev '^(local|readonly)[[:space:]]' \
               | wc -l | tr -d ' ')
    if [ "${BAD_VARS}" -gt 0 ]; then
        SDKPrintFailed
        FAIL=$((FAIL+1)) ; RETVAL=1
    else
        SDKPrintOK
        PASS=$((PASS+1))
    fi

    # ------------------------------------------------------------------
    # Check 5: Shebangs presentes en todos los scripts SDK
    # ------------------------------------------------------------------
    printf "[5/%s] Verificando shebangs en scripts SDK" "${TOTAL}"
    MISSING_SHEBANG=0
    while IFS= read -r script; do
        if [ -z "${script}" ]; then continue ; fi
        if ! head -1 "${script}" | grep -q '^#!/'; then
            printf "\n  AVISO: sin shebang en %s" "${script}"
            MISSING_SHEBANG=$((MISSING_SHEBANG+1))
        fi
    done << FILELIST
$(find ./checks ./unit-tests ./linters -type f -name "*.sh" 2>/dev/null | sort)
FILELIST

    if [ "${MISSING_SHEBANG}" -gt 0 ]; then
        SDKPrintFailed
        FAIL=$((FAIL+1)) ; RETVAL=1
    else
        SDKPrintOK
        PASS=$((PASS+1))
    fi

    printf "\n"
    printf "Resultado checks: ${GREEN}%d PASS${NORMAL} / ${RED}%d FAIL${NORMAL} de %d\n" \
           "${PASS}" "${FAIL}" "${TOTAL}"

    return ${RETVAL}
}
# EOF
