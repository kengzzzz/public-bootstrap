FROM cachyos/cachyos@sha256:7f5b38a2da25cefe24c0b33fcfa98b96e7dc6480f4dd2633f55c3a986b54ea74

ARG COMMIT_HASH=4224303b6d7a50dd1cc3ffa78864050cc9536eec

RUN pacman-key --init && \
    pacman -Sy --noconfirm cachyos-keyring archlinux-keyring && \
    pacman -Su --noconfirm \
    base-devel git sudo wget bc cpio pahole xmlto kmod libelf python-sphinx pacman-contrib \
    rust rust-bindgen rust-src ncurses llvm \
    && pacman -Scc --noconfirm \
    && rm -rf /var/lib/pacman/sync/*

RUN useradd -m -G wheel builder && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder && \
    chmod 0440 /etc/sudoers.d/builder

WORKDIR /src

RUN git init && \
    git remote add origin https://github.com/CachyOS/linux-cachyos.git && \
    git fetch --depth 1 origin "${COMMIT_HASH}" && \
    git checkout FETCH_HEAD && \
    cd linux-cachyos-bore && \
    sed -i 's/_use_llvm_lto:=[^}]*/_use_llvm_lto:=full/' PKGBUILD

ENV LLVM=1 \
    BUILDDIR=/build