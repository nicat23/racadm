# syntax=docker/dockerfile:1

# Stage 1: Download and extract Dell RACADM for RHEL 9 (x86-64-v2 compatible)
FROM registry.access.redhat.com/ubi9/ubi-minimal AS racadm-build

ARG DSU=DSU_26.09.28
ARG OS=RHEL9_64
ARG SEMVER=11.4.0.0-1435.el9.x86_64

RUN set -eux; \
    microdnf install -y --setopt=install_weak_deps=0 \
        rpm; \
    mkdir -p /tmp/rpms; \
    cd /tmp/rpms; \
    for pkg in srvadmin-argtable2 srvadmin-idracadm7; do \
        curl --fail --show-error --location --retry 3 --retry-all-errors \
            --output "${pkg}.rpm" \
            "https://linux.dell.com/repo/hardware/${DSU}/os_dependent/${OS}/racadm/${pkg}-${SEMVER}.rpm"; \
    done; \
    rpm -Uvh --nodeps ./*.rpm; \
    test -x /opt/dell/srvadmin/bin/idracadm7

# Stage 2: Minimal Wolfi Runtime (x86-64-v2 compatible, 0 CVEs)
FROM cgr.dev/chainguard/wolfi-base:latest

LABEL org.opencontainers.image.title="Dell RACADM (Wolfi)" \
      org.opencontainers.image.description="Minimal Wolfi-based Dell RACADM CLI for remote iDRAC management (x86-64-v2 compatible)" \
      org.opencontainers.image.vendor="Dell Technologies"

ENV PAGER=cat \
    LD_LIBRARY_PATH="/opt/dell/srvadmin/lib64:/usr/lib64:/usr/lib:/lib"

RUN set -eux; \
    apk upgrade --no-cache; \
    apk add --no-cache \
        ca-certificates-bundle \
        libstdc++ \
        openssl-3.6-libcrypto \
        openssl-3.6-libssl; \
    SSL_LIB="$(find /lib /usr/lib -name 'libssl.so.3*' | head -n 1)"; \
    CRYPTO_LIB="$(find /lib /usr/lib -name 'libcrypto.so.3*' | head -n 1)"; \
    test -n "$SSL_LIB" && test -n "$CRYPTO_LIB"; \
    mkdir -p /usr/lib64; \
    ln -sf "$SSL_LIB" /usr/lib/libssl.so; \
    ln -sf "$CRYPTO_LIB" /usr/lib/libcrypto.so; \
    ln -sf "$SSL_LIB" /usr/lib64/libssl.so; \
    ln -sf "$CRYPTO_LIB" /usr/lib64/libcrypto.so; \
    test -e /usr/lib64/libssl.so && test -e /usr/lib64/libcrypto.so; \
    chown -R 1000:1000 /opt

COPY --from=racadm-build --chown=1000:1000 /opt/dell /opt/dell

USER 1000:1000
WORKDIR /opt/dell/srvadmin/bin

ENTRYPOINT ["/opt/dell/srvadmin/bin/idracadm7"]
CMD ["help"]