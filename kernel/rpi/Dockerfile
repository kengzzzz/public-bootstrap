FROM debian:trixie-slim

RUN apt-get update && apt-get install -y \
    build-essential git bc bison flex libssl-dev make libc6-dev libncurses-dev \
    kmod cpio pahole clang lld llvm rsync fakeroot sudo ca-certificates python3 \
    && if [ "$(uname -m)" = "x86_64" ]; then \
       apt-get install -y crossbuild-essential-arm64; \
    fi \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN groupadd wheel && \
    useradd -m -G wheel -s /bin/bash builder && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder

USER builder
WORKDIR /build