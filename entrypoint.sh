#!/bin/sh
# Miget entrypoint: keep every piece of nanobot state on the persistent volume
# and initialise the config only once, so changes made in the WebUI survive
# redeploys.
set -e

DATA_DIR="${NANOBOT_DATA_DIR:-/app/storage/nanobot}"
WORKSPACE="${NANOBOT_WORKSPACE:-/app/storage/workspace}"
CONFIG="$DATA_DIR/config.json"

mkdir -p "$DATA_DIR" "$WORKSPACE"

if [ -f "$CONFIG" ]; then
    echo "[entrypoint] using existing $CONFIG"
else
    echo "[entrypoint] initializing $CONFIG from template"
    cp /app/config.template.json "$CONFIG"
fi

if [ -z "$NANOBOT_WEB_TOKEN" ]; then
    echo "[entrypoint] warning: NANOBOT_WEB_TOKEN is empty — the WebUI login will not work" >&2
fi

# Top-level flags such as --version are not subcommands and do not accept
# --config; everything else (gateway, status, agent, …) does.
case "$1" in
    -*|"") exec nanobot "$@" ;;
    *) exec nanobot "$@" --config "$CONFIG" ;;
esac
