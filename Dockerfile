FROM alpine:latest

RUN set -e && \
apk add --no-cache go && \
mkdir /src && \
cd /src && \
wget https://github.com/J3vb/OwnCord/archive/refs/tags/v1.0.0.tar.gz && \
tar xvf v1.0.0.tar.gz && \
cd OwnCord-1.0.0/Serlsver && \ 
go build -o chatserver.exe -ldflags "-s -w -X main.version=1.0.0" && \