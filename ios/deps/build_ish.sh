#!/bin/bash
set -e

# Build iSH-ARM64 static libraries for embedding into Kelivo/Henglu.
# Adapted from OpenMinis/deps/build_ish.sh.
#
# Run from repository root:
#   cd ios/deps && ./build_ish.sh
#
# Output:
#   ios/deps/libs/*.a
#   ios/deps/include/ish/*.h
#   ios/deps/resources/libvdso.so.elf

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISH_DIR="$SCRIPT_DIR/ish"
# Place iSH build artifacts inside the local CocoaPods plugin so it can link them.
OUTPUT_ROOT="$SCRIPT_DIR/../ish_sandbox/Classes/deps"
OUTPUT_LIBS="$OUTPUT_ROOT/libs"
OUTPUT_INCLUDE="$OUTPUT_ROOT/include"
OUTPUT_RESOURCES="$OUTPUT_ROOT/resources"

BUILD_TYPE="${1:-release}"
ARCHS="arm64"
IOS_DEPLOYMENT_TARGET="14.0"

log_info() { echo "[ish-build] $1"; }
log_error() { echo "[ish-build] ERROR: $1" >&2; exit 1; }

check_prerequisites() {
    log_info "Checking prerequisites..."
    command -v python3 >/dev/null 2>&1 || log_error "python3 required"
    command -v meson >/dev/null 2>&1 || log_error "meson required: pip3 install meson"
    command -v ninja >/dev/null 2>&1 || log_error "ninja required: brew install ninja"
    xcode-select -p >/dev/null 2>&1 || log_error "Xcode command line tools required"
    log_info "Prerequisites OK"
}

clone_ish() {
    if [ ! -d "$ISH_DIR/.git" ]; then
        log_info "Cloning OpenMinis/ish-arm64..."
        rm -rf "$ISH_DIR"
        git clone --depth 1 --branch feature-arm64 https://github.com/OpenMinis/ish-arm64.git "$ISH_DIR"
    else
        log_info "iSH source already present"
    fi
}

init_submodules() {
    log_info "Initializing iSH submodules..."
    cd "$ISH_DIR"
    if [ ! -d "deps/libapps/.git" ] && [ ! -f "deps/libapps/.git" ]; then
        git submodule update --init --recursive
    fi
    cd "$SCRIPT_DIR"
}

build_ish() {
    local BUILD_DIR="$ISH_DIR/build-ios"
    mkdir -p "$BUILD_DIR"

    local IOS_SDK
    IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"

    local CROSS_FILE="$BUILD_DIR/ios-cross.txt"
    cat > "$CROSS_FILE" <<EOF
[binaries]
c = ['clang', '-arch', 'arm64', '-isysroot', '$IOS_SDK', '-miphoneos-version-min=$IOS_DEPLOYMENT_TARGET']
ar = 'ar'
strip = 'strip'
pkg-config = 'false'

[host_machine]
system = 'darwin'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'

[built-in options]
c_args = []
c_link_args = ['-L$IOS_SDK/usr/lib']

[properties]
needs_exe_wrapper = true
sys_root = '$IOS_SDK'
library_dirs = ['$IOS_SDK/usr/lib']
EOF

    local MESON_BUILDTYPE="release"
    [ "$BUILD_TYPE" == "debug" ] && MESON_BUILDTYPE="debug"

    cd "$ISH_DIR"
    if [ ! -f "$BUILD_DIR/build.ninja" ]; then
        log_info "Configuring meson..."
        meson setup "$BUILD_DIR" \
            --cross-file "$CROSS_FILE" \
            --buildtype="$MESON_BUILDTYPE" \
            -Dlog="" \
            -Dlog_handler=nslog \
            -Dkernel=ish \
            -Dengine=asbestos \
            -Dguest_arch=arm64
    else
        meson configure "$BUILD_DIR" --buildtype="$MESON_BUILDTYPE"
    fi

    log_info "Building libraries..."
    ninja -C "$BUILD_DIR" libish.a libish_emu.a libfakefs.a
    ninja -C "$BUILD_DIR" vdso/arm64/libvdso.so.elf || log_info "VDSO build skipped (may need LLVM)"
    cd "$SCRIPT_DIR"
}

copy_outputs() {
    log_info "Copying outputs..."
    local BUILD_DIR="$ISH_DIR/build-ios"
    mkdir -p "$OUTPUT_LIBS" "$OUTPUT_INCLUDE/ish" "$OUTPUT_RESOURCES"

    cp "$BUILD_DIR/libish.a" "$OUTPUT_LIBS/"
    cp "$BUILD_DIR/libish_emu.a" "$OUTPUT_LIBS/"
    cp "$BUILD_DIR/libfakefs.a" "$OUTPUT_LIBS/"

    if [ -f "$BUILD_DIR/vdso/arm64/libvdso.so.elf" ]; then
        cp "$BUILD_DIR/vdso/arm64/libvdso.so.elf" "$OUTPUT_RESOURCES/"
    elif [ -f "$BUILD_DIR/vdso/libvdso.so.elf" ]; then
        cp "$BUILD_DIR/vdso/libvdso.so.elf" "$OUTPUT_RESOURCES/"
    fi

    # Headers: keep minimal set needed for integration
    cp "$ISH_DIR/debug.h" "$ISH_DIR/misc.h" "$ISH_DIR/xX_main_Xx.h" "$OUTPUT_INCLUDE/ish/" 2>/dev/null || true
    cp "$ISH_DIR"/*.h "$OUTPUT_INCLUDE/ish/" 2>/dev/null || true
    cp "$ISH_DIR/kernel"/*.h "$OUTPUT_INCLUDE/ish/" 2>/dev/null || true
    cp "$ISH_DIR/fs"/*.h "$OUTPUT_INCLUDE/ish/" 2>/dev/null || true
    cp "$ISH_DIR/util"/*.h "$OUTPUT_INCLUDE/ish/" 2>/dev/null || true
    cp "$ISH_DIR/platform"/*.h "$OUTPUT_INCLUDE/ish/" 2>/dev/null || true
    cp "$ISH_DIR/emu"/*.h "$OUTPUT_INCLUDE/ish/" 2>/dev/null || true
    cp "$ISH_DIR/asbestos"/*.h "$OUTPUT_INCLUDE/ish/" 2>/dev/null || true

    if [ -f "$BUILD_DIR/cpu-offsets.h" ]; then
        cp "$BUILD_DIR/cpu-offsets.h" "$OUTPUT_INCLUDE/ish/"
    fi

    log_info "Libraries: $OUTPUT_LIBS"
    ls -lh "$OUTPUT_LIBS"/*.a
}

create_umbrella_header() {
    cat > "$OUTPUT_INCLUDE/ish/ish.h" <<'EOF'
#ifndef ISH_H
#define ISH_H

#include "misc.h"
#include "debug.h"

#include "kernel/init.h"
#include "kernel/task.h"
#include "kernel/calls.h"
#include "kernel/fs.h"
#include "kernel/memory.h"
#include "kernel/signal.h"
#include "kernel/errno.h"

#include "fs/fd.h"
#include "fs/stat.h"
#include "fs/tty.h"
#include "fs/fake.h"
#include "fs/real.h"
#include "fs/poll.h"
#include "fs/dev.h"

#include "emu/cpu.h"
#include "emu/tlb.h"
#include "emu/mmu.h"

#include "platform/platform.h"

#endif
EOF
}

main() {
    check_prerequisites
    clone_ish
    init_submodules
    build_ish
    copy_outputs
    create_umbrella_header
    log_info "Done."
}

main "$@"
