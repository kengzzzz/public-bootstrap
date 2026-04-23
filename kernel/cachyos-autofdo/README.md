# Create Config

- `docker compose run --rm kernel-config`

# Compile Kernel

- `docker compose run --rm kernel-builder`

# Prepare Installation

- update `/etc/mkinitcpio.d/linux-cachyos.preset` add `default_options="-S autodetect"`

# Installation

- `sudo pacman -U --overwrite '*' ./out/linux-cachyos*.pkg.tar.zst`

# Prepare

### Host

- `sudo sh -c "echo 0 > /proc/sys/kernel/kptr_restrict"`
- `sudo sh -c "echo 0 > /proc/sys/kernel/perf_event_paranoid"`
- `docker run -it --rm --privileged --pid=host -v /usr/lib/modules:/usr/lib/modules:ro -v $(pwd):/workspace cachyos/cachyos@sha256:6bb7a49d936b87ef4ff3b5333d9deb888f1fd1d5972554bc3788b9b833ac10b4 /bin/bash`

### Container

- `pacman -Sy --noconfirm perf wget unzip`
- `wget https://github.com/google/autofdo/releases/download/v0.30.1/create_llvm_prof-x86_64-v0.30.1.zip`
- `unzip create_llvm_prof-x86_64-v0.30.1.zip`
- `chmod +x create_llvm_prof`

# Workload

### Host

- burn your CPU around 20 mins

### Container

- `perf record --pfm-events RETIRED_TAKEN_BRANCH_INSTRUCTIONS:k -a -N -b -c 500009 -o /workspace/kernel.data sleep 1200`

# Collect Result

### Host

- `mkdir extract_dbg`
- `tar --use-compress-program=zstd -xvf out/linux-cachyos-dbg-*.pkg.tar.zst -C extract_dbg`


### Container

- `./create_llvm_prof --binary=/workspace/extract_dbg/usr/src/debug/linux-cachyos/vmlinux --profile=/workspace/kernel.data --format=extbinary --out=/workspace/kernel.afdo`