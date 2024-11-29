FROM rust:1.82.0-bookworm AS builder

RUN set -ex \
        \
    && rustup target add x86_64-unknown-linux-musl \
    && rustup toolchain install stable \
    && rustup toolchain install nightly --component rust-src \
    && cargo install bpf-linker

COPY Cargo.toml /opt/app/Cargo.toml
COPY protego /opt/app/protego
COPY protego-ebpf/ /opt/app/protego-ebpf
COPY protego-common/ /opt/app/protego-common

WORKDIR /opt/app

RUN --mount=type=cache,target=/usr/local/cargo/registry true \
    set -ex \
        \
    && cargo build --release --target=x86_64-unknown-linux-musl --config 'target."cfg(all())".runner="sudo -E"'


FROM alpine:3.20.3 AS runtime

RUN set -ex \
        \
    && apk update \
    && apk upgrade \
    && apk add --update --no-cache tini curl \
    && rm -rf /var/cache/apk/*

WORKDIR /opt/app

COPY --from=builder /opt/app/target/x86_64-unknown-linux-musl/release/protego /opt/app/protego

ENTRYPOINT ["/sbin/tini", "-s", "--"]
CMD ["/opt/app/protego", "-i", "eth0"]
