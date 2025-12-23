# syntax=docker/dockerfile:1

FROM rust:1-bookworm AS chef
WORKDIR /app

RUN apt update && apt install -y build-essential libssl-dev git pkg-config curl perl clang lld
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | sh
RUN cargo binstall cargo-chef -y

COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM rust:1-bookworm AS builder
WORKDIR /app

RUN apt update && apt install -y build-essential libssl-dev git pkg-config curl perl clang lld
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | sh
RUN cargo binstall cargo-chef -y

COPY --from=chef /app/recipe.json recipe.json
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    cargo chef cook --release --recipe-path recipe.json

COPY . .
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    cargo build --release \
    && mkdir -p /app/out \
    && mv target/release/forge /app/out/ \
    && mv target/release/cast /app/out/ \
    && mv target/release/anvil /app/out/ \
    && mv target/release/chisel /app/out/ \
    && strip /app/out/forge \
    && strip /app/out/cast \
    && strip /app/out/chisel \
    && strip /app/out/anvil

FROM ubuntu:22.04 AS runtime

RUN apt update && apt install -y git

COPY --from=builder /app/out/* /usr/local/bin/

RUN groupadd -g 1000 foundry && \
    useradd -m -u 1000 -g foundry foundry
USER foundry

ENTRYPOINT ["/bin/sh", "-c"]

LABEL org.label-schema.name="Foundry" \
    org.label-schema.description="Foundry" \
    org.label-schema.url="https://getfoundry.sh" \
    org.label-schema.vcs-url="https://github.com/foundry-rs/foundry.git" \
    org.label-schema.vendor="Foundry-rs" \
    org.label-schema.schema-version="1.0"
