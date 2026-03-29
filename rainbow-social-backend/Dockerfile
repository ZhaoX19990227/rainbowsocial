FROM golang:1.22-bookworm AS builder

WORKDIR /src
ENV GOPROXY=https://proxy.golang.org,direct
ENV GOSUMDB=sum.golang.org

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/rainbow-social-backend ./main.go

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates tzdata \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /out/rainbow-social-backend /app/rainbow-social-backend
COPY --from=builder /src/downloads /app/downloads

RUN mkdir -p /data/uploads /app/downloads

ENV APP_ENV=production
ENV GIN_MODE=release
ENV PORT=8088
ENV SERVER_PORT=8088
ENV DATABASE_PATH=/data/social_app.db
ENV UPLOAD_DIR=/data/uploads
ENV DOWNLOAD_DIR=/app/downloads

EXPOSE 8088

CMD ["/app/rainbow-social-backend"]
