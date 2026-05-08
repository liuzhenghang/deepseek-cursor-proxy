#!/bin/sh
set -e

# 修复 bind mount 目录权限（此时以 root 运行）
mkdir -p /home/app/.deepseek-cursor-proxy
chown app:app /home/app/.deepseek-cursor-proxy

args=""

for var in \
    "PROXY_HOST=--host" \
    "PROXY_PORT=--port" \
    "BASE_URL=--base-url" \
    "MODEL=--model" \
    "THINKING=--thinking" \
    "REASONING_EFFORT=--reasoning-effort" \
    "REQUEST_TIMEOUT=--request-timeout" \
    "MAX_REQUEST_BODY_BYTES=--max-request-body-bytes" \
    "MISSING_REASONING_STRATEGY=--missing-reasoning-strategy" \
    "REASONING_CACHE_MAX_AGE_SECONDS=--reasoning-cache-max-age-seconds" \
    "REASONING_CACHE_MAX_ROWS=--reasoning-cache-max-rows" \
    "TRACE_DIR=--trace-dir" \
    "CONFIG_PATH=--config"; do
    env_name="${var%=*}"
    flag_name="${var#*=}"
    eval "val=\"\$${env_name}\""
    if [ -n "$val" ]; then
        args="$args $flag_name $val"
    fi
done

# 容器内 ngrok 默认关闭
NGROK="${NGROK:-0}"

for var in \
    "VERBOSE=--verbose" \
    "CORS=--cors" \
    "DISPLAY_REASONING=--display-reasoning" \
    "COLLAPSIBLE_REASONING=--collapsible-reasoning" \
    "NGROK=--ngrok"; do
    env_name="${var%=*}"
    flag_name="${var#*=}"
    eval "val=\"\$${env_name}\""
    if [ -n "$val" ]; then
        case "$val" in
            1|true|yes|on)  args="$args $flag_name" ;;
            0|false|no|off) args="$args --no-$(echo $flag_name | sed 's/^--//')" ;;
        esac
    fi
done

if [ "${CLEAR_REASONING_CACHE:-}" = "1" ] || [ "${CLEAR_REASONING_CACHE:-}" = "true" ]; then
    args="$args --clear-reasoning-cache"
fi

# 降权到 app 用户运行
exec su -s /bin/sh -c "exec python -m deepseek_cursor_proxy $args" app
