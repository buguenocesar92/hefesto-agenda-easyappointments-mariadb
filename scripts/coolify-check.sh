#!/usr/bin/env bash
# Verifica que compose.yaml cumple el contrato Coolify para
# hefesto-agenda-easyappointments-mariadb.
#
# Reglas evaluadas (contrato común Coolify MVP Hefesto):
#   1. Nada que salte Traefik ni dé poder sobre el host:
#      services sin `profiles:` no deben declarar ports:, container_name,
#      privileged, cap_add, devices, network_mode: host, pid: host,
#      ipc: host, security_opt con unconfined, binds fuera del repo ni
#      bind a docker.sock.
#   2. Nombres estables sin forzar: el render no debe traer `name:` a
#      nivel raíz ni en volúmenes declarados (Coolify pone el nombre).
#
# Uso: bash scripts/coolify-check.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/compose.yaml"

if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "ERROR: no se encuentra $COMPOSE_FILE" >&2
    exit 2
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: docker no disponible en PATH" >&2
    exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq no disponible en PATH" >&2
    exit 2
fi

# Genera un .env temporal con valores ficticios no secretos para todas las
# variables ${VAR}, ${VAR:-defecto} y ${VAR:?motivo} que aparezcan en el
# compose. Variables de host o URL se rellenan con https://ejemplo.invalid
# para que no rompan la validación nativa.
TMP_ENV="$(mktemp -t coolify-check-XXXXXX.env)"
trap 'rm -f "$TMP_ENV"' EXIT

: > "$TMP_ENV"
grep -oE '\$\{[A-Z_][A-Z0-9_]*(:[^}]*)?\}' "$COMPOSE_FILE" \
    | sed -E 's/^\$\{//; s/:[^}]*\}$//' \
    | sort -u \
    | while IFS= read -r var; do
        [[ -z "$var" ]] && continue
        case "$var" in
            AGENDA_HOST|MAIL_FROM|MAIL_FROM_ADDRESS|BASE_URL)
                echo "${var}=https://ejemplo.invalid" >> "$TMP_ENV"
                ;;
            *)
                echo "${var}=x1234567890abcdef1234567890abcdef" >> "$TMP_ENV"
                ;;
        esac
    done

# Renderiza el compose a JSON. stderr se descarta para no contaminar el
# JSON que luego consume jq; si falla, lo dejamos explícito.
set +e
RENDER_JSON="$(docker compose \
    --project-directory "$REPO_ROOT" \
    -f "$COMPOSE_FILE" \
    --env-file "$TMP_ENV" \
    config --format json 2>/dev/null)"
RENDER_RC=$?
set -e
if [[ $RENDER_RC -ne 0 || -z "$RENDER_JSON" ]]; then
    echo "ERROR: docker compose config falló (rc=$RENDER_RC)" >&2
    docker compose \
        --project-directory "$REPO_ROOT" \
        -f "$COMPOSE_FILE" \
        --env-file "$TMP_ENV" \
        config --format json >&2 || true
    exit 1
fi

failures=0
report_failure() {
    echo "FALLO: $1"
    failures=$((failures + 1))
}

# Regla 2: no `name:` a nivel raíz ni en volúmenes declarados. Se valida
# contra el YAML fuente: Docker Compose siempre rellena nombres automáticos
# basados en el directorio aunque no estén declarados, así que la prueba
# fiable es mirar el archivo original.
src="$(cat "$COMPOSE_FILE")"
if printf '%s' "$src" | grep -qE '^name:[[:space:]]*[^[:space:]]'; then
    src_root_name="$(printf '%s' "$src" | sed -nE 's/^name:[[:space:]]*(.*)$/\1/p' | head -n1)"
    report_failure "raíz: name fijo declarado ($src_root_name) — Coolify asigna el nombre de proyecto"
fi

# Recorre el bloque `volumes:` del YAML y reporta cualquier entrada con `name:` propio.
# Se procesa cada línea sin getline para no perder entradas adyacentes.
awk '
    /^volumes:[[:space:]]*$/ { in_vol = 1; next }
    in_vol && /^[A-Za-z]/ { in_vol = 0 }
    in_vol && /^  [A-Za-z0-9_-]+:[[:space:]]*$/ {
        vol_name = $0
        sub(/^[[:space:]]+/, "", vol_name)
        sub(/:[[:space:]]*$/, "", vol_name)
        next
    }
    in_vol && /^[[:space:]]{4,}name:[[:space:]]*[^[:space:]]/ {
        n = $0
        sub(/^[[:space:]]+name:[[:space:]]*/, "", n)
        sub(/[[:space:]]*$/, "", n)
        if (vol_name != "") {
            printf "volumen %s: name fijo declarado (%s) — Coolify asigna el nombre\n", vol_name, n
        }
        next
    }
' "$COMPOSE_FILE" > "$TMP_ENV.lines"
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    report_failure "$line"
done < "$TMP_ENV.lines"
rm -f "$TMP_ENV.lines"

# Detecta servicios sin `profiles` mirando el YAML fuente (el render omite los
# servicios con profiles activos cuando no se pide ese profile).
service_has_profile() {
    local svc="$1"
    awk -v svc="$svc" '
        $0 ~ "^  "svc":$" { in_svc = 1; next }
        in_svc && /^  [A-Za-z]/ { in_svc = 0 }
        in_svc && /^[[:space:]]+profiles:[[:space:]]*$/ { print "yes"; exit }
        in_svc && /^[[:space:]]+profiles:[[:space:]]*\[[^]]*\]/ { print "yes"; exit }
    ' "$COMPOSE_FILE"
}

services="$(jq -r '.services | keys[]' <<< "$RENDER_JSON" 2>/dev/null || true)"
for svc in $services; do
    [[ -z "$svc" ]] && continue
    if [[ "$(service_has_profile "$svc")" == "yes" ]]; then
        continue
    fi

    check_field() {
        local path="$1" label="$2"
        local val
        val="$(printf '%s' "$RENDER_JSON" | jq -r --arg s "$svc" ".services[\$s]${path} // empty" 2>/dev/null || true)"
        if [[ -n "$val" && "$val" != "null" ]]; then
            report_failure "$svc: $label detectado"
        fi
    }

    check_field ".ports" "ports:"
    check_field ".container_name" "container_name"
    check_field ".privileged" "privileged"
    check_field ".cap_add" "cap_add"
    check_field ".devices" "devices"
    check_field ".pid" "pid"
    check_field ".ipc" "ipc"

    network_mode="$(printf '%s' "$RENDER_JSON" | jq -r --arg s "$svc" ".services[\$s].network_mode // empty" 2>/dev/null || true)"
    if [[ "$network_mode" == "host" ]]; then
        report_failure "$svc: network_mode: host detectado"
    fi

    if printf '%s' "$RENDER_JSON" | jq -e --arg s "$svc" '.services[$s].security_opt // [] | index("unconfined")' >/dev/null 2>&1; then
        report_failure "$svc: security_opt: unconfined detectado"
    fi

    # Binds fuera del repo y bind a docker.sock.
    bind_violations="$(printf '%s' "$RENDER_JSON" | jq -r --arg s "$svc" --arg root "$REPO_ROOT" '
        .services[$s].volumes // [] | .[] | select(.type == "bind") |
        if (.source | test("docker\\.sock")) then "docker.sock"
        elif ((.source | startswith($root + "/")) or .source == $root) | not then ("bind fuera del repo: " + .source)
        else empty end
    ' 2>/dev/null || true)"
    if [[ -n "$bind_violations" ]]; then
        while IFS= read -r v; do
            [[ -z "$v" ]] && continue
            report_failure "$svc: $v detectado"
        done <<< "$bind_violations"
    fi
done

if [[ "$failures" -gt 0 ]]; then
    echo "Total fallos: $failures"
    exit 1
fi

echo "OK: compose.yaml cumple el contrato Coolify (servicios revisados: $(echo $services | tr ' ' ','))."
