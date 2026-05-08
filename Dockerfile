FROM python:3.12-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app
COPY pyproject.toml .
COPY src/ src/

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --no-dev


FROM python:3.12-slim

RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 --ingroup app --home /home/app app && \
    mkdir -p /home/app/.deepseek-cursor-proxy && \
    chown app:app /home/app /home/app/.deepseek-cursor-proxy

WORKDIR /app

COPY --from=builder /app /app
COPY --from=builder /app/.venv /app/.venv
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

VOLUME /home/app/.deepseek-cursor-proxy

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
CMD []
