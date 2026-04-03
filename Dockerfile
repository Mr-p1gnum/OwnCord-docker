# Этап 1: Сборка приложения
FROM golang:1.25-alpine AS builder

WORKDIR /build

# Копируем файлы с зависимостями
COPY Server/go.mod Server/go.sum ./
RUN go mod download

# Копируем весь исходный код сервера
COPY Server/ .

# Сборка бинарного файла для Linux
RUN go build -o chatserver -ldflags "-s -w -X main.version=1.0.0"

# Этап 2: Финальный образ
FROM alpine:latest

WORKDIR /app

# Копируем собранный бинарный файл из этапа сборки
COPY --from=builder /build/chatserver .

# Создаем volume для постоянных данных (БД, конфиги, загрузки)
VOLUME [ "/app/data" ]

# Открываем порты (8443 - основной веб-интерфейс и WebSocket, 7880 - порт для LiveKit)
EXPOSE 8443
EXPOSE 7880

# Запускаем сервер
CMD [ "./chatserver" ]