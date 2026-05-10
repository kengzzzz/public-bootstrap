FROM debian@sha256:4ffb3a1511099754cddc70eb1b12e50ffdb67619aa0ab6c13fcd800a78ef7c7a

ARG COMMIT_HASH=427645e3db3a8896714f22a3d3fe0c3f7b317ad4

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    build-essential git bc bison flex libssl-dev make libc6-dev libncurses-dev \
    kmod cpio dwarves clang lld llvm rsync fakeroot sudo ca-certificates python3 \
    zstd libelf-dev pkg-config wget curl xz-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN groupadd wheel && \
    useradd -m -G wheel -s /bin/bash builder && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder && \
    mkdir /src && \
    chown -R builder:builder /src

USER builder
WORKDIR /src

RUN git init && \
    git remote add origin https://github.com/microsoft/WSL2-Linux-Kernel.git && \
    git fetch --depth 1 origin "${COMMIT_HASH}" && \
    git checkout FETCH_HEAD

ENV LLVM=1