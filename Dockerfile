# Stage 1: Prepare the root filesystem and create a tarball
FROM --platform=linux/arm64 ubuntu:22.04 AS rootfs_builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y systemd systemd-sysv git python3-pip adduser
RUN useradd --create-home --shell /bin/bash appuser
# Create a compressed archive of the entire filesystem
RUN tar -czf /rootfs.tar.gz --exclude=/rootfs.tar.gz --exclude=/dev --exclude=/proc --exclude=/sys /

# Stage 2: Prepare the boot filesystem and create a tarball
FROM debian:stable-slim AS bootfs_builder
RUN apt-get update && apt-get install -y git && \
    git clone --depth=1 https://github.com/raspberrypi/firmware.git /rpi-firmware && \
    tar -czf /bootfs.tar.gz -C /rpi-firmware/boot .

# Stage 3: Assemble the final image using guestfish
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
# Install guestfish and its dependencies, then immediately clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends libguestfs-tools linux-image-generic && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create the output directory
RUN mkdir -p /output

# Copy the prepared tarballs from previous stages
COPY --from=rootfs_builder /rootfs.tar.gz /
COPY --from=bootfs_builder /bootfs.tar.gz /

# Copy the assembly script
COPY scripts/create-image.sh /usr/local/bin/create-image.sh
RUN chmod +x /usr/local/bin/create-image.sh

# Run the script to create the final .img file
CMD ["/usr/local/bin/create-image.sh"]