FROM archlinux@sha256:5ba8bb318666baef4d33afefc0e65db80f38b23503cb8e7b150d315cc2d4d5da AS cachyos-base

RUN pacman -Syy --noconfirm --needed curl && \
    pacman-key --init && \
    curl -L https://mirror.cachyos.org/cachyos-repo.tar.xz | tar xJ && \
    cd cachyos-repo && \
    yes | ./cachyos-repo.sh && \
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    pacman -Syu --noconfirm cachyos-keyring archlinux-keyring
    
FROM cachyos-base

ARG COMMIT_HASH=4224303b6d7a50dd1cc3ffa78864050cc9536eec

RUN pacman -Syyu --noconfirm --needed \
    base-devel git sudo wget bc cpio pahole xmlto kmod libelf python-sphinx pacman-contrib \
    rust rust-bindgen rust-src ncurses llvm \
    && pacman -Scc --noconfirm \
    && rm -rf /var/lib/pacman/sync/* && \
    useradd -m -G wheel builder && \
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