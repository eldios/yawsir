# syntax=docker/dockerfile:1

################################################################################
# COMMON BUILD ARGS
ARG RUST_VERSION=1.76
ARG DEBIAN_VERSION=bookworm
ARG APP_NAME=yawsir

################################################################################
# BUILDER
FROM rust:${RUST_VERSION}-slim-${DEBIAN_VERSION} as builder
ARG APP_NAME
WORKDIR /app

COPY src src
COPY Cargo.toml Cargo.toml
COPY Cargo.lock Cargo.lock
RUN  cargo build --locked --release

################################################################################
# FINAL IMAGE - RUNTIME
FROM debian:${DEBIAN_VERSION}-slim AS final
WORKDIR /app
ARG APP_NAME
ENV APP_NAME ${APP_NAME}

COPY --from=builder /app/target/release/${APP_NAME} /app/${APP_NAME}

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
ARG UID=10001
RUN adduser                 \
  --disabled-password       \
  --gecos ""                \
  --home "/nonexistent"     \
  --shell "/sbin/nologin"   \
  --no-create-home          \
  --uid "${UID}"            \
  appuser                 &&\
  chown -R appuser:  /app &&\
  chmod -R ug=rwX,o= /app
USER appuser

# workaround to bind Rocket http listener to all interfaces
ENV ROCKET_ADDRESS "0.0.0.0"

# What the container should run when it is started.
CMD /app/${APP_NAME}
