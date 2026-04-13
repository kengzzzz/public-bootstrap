#!/usr/bin/env bash
set -euo pipefail

echo "Bootstrap Arch Linux installer..."

pacman -Sy --noconfirm --needed git openssh libfido2

mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keyscan -H github.com >> ~/.ssh/known_hosts 2>/dev/null || true
chmod 644 ~/.ssh/known_hosts

eval "$(ssh-agent -s)" >/dev/null
ORIG_DIR="$(pwd)"
cd ~/.ssh
ssh-keygen -K
cd "$ORIG_DIR"

find ~/.ssh -name '*_sk*' 2>/dev/null | while read -r key; do
    rm -f "${key}.pub"
    ssh-add "$key" 2>/dev/null || true
done

PRIVATE_REPO="git@github.com:kengzzzz/dotfiles.git"
TEMP_DIR="/utils/scripts/install.sh"
BRANCH="main"

rm -rf "$TEMP_DIR"
git clone --depth 1 --no-checkout --filter=blob:none --branch "$BRANCH" "$PRIVATE_REPO" "$TEMP_DIR"

cd "$TEMP_DIR"
git sparse-checkout init --cone >/dev/null 2>&1
git sparse-checkout set install.sh >/dev/null 2>&1
git checkout >/dev/null 2>&1

chmod +x install.sh
echo "Running install.sh..."
exec ./install.sh