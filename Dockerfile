# syntax=docker/dockerfile:1

FROM rust:1-bookworm AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    git \
    pkg-config \
    curl \
    perl \
    clang \
    lld \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    --mount=type=cache,target=/app/target \
    cargo build --release \
    && mkdir -p /app/out \
    && cp target/release/forge /app/out/ \
    && cp target/release/cast /app/out/ \
    && cp target/release/anvil /app/out/ \
    && cp target/release/chisel /app/out/ \
    && strip /app/out/forge \
    && strip /app/out/cast \
    && strip /app/out/chisel \
    && strip /app/out/anvil

FROM ubuntu:22.04 AS runtime

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/out/* /usr/local/bin/

RUN groupadd -g 1000 foundry && \
    useradd -m -u 1000 -g foundry foundry && \
    git config --global --add safe.directory '*'
USER foundry
RUN git config --global --add safe.directory '*'

ENTRYPOINT ["/bin/sh", "-c"]

LABEL org.label-schema.name="Foundry" \
    org.label-schema.description="Foundry" \
    org.label-schema.url="https://getfoundry.sh" \
    org.label-schema.vcs-url="https://github.com/foundry-rs/foundry.git" \
    org.label-schema.vendor="Foundry-rs" \
    org.label-schema.schema-version="1.0"
