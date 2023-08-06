FROM rust:alpine AS build

RUN apk update
RUN apk add cmake make musl-dev g++
RUN cargo install boringtun-cli

###

FROM alpine

ENV WG_QUICK_USERSPACE_IMPLEMENTATION boringtun
ENV WG_LOG_LEVEL info
ENV WG_LOG_FILE /var/log/boringtun
ENV WG_SUDO 1

RUN apk --update add iproute2 wireguard-tools-wg-quick libqrencode dnsmasq

WORKDIR /scripts

COPY --from=build /usr/local/cargo/bin/boringtun-cli /usr/local/bin/boringtun
COPY scripts/ ./

ENTRYPOINT ["/scripts/entrypoint.sh"]
