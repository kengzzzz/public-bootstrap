FROM cachyos/cachyos@sha256:2c369119e890b3b5d64732b99f46ca83fb686728b0fe352347b924ffa4969dff

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

USER builder
WORKDIR /home/builder