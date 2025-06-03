# Build stage: use latest Go with Debian Bookworm
FROM golang:1.24-bookworm AS builder

WORKDIR /app/gohttpserver

# Copy go.mod and go.sum first to leverage Docker cache for dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the Go binary statically with version info
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-X main.VERSION=docker" -o gohttpserver

# Final stage: use minimal Debian slim image
FROM debian:bookworm-slim

WORKDIR /app

# Install only ca-certificates for HTTPS support, clean apt cache to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create public directory and declare it as a volume
RUN mkdir -p /app/public
VOLUME /app/public

# Copy static assets and the built binary from the builder stage
COPY assets ./assets
COPY --from=builder /app/gohttpserver/gohttpserver .

# Expose the application port
EXPOSE 8000

# Entrypoint and default command
ENTRYPOINT ["/app/gohttpserver", "--root=/app/public"]
CMD []
