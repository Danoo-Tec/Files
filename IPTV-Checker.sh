#!/usr/bin/env bash
# IPTV-Checker.sh — Diagnóstico visual para streams IPTV (HEAD -> GET Range)
# Uso:
#   chmod +x IPTV-Checker.sh
#   ./IPTV-Checker.sh "http://host/live/USER/PASS/321276.ts" [--timeout 8] [--no-color] [--no-follow] [--show-headers] [--show-commands] [--ua 'UA...']
# Códigos de salida:
#   0 OK (206 / 200 con datos / chunked)
#   1 Advertencia (200 con 0 bytes u otro no crítico / 406)
#   2 Denegado (401/403)
#   3 No encontrado (404)
#   4 Error de servidor (5xx)
#   5 Error de red/timeout

set -uo pipefail

# ---------------- Opciones ----------------
TIMEOUT=8
FOLLOW="-L"
COLOR=1
SHOW_HEADERS=0
SHOW_CMDS=0
URL=""
UA_DEFAULT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36"
UA="$UA_DEFAULT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout)        TIMEOUT="${2:-8}"; shift 2;;
    --no-color)       COLOR=0; shift;;
    --no-follow)      FOLLOW=""; shift;;
    --show-headers)   SHOW_HEADERS=1; shift;;
    --show-commands)  SHOW_CMDS=1; shift;;
    --ua)             UA="${2:-$UA_DEFAULT}"; shift 2;;
    -h|--help)
      echo "Uso: $0 <URL> [--timeout N] [--no-color] [--no-follow] [--show-headers] [--show-commands] [--ua 'UA...']"
      exit 0;;
    *) URL="$1"; shift;;
  esac
done

[[ -z "${URL}" ]] && { echo "Error: falta la URL." >&2; exit 5; }

# ---- Limpia pantalla (mejor presentación) ----
clear 2>/dev/null || printf '\033c'

# ---------------- Estilos ----------------
if [[ "$COLOR" -eq 1 && -t 1 ]]; then
  BOLD=$'\e[1m'; DIM=$'\e[2m'; RESET=$'\e[0m'
  GRAY=$'\e[38;5;246m'
  RED=$'\e[38;5;203m'; GREEN=$'\e[38;5;83m'; YELLOW=$'\e[38;5;179m'; BLUE=$'\e[38;5;69m'; CYAN=$'\e[38;5;45m'
  BG_NEU=$'\e[48;5;60m'
else
  BOLD=""; DIM=""; RESET=""; GRAY=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; BG_NEU=""
fi

hr(){ local w; w=$(tput cols 2>/dev/null || echo 80); printf '%*s\n' "$w" '' | tr ' ' '─'; }
trim(){ sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
kv(){ printf "  %s%-16s%s %s\n" "$GRAY" "$1:" "$RESET" "$2"; }
badge(){ printf "%s %s%s %s%s " "$BG_NEU" "$BOLD" "$2" "$1" "$RESET"; }

# -------------- Curl helpers --------------
LAST_FILE=""; LAST_CODE="000"; LAST_TIME="0"
COMMON_H=(-H 'Accept: */*' -H 'Cache-Control: no-cache' -A "$UA")

probe_head() {
  LAST_FILE="$(mktemp)"
  local out
  out=$( (curl -sS -I $FOLLOW -m "$TIMEOUT" "${COMMON_H[@]}" \
          -D "$LAST_FILE" -o /dev/null -w '%{http_code} %{time_total}' "$URL") 2>&1 ) || true
  read -r LAST_CODE LAST_TIME <<<"$out"
}

probe_range() {
  LAST_FILE="$(mktemp)"
  local out
  out=$( (curl -sS $FOLLOW -m "$TIMEOUT" "${COMMON_H[@]}" \
          -H 'Range: bytes=0-0' -D "$LAST_FILE" -o /dev/null \
          -w '%{http_code} %{time_total}' "$URL") 2>&1 ) || true
  read -r LAST_CODE LAST_TIME <<<"$out"
}

hval(){ grep -i "^$2:" "$1" 2>/dev/null | head -n1 | cut -d: -f2- | tr -d '\r' | trim; }
digits(){ sed -n 's/[^0-9]//gp' <<<"$1"; }

# -------------- Banner --------------
hr
printf "%sIPTV Checker%s  %s%s%s\n" "$BOLD" "$RESET" "$DIM" "$URL" "$RESET"
hr

# -------------- HEAD primero --------------
probe_head

# Si HEAD no sirve (000/405) intento GET con Range
if [[ "$LAST_CODE" == "000" || "$LAST_CODE" == "405" || -z "$LAST_CODE" ]]; then
  probe_range
  METHOD="GET + Range"
else
  METHOD="HEAD"
fi

# -------------- Parse headers --------------
CLEN=$(hval "$LAST_FILE" "Content-Length")
CTYPE=$(hval "$LAST_FILE" "Content-Type")
TENC=$(hval "$LAST_FILE" "Transfer-Encoding")
ACCR=$(hval "$LAST_FILE" "Accept-Ranges")
SERV=$(hval "$LAST_FILE" "Server")
DATE=$(hval "$LAST_FILE" "Date")

CLEN_NUM=$(digits "${CLEN:-0}")
[[ -z "$CLEN_NUM" ]] && CLEN_NUM=0

# -------------- Clasificación --------------
VERDICT=""; MSG=""; EXITCODE=1; COLOR_CODE="$BLUE"

case "$LAST_CODE" in
  206)
    VERDICT="✅ 206 Partial"; MSG="Acepta Range (muy buena señal de stream activo)."; EXITCODE=0; COLOR_CODE="$GREEN";;
  200)
    if [[ "$TENC" =~ [Cc]hunked ]]; then
      VERDICT="✅ 200 OK (chunked)"; MSG="Transferencia por trozos: normal en TS/HLS (sin Content-Length)."; EXITCODE=0; COLOR_CODE="$GREEN"
    elif (( CLEN_NUM > 0 )); then
      VERDICT="✅ 200 OK con datos"; MSG="Content-Length > 0: el origen está emitiendo."; EXITCODE=0; COLOR_CODE="$GREEN"
    else
      VERDICT="⚠️ 200 OK con 0 bytes"; MSG="Stream parado/origen vacío. Si persiste, depende del proveedor."; EXITCODE=1; COLOR_CODE="$YELLOW"
    fi;;
  401|403)
    VERDICT="⛔ ${LAST_CODE} Denegado"; MSG="Credenciales/geo/IP o límite de conexiones. Prueba VPN/cambiar IP y revisa tu cuenta."; EXITCODE=2; COLOR_CODE="$RED";;
  404)
    VERDICT="❌ 404 No encontrado"; MSG="El ID/URL no existe o fue retirado."; EXITCODE=3; COLOR_CODE="$RED";;
  406)
    VERDICT="⚠️ 406 Not Acceptable"; MSG="El servidor no acepta la petición tal cual (WAF/negociación). Ya se envía UA real y 'Accept: */*'. Si persiste, prueba otro UA (--ua) o Referer/IP distinta."; EXITCODE=1; COLOR_CODE="$YELLOW";;
  5??)
    VERDICT="💥 ${LAST_CODE} Error servidor"; MSG="Origen caído o sobrecargado. No depende de ti."; EXITCODE=4; COLOR_CODE="$RED";;
  000|"")
    VERDICT="❌ Error de red/CURL"; MSG="Sin respuesta. Revisa conectividad/DNS/firewall. Si tu ISP bloquea, usa VPN."; EXITCODE=5; COLOR_CODE="$RED";;
  *)
    VERDICT="ℹ️ HTTP ${LAST_CODE}"; MSG="Respuesta no clasificada. Revisa cabeceras abajo."; EXITCODE=1; COLOR_CODE="$BLUE";;
esac

# -------------- Salida --------------
echo
badge " $VERDICT " "$COLOR_CODE"
printf "%s%s%s\n\n" "$DIM" "$MSG" "$RESET"

echo "┌────────────────────── Detalles ─────────────────────"
kv "Método"         "$METHOD"
kv "HTTP Status"    "$LAST_CODE"
kv "Tiempo"         "${LAST_TIME}s"
kv "Content-Type"   "${CTYPE:-—}"
kv "Content-Length" "${CLEN:-—}"
kv "Transfer-Enc."  "${TENC:-—}"
kv "Accept-Ranges"  "${ACCR:-—}"
kv "Server"         "${SERV:-—}"
kv "Date"           "${DATE:-—}"
echo "└─────────────────────────────────────────────────────"

echo
echo "${BOLD}Sugerencias:${RESET}"
case "$EXITCODE" in
  0)
    echo "${GREEN}✓${RESET} Todo apunta a que el stream ${BOLD}está emitiendo${RESET}."
    [[ "$LAST_CODE" == "206" ]] && echo "${CYAN}•${RESET} Soporta ${BOLD}Range${RESET}: buen búfer/seek."
    [[ "$TENC" =~ [Cc]hunked ]] && echo "${CYAN}•${RESET} ${BOLD}Chunked${RESET}: normal que no haya Content-Length."
    ;;
  1)
    if (( CLEN_NUM == 0 && LAST_CODE == 200 )); then
      echo "${YELLOW}!${RESET} ${BOLD}200 con 0 bytes${RESET}: suele ser origen parado."
      echo "Reintenta en unos minutos. Si persiste, es cosa del proveedor."
    elif [[ "$LAST_CODE" == "406" ]]; then
      echo "${YELLOW}!${RESET} ${BOLD}406${RESET}: el servidor rechaza la negociación."
      echo "Prueba otro User-Agent con --ua '...' o usa VPN/otra IP. Algunos exigen Referer/host concreto."
    else
      echo "${YELLOW}!${RESET} Respuesta no crítica pero no concluyente. Revisa cabeceras."
    fi
    ;;
  2)
    echo "${RED}×${RESET} Acceso denegado."
    echo "Comprueba usuario/contraseña y caducidad; puede ser bloqueo por IP/geo o límite de conexiones."
    ;;
  3)
    echo "${RED}×${RESET} Verifica el ${BOLD}ID/URL${RESET} del stream. Puede haberse retirado."
    ;;
  4)
    echo "${RED}×${RESET} Problema en el ${BOLD}servidor de origen${RESET} (5xx). Reintenta o contacta con el proveedor."
    ;;
  5)
    echo "${RED}×${RESET} Sin respuesta."
    echo "Comprueba red/DNS/firewall. Si tu ISP filtra IPTV, usa ${BOLD}VPN${RESET} o DNS alternativos."
    ;;
esac

if [[ "$SHOW_CMDS" -eq 1 ]]; then
  echo
  echo "${BOLD}Comandos útiles (qué comprueban):${RESET}"
  printf "  %s\n" "curl -sS -I -m ${TIMEOUT} -A \"$UA\" -H 'Accept: */*' '${URL}'"
  echo "    • HEAD: sólo cabeceras. Rápido para ver estado HTTP/tipo sin cuerpo."
  printf "  %s\n" "curl -sS -m ${TIMEOUT} -A \"$UA\" -H 'Accept: */*' -H 'Range: bytes=0-0' -D - -o /dev/null '${URL}'"
  echo "    • GET con Range (primer byte): detecta ${BOLD}206 Partial${RESET} y soporte de rangos."
  echo "      Útil para confirmar entrega de datos aunque falte Content-Length."
fi

# deja aire visual al terminar
printf '\n\n'

exit "$EXITCODE"
