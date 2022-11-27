FROM rust:slim AS build

RUN rustup target add x86_64-unknown-linux-musl
RUN apt update && apt install -y musl-tools musl-dev
RUN cargo install --target x86_64-unknown-linux-musl boringtun-cli

###

FROM alpine

ENV WG_QUICK_USERSPACE_IMPLEMENTATION boringtun
ENV WG_LOG_LEVEL info
ENV WG_LOG_FILE /var/log/boringtun
ENV WG_SUDO 1

RUN apk --update add iproute2 wireguard-tools-wg-quick libqrencode
COPY --from=build /usr/local/cargo/bin/boringtun-cli /usr/local/bin/boringtun
COPY create-config.sh entrypoint.sh ./
COPY add-client.sh entrypoint.sh ./

ENTRYPOINT ["./entrypoint.sh"]
