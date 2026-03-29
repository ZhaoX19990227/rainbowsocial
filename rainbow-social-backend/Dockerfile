FROM golang:1.22-bookworm

WORKDIR /app

COPY dist/rainbow-social-backend /app/rainbow-social-backend
COPY downloads /app/downloads

ENV APP_ENV=production
ENV GIN_MODE=release
ENV PORT=8088
ENV SERVER_PORT=8088
ENV DATABASE_PATH=/data/social_app.db
ENV UPLOAD_DIR=/data/uploads
ENV DOWNLOAD_DIR=/app/downloads

EXPOSE 8088

ENTRYPOINT ["/app/rainbow-social-backend"]
