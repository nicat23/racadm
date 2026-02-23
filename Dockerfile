# --- Stage 1: Build racadm environment ---
FROM alpine:3.23 AS emc

RUN apk add --no-cache --virtual .build-deps curl rpm \
    && apk add --no-cache gcompat libc6-compat libstdc++ \
    && rpm -ivh --nodeps --force \
        https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-argtable2-11.0.0.0-5268.el9.x86_64.rpm \
        https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-hapi-11.0.0.0-5268.el9.x86_64.rpm \
        https://linux.dell.com/repo/hardware/DSU_24.11.11/os_dependent/RHEL9_64/srvadmin/srvadmin-idracadm7-11.0.0.0-5268.el9.x86_64.rpm \
    && apk del .build-deps \
    # && ln -sf /opt/dell/srvadmin/bin/idracadm7 /usr/bin/racadm \
    # && chmod +x /usr/bin/racadm \
       # Generate wrapper script instead of symlink
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
    > /usr/bin/racadm \
    && chmod +x /usr/bin/racadm \
    && rm -rf /opt/dell/srvadmin/share /opt/dell/srvadmin/var /opt/dell/srvadmin/logs \
              /var/cache/apk/* /var/log/* /tmp/*

# --- Stage 2: Minimal runtime image ---
FROM alpine:3.23

RUN apk add --no-cache gcompat libc6-compat libstdc++

# Copy racadm binary + Dell libs
COPY --from=emc /opt/dell /opt/dell
COPY --from=emc /usr/bin/racadm /usr/bin/racadm
RUN [ ! -e /usr/lib/libssl.so ] && { \
    if [ -e /usr/lib/libssl.so.3 ]; then \
    ln -s /usr/lib/libssl.so.3 /usr/lib/libssl.so; \
    elif [ -e /usr/lib64/libssl.so.3 ]; then \
    ln -s /usr/lib64/libssl.so.3 /usr/lib/libssl.so; \
    fi; \
    }

ENTRYPOINT ["racadm"]
CMD []
