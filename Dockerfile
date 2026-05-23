# Stage 1: build the React/Vite web UI
FROM node:lts-slim AS web-builder
WORKDIR /build/web
COPY microclaw/web/package*.json ./
RUN npm ci
COPY microclaw/web/ ./
RUN npm run build

# Stage 2: build the Rust binary (web/dist pre-built, skip npm in build.rs)
# rust:bookworm matches the Debian 12 base of the final image (glibc 2.36).
FROM rust:bookworm AS rust-builder
RUN apt-get update \
 && apt-get install -y --no-install-recommends mold \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /build
COPY microclaw/ .
COPY --from=web-builder /build/web/dist ./web/dist
RUN MICROCLAW_SKIP_WEB_BUILD=1 RUSTFLAGS="-C link-arg=-fuse-ld=mold" \
    cargo build --release --bin microclaw

# Stage 3: final image — upstream base (system config, entrypoint, etc.)
# plus the docker CLI for sandbox and our locally-built binary
FROM ghcr.io/microclaw/microclaw:latest
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends docker.io \
 && rm -rf /var/lib/apt/lists/*
COPY --from=rust-builder /build/target/release/microclaw /usr/local/bin/microclaw
USER microclaw
