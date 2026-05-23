# Stage 1: build the React/Vite web UI
FROM node:lts-slim AS web-builder
WORKDIR /build/web
COPY microclaw/web/package*.json ./
RUN npm ci
COPY microclaw/web/ ./
RUN npm run build

# Stage 2: build the Rust binary (web/dist pre-built, skip npm in build.rs)
FROM rust:latest AS rust-builder
WORKDIR /build
COPY microclaw/ .
COPY --from=web-builder /build/web/dist ./web/dist
RUN MICROCLAW_SKIP_WEB_BUILD=1 cargo build --release --bin microclaw

# Stage 3: final image — upstream base (system config, entrypoint, etc.)
# plus the docker CLI for sandbox and our locally-built binary
FROM ghcr.io/microclaw/microclaw:latest
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends docker.io \
 && rm -rf /var/lib/apt/lists/*
COPY --from=rust-builder /build/target/release/microclaw /usr/local/bin/microclaw
USER microclaw
