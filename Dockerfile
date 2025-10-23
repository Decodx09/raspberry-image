# Stage 1: Prepare the root filesystem with all MVP features
FROM --platform=linux/arm64 ubuntu:22.04 AS rootfs_builder
ENV DEBIAN_FRONTEND=noninteractive

# Install all software: ModemManager for internet, plus our other tools
RUN apt-get update && apt-get install -y \
    modemmanager \
    systemd \
    systemd-sysv \
    git \
    python3-pip \
    curl \
    jq

# Copy ALL of our custom scripts and services into the builder
COPY automonQR.sh /tmp/
COPY update-app.sh /tmp/
COPY first-boot.sh /tmp/
COPY automon-qr.service /tmp/
COPY myapp.service /tmp/
COPY first-boot.service /tmp/

RUN \
    # Create the app user
    useradd --create-home --shell /bin/bash appuser && \
    \
    # Create the blue-green directory structure
    mkdir -p /opt/app/blue /opt/app/green && \
    ln -sfn /opt/app/blue /opt/app/current && \
    \
    # Clone your application (REPLACE WITH YOUR REPO URL)
    GIT_TERMINAL_PROMPT=0 git clone https://github.com/Decodx09/k8s.git /opt/app/blue && \
    touch /opt/app/blue/.env && \
    chown -R appuser:appuser /opt/app && \
    \
    # Install all scripts to their final location
    mv /tmp/automonQR.sh /usr/local/bin/automonQR.sh && \
    mv /tmp/update-app.sh /usr/local/bin/update-app.sh && \
    mv /tmp/first-boot.sh /usr/local/bin/first-boot.sh && \
    chmod +x /usr/local/bin/*.sh && \
    \
    # Install and enable all the systemd services
    mv /tmp/automon-qr.service /etc/systemd/system/automon-qr.service && \
    mv /tmp/myapp.service /etc/systemd/system/myapp.service && \
    mv /tmp/first-boot.service /etc/systemd/system/first-boot.service && \
    systemctl enable automon-qr.service && \
    systemctl enable myapp.service && \
    systemctl enable first-boot.service


# Stage 2: Prepare the boot filesystem
FROM debian:stable-slim AS bootfs_builder
RUN apt-get update && apt-get install -y git && \
    git clone --depth=1 https://github.com/raspberrypi/firmware.git /rpi-firmware && \
    mkdir /bootfs && \
    cp -r /rpi-firmware/boot/* /bootfs/


# Stage 3: Assemble the final image
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends dosfstools e2fsprogs fdisk util-linux sudo git ca-certificates

RUN mkdir -p /output
RUN git clone --depth=1 https://github.com/raspberrypi/firmware.git /rpi-firmware
COPY --from=rootfs_builder / /rootfs/
COPY scripts/create-image.sh /usr/local/bin/create-image.sh
CMD ["/usr/local/bin/create-image.sh"]