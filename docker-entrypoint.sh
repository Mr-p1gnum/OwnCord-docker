#!/bin/sh
set -e

CONFIG_DIR="/app"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

# Проверяем, существует ли уже конфиг (чтобы не перезаписывать при перезапусках)
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Конфигурационный файл не найден. Запускаю сервер для его генерации..."

    # Запускаем chatserver в фоне на короткое время или до создания файла
    /app/chatserver --generate-config &  # предположим, что такой флаг есть
    # Если флага нет, просто запускаем и ждём появления файла
    SERVER_PID=$!

    # Ждём появления config.yaml (максимум 10 секунд)
    for i in $(seq 1 10); do
        if [ -f "$CONFIG_FILE" ]; then
            echo "Конфигурационный файл создан."
            break
        fi
        sleep 1
    done

    # Останавливаем временный сервер
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true

    # Генерируем ключи LiveKit
    echo "Генерация ключей LiveKit..."
    KEYS_OUTPUT=$(/app/livekit-server generate-keys)
    LIVEKIT_API_KEY=$(echo "$KEYS_OUTPUT" | awk '/API Key:/ {print $3}')
    LIVEKIT_API_SECRET=$(echo "$KEYS_OUTPUT" | awk '/API Secret:/ {print $3}')

    # Вписываем ключи в конфиг
    if [ -f "$CONFIG_FILE" ]; then
        sed -i.bak  "s|# livekit_api_key:.*|livekit_api_key: \"$LIVEKIT_API_KEY\"|" "$CONFIG_FILE"
        sed -i.bak  "s|# livekit_api_secret:.*|livekit_api_secret: \"$LIVEKIT_API_SECRET\"|" "$CONFIG_FILE"
        sed -i.bak  's|# livekit_binary:.*|livekit_binary: "/app/livekit-server"|' "$CONFIG_FILE"
        sed -i.bak  's|livekit_url:.*|livekit_url: "http://localhost:7880"|' "$CONFIG_FILE"
        sed -i.bak  's|# quality:.*|quality: "medium"|' "$CONFIG_FILE"
        echo "Ключи LiveKit добавлены в конфигурацию."
    else
        echo "Ошибка: конфигурационный файл не был создан!" >&2
        exit 1
    fi
fi

# Запускаем основной сервер
exec /app/chatserver