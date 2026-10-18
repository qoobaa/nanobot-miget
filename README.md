# nanobot on Miget

Packages [HKUDS/nanobot](https://github.com/HKUDS/nanobot) (ultra-lightweight
self-hosted personal AI agent, Python) as a Miget app that serves the bundled
**WebUI**. No other channels (Telegram/Slack/…) are configured.

## How it runs

| | |
|---|---|
| Builder | Dockerfile |
| Listen port | `5000` — the only port Miget serves HTTP on, so the WebUI/WebSocket channel is bound there |
| Gateway health | `127.0.0.1:18790`, container-local only |
| Model | Xiaomi MiMo `mimo-v2.6-pro` via `https://token-plan-ams.xiaomimimo.com/v1` (OpenAI-compatible) |
| State | `/app/storage` (Miget volume addon): `nanobot/config.json`, `nanobot/sessions`, `workspace/` |
| Auth | WebUI login via `NANOBOT_WEB_TOKEN` (nanobot's `tokenIssueSecret`) |

`entrypoint.sh` creates `config.json` from `config.template.json` **only when it
does not exist**, so anything changed later in the WebUI survives redeploys.
`${XIAOMI_API_KEY}` and `${NANOBOT_WEB_TOKEN}` are resolved from the environment
at startup — the template still lives in the image, so putting the key in the
WebUI (Settings → Models) works too.

## Required environment variables (set on the Miget app)

| Variable | Purpose |
|---|---|
| `NANOBOT_WEB_TOKEN` | WebUI password / bootstrap secret. Generate with `openssl rand -hex 32`. |
| `XIAOMI_API_KEY` | Xiaomi MiMo API key (the same one opencode uses). |

## Updating nanobot

1. Bump `ARG NANOBOT_VERSION` in `Dockerfile` (see
   [releases](https://github.com/HKUDS/nanobot/releases)).
2. Commit and push.
3. Trigger a deploy: `POST /api/v1/apps/{uuid}/deploy`.

Sessions and memory are on the volume, so the upgrade keeps the agent's history.

## Local smoke test

```sh
docker build -t nanobot-miget .
docker run --rm -p 5000:5000 \
  -v "$PWD/.storage:/app/storage" \
  -e NANOBOT_WEB_TOKEN=test-token \
  -e XIAOMI_API_KEY=... \
  nanobot-miget gateway
# then open http://localhost:5000
```

One-shot check that the model path works:

```sh
docker run --rm -v "$PWD/.storage:/app/storage" \
  -e XIAOMI_API_KEY=... -e NANOBOT_WEB_TOKEN=whatever \
  nanobot-miget agent -m "Hello!"
```

## Notes

- The agent can run shell commands inside its container (that is what it is for).
  It has no Docker socket and no Miget credentials, and `tools.restrictToWorkspace`
  keeps file work inside `/app/storage/workspace` unless you change it.
- Miget mounts a storage addon root-owned; the container runs as root so the
  volume stays writable.
