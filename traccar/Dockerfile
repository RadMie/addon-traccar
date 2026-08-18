ARG BUILD_FROM=ghcr.io/hassio-addons/base:19.0.0
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy root filesystem
COPY rootfs /

# Set working dir
WORKDIR /opt/traccar

# Setup base
ARG TRACCAR_VERSION="v6.14.5"
ARG TRACCAR_SHA256="1395ddcab4e9b358829b3a8b1590deea102b2122c78778c6eee86986decfae97"
RUN \
    apk add --no-cache \
        mariadb-client=11.4.12-r0 \
        nginx=1.28.3-r7 \
        nss=3.114-r0 \
        openjdk21-jre-headless=21.0.11_p10-r0 \
        xmlstarlet=1.6.1-r2 \
    \
    && curl -fsSL --retry 3 -o /tmp/traccar.zip \
      "https://github.com/traccar/traccar/releases/download/${TRACCAR_VERSION}/traccar-other-${TRACCAR_VERSION#v}.zip" \
    && echo "${TRACCAR_SHA256}  /tmp/traccar.zip" | sha256sum -c - \
    \
    && mkdir -p /opt/traccar \
    && unzip -d /opt/traccar /tmp/traccar.zip \
    \
    && rm -fr /tmp/*

# Build arguments supplied by Home Assistant Supervisor and the CI builder
ARG BUILD_ARCH
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="Traccar 6 (RadMie)" \
    io.hass.description="Modern GPS Tracking Platform - Traccar 6.14.5" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="app" \
    io.hass.url="https://github.com/RadMie/addon-traccar" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="RadMie <https://github.com/RadMie>" \
    org.opencontainers.image.title="Traccar 6 for Home Assistant" \
    org.opencontainers.image.description="Modern GPS Tracking Platform - Traccar 6.14.5" \
    org.opencontainers.image.vendor="RadMie" \
    org.opencontainers.image.authors="RadMie; Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.licenses="MIT AND Apache-2.0" \
    org.opencontainers.image.url="https://github.com/RadMie/addon-traccar" \
    org.opencontainers.image.source="https://github.com/RadMie/addon-traccar" \
    org.opencontainers.image.documentation="https://github.com/RadMie/addon-traccar/blob/main/traccar/DOCS.md" \
    org.opencontainers.image.version="${BUILD_VERSION}"
