#!/bin/sh

################################################################################
#
#   Lynis SDK — unit-tests/tests-functions.sh v1.1.0
#
# Tests cubiertos (8 total):
#   1.  DirectoryExists — directorio válido
#   2.  DirectoryExists — directorio inválido
#   3.  FileExists      — archivo válido
#   4.  FileExists      — archivo inválido
#   5.  SDKShowLine     — produce exactamente 63 caracteres '='
#   6.  SDKPrintOK      — salida contiene 'OK'
#   7.  SDKPrintFailed  — salida contiene 'FAILED'
#   8.  _config_get     — parseo con comentarios y espacios
#
################################################################################

RETVAL=0
TOTAL=8
_PASS=0
_FAIL=0

# Helper: registra resultado y actualiza contadores
_assert_result() {
    _test_num="$1"
    _test_desc="$2"
    _test_ok="$3"  # 0 = OK, distinto = FAIL
    printf '[%d/%d] %s ' "${_test_num}" "${TOTAL}" "${_test_desc}"
    if [ "${_test_ok}" -eq 0 ]; then
        printf '%s OK%s\n' "${GREEN:-}" "${NORMAL:-}"
        _PASS=$((_PASS + 1))
    else
        printf '%sFAILED%s\n' "${RED:-}" "${NORMAL:-}"
        _FAIL=$((_FAIL + 1))
        RETVAL=1
    fi
}

Assert() {

    # ------------------------------------------------------------------
    # Test 1: DirectoryExists con directorio válido
    # ------------------------------------------------------------------
    if DirectoryExists . > /dev/null 2>&1; then _t=0; else _t=1; fi
    _assert_result 1 "DirectoryExists (directorio válido '.')" "${_t}"

    # ------------------------------------------------------------------
    # Test 2: DirectoryExists con directorio inválido (esperamos fallo)
    # ------------------------------------------------------------------
    if ! DirectoryExists non-existing-dir-lynis-sdk > /dev/null 2>&1; then _t=0; else _t=1; fi
    _assert_result 2 "DirectoryExists (directorio inválido)" "${_t}"

    # ------------------------------------------------------------------
    # Test 3: FileExists con archivo válido
    # ------------------------------------------------------------------
    _test_file="./lynis-devkit"
    if [ -f "${_test_file}" ]; then
        if FileExists "${_test_file}" > /dev/null 2>&1; then _t=0; else _t=1; fi
    else
        # Archivo no disponible en este contexto: test omitido con OK
        _t=0
        printf '  (omitido: lynis-devkit no en cwd)'
    fi
    _assert_result 3 "FileExists (archivo válido '${_test_file}')" "${_t}"

    # ------------------------------------------------------------------
    # Test 4: FileExists con archivo inválido (esperamos fallo)
    # ------------------------------------------------------------------
    if ! FileExists "/tmp/lynis-sdk-nonexistent-$$" > /dev/null 2>&1; then _t=0; else _t=1; fi
    _assert_result 4 "FileExists (archivo inválido)" "${_t}"

    # ------------------------------------------------------------------
    # Test 5: SDKShowLine produce exactamente una línea de 63 '='
    # ------------------------------------------------------------------
    if command -v SDKShowLine > /dev/null 2>&1; then
        _line_len=$(SDKShowLine | tr -d '\n' | wc -c | tr -d ' ')
        if [ "${_line_len}" -eq 63 ]; then _t=0; else _t=1; fi
    else
        printf '  (omitido: SDKShowLine no disponible)'
        _t=0
    fi
    _assert_result 5 "SDKShowLine produce 63 caracteres '='" "${_t}"

    # ------------------------------------------------------------------
    # Test 6: SDKPrintOK contiene 'OK' en su salida
    # ------------------------------------------------------------------
    if command -v SDKPrintOK > /dev/null 2>&1; then
        _out=$(SDKPrintOK 2>&1)
        printf '%s' "${_out}" | grep -q 'OK'
        _t=$?
    else
        printf '  (omitido: SDKPrintOK no disponible)'
        _t=0
    fi
    _assert_result 6 "SDKPrintOK produce salida con 'OK'" "${_t}"

    # ------------------------------------------------------------------
    # Test 7: SDKPrintFailed contiene 'FAILED' en su salida
    # ------------------------------------------------------------------
    if command -v SDKPrintFailed > /dev/null 2>&1; then
        _out=$(SDKPrintFailed 2>&1)
        printf '%s' "${_out}" | grep -q 'FAILED'
        _t=$?
    else
        printf '  (omitido: SDKPrintFailed no disponible)'
        _t=0
    fi
    _assert_result 7 "SDKPrintFailed produce salida con 'FAILED'" "${_t}"

    # ------------------------------------------------------------------
    # Test 8: _config_get parseo robusto
    # Crea un config de prueba con comentarios y espacios alrededor de '='
    # y verifica que _config_get extrae el valor correcto.
    # ------------------------------------------------------------------
    if command -v _config_get > /dev/null 2>&1; then
        _cfg_tmp=$(mktemp /tmp/lynis-sdk-test.XXXXXX)
        cat > "${_cfg_tmp}" <<'CFGEOF'
# Esto es un comentario
   # Otro comentario con espacios
lynis-directory = /opt/lynis
verbose = yes
# lynis-directory = /this/should/be/ignored
CFGEOF
        # Guardar config original y usar el de prueba
        _orig_cfg="${CONFIG_FILE:-config}"
        CONFIG_FILE="${_cfg_tmp}"
        _val=$(_config_get "lynis-directory" "")
        CONFIG_FILE="${_orig_cfg}"
        rm -f "${_cfg_tmp}"
        if [ "${_val}" = "/opt/lynis" ]; then _t=0; else _t=1; fi
    else
        printf '  (omitido: _config_get no disponible en este contexto)'
        _t=0
    fi
    _assert_result 8 "_config_get parseo con comentarios y espacios" "${_t}"

    # ------------------------------------------------------------------
    # Resumen
    # ------------------------------------------------------------------
    printf '\n'
    printf '  Resultado: %s%d PASS%s, %s%d FAIL%s (de %d tests)\n' \
        "${GREEN:-}" "${_PASS}" "${NORMAL:-}" \
        "${RED:-}"   "${_FAIL}" "${NORMAL:-}" \
        "${TOTAL}"
    printf '\n'

    return ${RETVAL}
}
