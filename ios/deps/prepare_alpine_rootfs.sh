#!/bin/bash
set -e

# Prepare Alpine Linux aarch64 rootfs for iSH-ARM64.
# Adapted from OpenMinis/deps/prepare_alpine_rootfs.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISH_DIR="$SCRIPT_DIR/ish"
OUTPUT_DIR="$SCRIPT_DIR/../ish_sandbox/Classes/deps/resources"
CACHE_DIR="$SCRIPT_DIR/.cache"

ALPINE_VERSION="${1:-3.21}"
ALPINE_MINOR="0"
ALPINE_ARCH="aarch64"
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine"

log_info() { echo "[rootfs] $1"; }
log_error() { echo "[rootfs] ERROR: $1" >&2; exit 1; }

check_prerequisites() {
    log_info "Checking prerequisites..."
    command -v curl >/dev/null 2>&1 || log_error "curl required"
    command -v meson >/dev/null 2>&1 || log_error "meson required"
    command -v ninja >/dev/null 2>&1 || log_error "ninja required"
    log_info "Prerequisites OK"
}

download_alpine() {
    mkdir -p "$CACHE_DIR"
    local ROOTFS_FILE="alpine-minirootfs-${ALPINE_VERSION}.${ALPINE_MINOR}-${ALPINE_ARCH}.tar.gz"
    local ROOTFS_PATH="$CACHE_DIR/$ROOTFS_FILE"
    local ROOTFS_URL="${ALPINE_MIRROR}/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/${ROOTFS_FILE}"

    if [ -f "$ROOTFS_PATH" ]; then
        log_info "Using cached rootfs: $ROOTFS_FILE"
    else
        log_info "Downloading $ROOTFS_URL"
        curl -L -o "$ROOTFS_PATH" "$ROOTFS_URL"
    fi
    echo "$ROOTFS_PATH"
}

build_fakefsify() {
    local BUILD_DIR="$ISH_DIR/build-native"
    if [ -x "$BUILD_DIR/tools/fakefsify" ]; then
        log_info "fakefsify already built"
        return
    fi
    log_info "Building fakefsify..."
    mkdir -p "$BUILD_DIR"
    cd "$ISH_DIR"
    if [ ! -f "$BUILD_DIR/build.ninja" ]; then
        meson setup "$BUILD_DIR" \
            --buildtype=release \
            -Dlog="" \
            -Dkernel=ish \
            -Dengine=asbestos \
            -Dguest_arch=arm64
    fi
    ninja -C "$BUILD_DIR" tools/fakefsify
    cd "$SCRIPT_DIR"
}

create_fakefs() {
    local ROOTFS_PATH
    ROOTFS_PATH="$(download_alpine)"
    local FAKEFSIFY="$ISH_DIR/build-native/tools/fakefsify"
    local OUTPUT_ROOTFS="$OUTPUT_DIR/alpine-rootfs"

    rm -rf "$OUTPUT_ROOTFS"
    mkdir -p "$OUTPUT_DIR"
    "$FAKEFSIFY" "$ROOTFS_PATH" "$OUTPUT_ROOTFS"

    if [ ! -d "$OUTPUT_ROOTFS/data" ] || [ ! -f "$OUTPUT_ROOTFS/meta.db" ]; then
        log_error "Failed to create fakefs rootfs"
    fi
}

configure_rootfs() {
    log_info "Configuring rootfs..."
    local ROOTFS_DATA="$OUTPUT_DIR/alpine-rootfs/data"
    mkdir -p "$ROOTFS_DATA/dev" "$ROOTFS_DATA/proc" "$ROOTFS_DATA/sys" \
        "$ROOTFS_DATA/tmp" "$ROOTFS_DATA/run" "$ROOTFS_DATA/root" "$ROOTFS_DATA/home"

    if [ -f "$ROOTFS_DATA/etc/passwd" ]; then
        sed -i.bak 's|^root:.*|root:x:0:0:root:/root:/bin/sh|' "$ROOTFS_DATA/etc/passwd"
        rm -f "$ROOTFS_DATA/etc/passwd.bak"
    fi

    cat >> "$ROOTFS_DATA/etc/profile" <<'EOF'
export PS1='\u@henglu:\w\$ '
export TERM=xterm-256color
export HOME=/root
export LANG=C.UTF-8
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF

    cat > "$ROOTFS_DATA/etc/resolv.conf" <<'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
}

create_zip_archive() {
    local ZIP_FILE="$OUTPUT_DIR/alpine-rootfs.zip"
    rm -f "$ZIP_FILE"
    cd "$OUTPUT_DIR"
    zip -r "alpine-rootfs.zip" "alpine-rootfs" -x "*.db-shm" -x "*.db-wal" >/dev/null
    cd "$SCRIPT_DIR"
    log_info "Created $ZIP_FILE ($(du -h "$ZIP_FILE" | cut -f1))"
}

main() {
    check_prerequisites
    build_fakefsify
    create_fakefs
    configure_rootfs
    create_zip_archive
    log_info "Rootfs ready."
}

main "$@"
