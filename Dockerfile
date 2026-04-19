# Этап 1: Сборка приложения
FROM golang:1.25-alpine AS owncord

WORKDIR /build

# Копируем файлы с зависимостями
COPY Server/go.mod Server/go.sum ./
RUN go mod download

# Копируем весь исходный код сервера
COPY Server/ .

# Сборка бинарного файла для Linux
RUN go build -o chatserver -ldflags "-s -w -X main.version=1.0.0"

# Этап 2: Livekit server
FROM golang:1.25-alpine AS livekit

ARG TARGETPLATFORM
ARG TARGETARCH
RUN echo building for "$TARGETPLATFORM"

WORKDIR /build

# Copy the Go Modules manifests
COPY livekit-1.11.0/go.mod go.mod
COPY livekit-1.11.0/go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY livekit-1.11.0/cmd/ cmd/
COPY livekit-1.11.0/pkg/ pkg/
COPY livekit-1.11.0/test/ test/
COPY livekit-1.11.0/tools/ tools/
COPY livekit-1.11.0/version/ version/

RUN CGO_ENABLED=0 GOOS=linux GOARCH=$TARGETARCH GO111MODULE=on go build -a -o livekit-server ./cmd/server

# Этап 3: Финальный образ
FROM alpine:latest

WORKDIR /app

# Копируем собранный бинарный файл из этапа сборки
COPY --from=owncord /build/chatserver .
COPY --from=livekit /build/livekit-server .

# Копируем скрипт для инициализации livekit и owncord
COPY docker-entrypoint.sh .
RUN sed -i 's/\r$//' /app/docker-entrypoint.sh

# Делаем скрипт исполняемым
RUN chmod +x /app/docker-entrypoint.sh

# Создаем volume для постоянных данных (БД, конфиги, загрузки)
VOLUME [ "/app/data" ]

# Открываем порты (8443 - основной веб-интерфейс и WebSocket, 7880 - порт для LiveKit)
EXPOSE 8443
EXPOSE 7880

# Запускаем сервер
ENTRYPOINT [ "./docker-entrypoint.sh" ]