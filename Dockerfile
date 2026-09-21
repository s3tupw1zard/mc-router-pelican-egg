# syntax=docker/dockerfile:1.7

ARG MC_ROUTER_VERSION=1.47.1

FROM --platform=$BUILDPLATFORM alpine:3.22 AS downloader

ARG TARGETARCH
ARG MC_ROUTER_VERSION

RUN apk add --no-cache ca-certificates curl tar

RUN set -eux; \
    version="${MC_ROUTER_VERSION#v}"; \
    case "${TARGETARCH}" in \
      amd64|arm64) arch="${TARGETARCH}" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    asset="mc-router_${version}_linux_${arch}.tar.gz"; \
    base_url="https://github.com/itzg/mc-router/releases/download/v${version}"; \
    curl -fsSL "${base_url}/${asset}" -o "/tmp/${asset}"; \
    curl -fsSL "${base_url}/mc-router_${version}_checksums.txt" -o /tmp/checksums.txt; \
    grep " ${asset}$" /tmp/checksums.txt > /tmp/checksum.txt; \
    cd /tmp; \
    sha256sum -c checksum.txt; \
    mkdir -p /out; \
    tar -xzf "${asset}" -C /out; \
    test -x /out/mc-router || chmod +x /out/mc-router

FROM debian:bookworm-slim

ARG MC_ROUTER_VERSION

LABEL org.opencontainers.image.title="mc-router Pelican image" \
      org.opencontainers.image.description="Pelican-compatible runtime image for itzg/mc-router" \
      org.opencontainers.image.source="https://github.com/s3tupw1zard/mc-router-pelican-egg" \
      org.opencontainers.image.licenses="MIT" \
      io.s3tupw1zard.mc-router.version="${MC_ROUTER_VERSION}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        iproute2 \
        tini \
        tzdata \
    && useradd -m -d /home/container -s /bin/bash container \
    && rm -rf /var/lib/apt/lists/*

COPY --from=downloader /out/mc-router /usr/local/bin/mc-router
COPY licenses/mc-router-LICENSE.txt /usr/share/licenses/mc-router/LICENSE.txt
COPY --chown=container:container entrypoint.sh /entrypoint.sh

RUN chmod 0755 /usr/local/bin/mc-router /entrypoint.sh

ENV USER=container \
    HOME=/home/container \
    TZ=UTC \
    MC_ROUTER_VERSION="${MC_ROUTER_VERSION}"

USER container
WORKDIR /home/container

EXPOSE 25565/tcp

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
