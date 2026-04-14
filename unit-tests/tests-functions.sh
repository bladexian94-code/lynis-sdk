#!/bin/sh
#
# Lynis Development Kit -- unit-tests/tests-functions.sh
# Version mejorada 1.1.0
#
# Cambios: 2 -> 8 tests, resumen PASS/FAIL, cubre FileExists/SDKShowLine/_config_get

RETVAL=0
TOTAL=8
PASS=0
FAIL=0

Assert() {
    printf "  [BLOQUE] Funciones del SDK y utilidades devkit\n\n"

    # -- Test 1: DirectoryExists con directorio real -----------------------
    printf "  %-55s" "DirectoryExists('/tmp') => true"
    if DirectoryExists "/tmp"; then
        SDKPrintOK ; PASS=$((PASS+1))
    else
        SDKPrintFailed ; FAIL=$((FAIL+1)) ; RETVAL=1
    fi

    # -- Test 2: DirectoryExists con ruta inexistente ----------------------
    printf "  %-55s" "DirectoryExists('/nonexistent_xyz') => false"
    if DirectoryExists "/tmp/nonexistent_lynis_test_xyz_99"; then
        SDKPrintFailed ; FAIL=$((FAIL+1)) ; RETVAL=1
    else
        SDKPrintOK ; PASS=$((PASS+1))
    fi

    # -- Test 3: FileExists con archivo real -------------------------------
    printf "  %-55s" "FileExists('./lynis-devkit') => true"
    if FileExists "./lynis-devkit"; then
        SDKPrintOK ; PASS=$((PASS+1))
    else
        SDKPrintFailed ; FAIL=$((FAIL+1)) ; RETVAL=1
    fi

    # -- Test 4: FileExists con archivo inexistente ------------------------
    printf "  %-55s" "FileExists('./nonexistent.sh') => false"
    if FileExists "./lynis_nonexistent_file_xyz.sh"; then
        SDKPrintFailed ; FAIL=$((FAIL+1)) ; RETVAL=1
    else
        SDKPrintOK ; PASS=$((PASS+1))
    fi

    # -- Test 5: SDKPrintOK no produce error -------------------------------
    printf "  %-55s" "SDKPrintOK ejecuta sin error"
    if SDKPrintOK > /dev/null 2>&1; then
        PASS=$((PASS+1)) ; printf "${GREEN}[ OK ]${NORMAL}\n"
    else
        FAIL=$((FAIL+1)) ; RETVAL=1 ; printf "${RED}[FAILED]${NORMAL}\n"
    fi

    # -- Test 6: SDKPrintFailed no produce error ---------------------------
    printf "  %-55s" "SDKPrintFailed ejecuta sin error"
    if SDKPrintFailed > /dev/null 2>&1; then
        PASS=$((PASS+1)) ; printf "${GREEN}[ OK ]${NORMAL}\n"
    else
        FAIL=$((FAIL+1)) ; RETVAL=1 ; printf "${RED}[FAILED]${NORMAL}\n"
    fi

    # -- Test 7: SDKShowLine no produce error ------------------------------
    printf "  %-55s" "SDKShowLine ejecuta sin error"
    if SDKShowLine > /dev/null 2>&1; then
        PASS=$((PASS+1)) ; printf "${GREEN}[ OK ]${NORMAL}\n"
    else
        FAIL=$((FAIL+1)) ; RETVAL=1 ; printf "${RED}[FAILED]${NORMAL}\n"
    fi

    # -- Test 8: _config_get devuelve default si clave no existe ----------
    printf "  %-55s" "_config_get retorna default si clave no existe"
    OLD_CONFIG="${CONFIG_FILE}"
    CONFIG_FILE="/tmp/lynis_test_noexist_config"
    RESULT=$(_config_get "clave_test_xyz" "mi_default_123" 2>/dev/null)
    CONFIG_FILE="${OLD_CONFIG}"
    if [ "${RESULT}" = "mi_default_123" ]; then
        PASS=$((PASS+1)) ; printf "${GREEN}[ OK ]${NORMAL}\n"
    else
        FAIL=$((FAIL+1)) ; RETVAL=1 ; printf "${RED}[FAILED]${NORMAL}\n"
        printf "    Esperado: 'mi_default_123'  Obtenido: '%s'\n" "${RESULT}"
    fi

    printf "\n"
    printf "  Resultado: ${GREEN}%d PASS${NORMAL} / ${RED}%d FAIL${NORMAL} de %d\n" \
           "${PASS}" "${FAIL}" "${TOTAL}"

    return ${RETVAL}
}
# EOF
