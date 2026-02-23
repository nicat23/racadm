# --- Stage 1: Build racadm environment ---
FROM alpine:3.23 AS emc
ARG DSU=DSU_26.02.09 \
	OS=RHEL10_64 \
	SEMVER=11.4.0.0-1435.el10.x86_64
RUN set -eux; \
    apk add --no-cache --virtual .build-deps curl rpm gcompat libc6-compat libstdc++ bash coreutils; \
    TMPDIR=/tmp/rpms; mkdir -p "$TMPDIR"; cd "$TMPDIR"; \
    echo "https://linux.dell.com/repo/hardware/${DSU}/os_dependent/${OS}/racadm/srvadmin-argtable2-${SEMVER}.rpm" > urls.txt; \
    echo "https://linux.dell.com/repo/hardware/${DSU}/os_dependent/${OS}/racadm/srvadmin-hapi-${SEMVER}.rpm" >> urls.txt; \
    echo "https://linux.dell.com/repo/hardware/${DSU}/os_dependent/${OS}/racadm/srvadmin-idracadm7-${SEMVER}.rpm" >> urls.txt; \
    while read -r url; do \
        fn=$(basename "$url"); \
        echo "Downloading $fn"; \
        curl --proto '=https' --tlsv1.2 --retry 5 --retry-delay 2 --fail --show-error --location -o "$fn" "$url"; \
    done < urls.txt; \
    rpm -Uvh --nodeps --force ./*.rpm; \
    if command -v ldd >/dev/null 2>&1; then ldd /opt/dell/srvadmin/bin/idracadm7 || true; fi; \
    rm -rf "$TMPDIR"; \
    apk del --purge .build-deps || true

# --- Stage 2: Minimal runtime image ---
FROM alpine:3.23
COPY --from=emc /opt/dell /opt/dell
#COPY --from=emc /opt/dell/srvadmin/bin/idracadm7 /opt/dell/srvadmin/bin/idracadm7

ENV PAGER=cat \
    SHELL=/bin/sh
RUN addgroup -g 1000 -S appgroup \
    && adduser -u 1000 -S appuser -G appgroup -s /bin/sh \
    && apk add --no-cache gcompat libc6-compat libstdc++ sudo \
    && [ ! -e /usr/lib/libssl.so ] && { \
    if [ -e /usr/lib/libssl.so.3 ]; then \
        ln -s /usr/lib/libssl.so.3 /usr/lib/libssl.so; \
    elif [ -e /usr/lib64/libssl.so.3 ]; then \
        ln -s /usr/lib64/libssl.so.3 /usr/lib/libssl.so; \
    fi; \
    } \
    && printf '%s\n' \
        '#!/bin/sh' \
        '# Auto-generated racadm wrapper script' \
        '# This script automatically handles privilege escalation for racadm' \
        '' \
        'RACADM_BINARY="/opt/dell/srvadmin/bin/idracadm7"' \
        '' \
        '# Check if the actual racadm binary exists' \
        'if [ ! -x "$RACADM_BINARY" ]; then' \
        '    echo "Error: racadm binary not found at $RACADM_BINARY" >&2' \
        '    exit 1' \
        'fi' \
        '' \
        '# If already running as root, execute directly' \
        'if [ "$(id -u)" = "0" ]; then' \
        '    exec "$RACADM_BINARY" "$@"' \
        'else' \
        '    # Use sudo for privilege escalation' \
        '    exec sudo "$RACADM_BINARY" "$@"' \
        'fi' \
    > /usr/bin/racadm && chmod 0755 /usr/bin/racadm \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/* \
    && printf "%b" "\
    Defaults env_reset\n\
    Defaults secure_path=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\n\
    Defaults passwd_timeout=0\n\
    Defaults !requiretty\n\
    %appgroup ALL=(root) NOPASSWD: /usr/bin/racadm, /opt/dell/srvadmin/bin/idracadm7\n" \
    > /etc/sudoers.d/app && \
    chmod 0440 /etc/sudoers.d/app && \
    visudo -c && \
    sudo -u appuser sudo -l | grep -q racadm && echo "Sudo configuration verified" || echo "Sudo configuration failed"
USER appuser

ENTRYPOINT ["racadm"]
CMD []
