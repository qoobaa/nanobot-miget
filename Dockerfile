# nanobot (HKUDS/nanobot) packaged for Miget.
#
# Miget serves HTTP only on port 5000, so the WebUI/WebSocket channel is bound
# there (see config.template.json). Everything stateful lives under
# /app/storage, which is where a Miget storage add-on is mounted.
FROM python:3.12-slim-bookworm

# Pinned so an upstream release never lands without a deliberate bump.
ARG NANOBOT_VERSION=0.3.5

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DATA_DIR=/app/storage

# git + ripgrep are used by the agent's own tools; curl helps debugging.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git ripgrep curl \
 && rm -rf /var/lib/apt/lists/*

RUN pip install "nanobot-ai==${NANOBOT_VERSION}"

WORKDIR /app
COPY config.template.json /app/config.template.json
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && mkdir -p /app/storage

EXPOSE 5000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["gateway"]
