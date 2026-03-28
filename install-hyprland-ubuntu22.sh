#!/usr/bin/env bash
# =============================================================================
#  install-hyprland-ubuntu22.sh — Hyprland + Waybar + Utilitarios no Ubuntu 22.04
#
#  Testado e construido na pratica. Resolve ~25 dependencias incompativeis.
#
#  USO:
#    chmod +x install-hyprland-ubuntu22.sh
#    ./install-hyprland-ubuntu22.sh
#
#  AVISOS:
#    - NAO rode como root.
#    - Leva 60-120 min dependendo da maquina.
#    - Apos instalar, REINICIE e selecione Hyprland no GDM (engrenagem).
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[ERRO]${NC} $*" >&2; exit 1; }

[[ "$EUID" -eq 0 ]] && die "Nao rode como root."

. /etc/os-release
if [[ "$VERSION_ID" != "22.04" ]]; then
  warn "Este script foi feito para Ubuntu 22.04. Voce esta em: $PRETTY_NAME"
  read -rp "Continuar mesmo assim? [s/N] " resp
  [[ "${resp,,}" == "s" ]] || exit 0
fi

SRC_DIR="$HOME/HyprSource"
mkdir -p "$SRC_DIR"
log "Diretorio de fontes: $SRC_DIR"

CC_BIN="/usr/bin/clang-19"
CXX_BIN="/usr/bin/clang++-19"
CXX_STD="23"
CXX_FLAGS="-stdlib=libc++"
LD_FLAGS="-stdlib=libc++ -lc++abi"

export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64:${LD_LIBRARY_PATH:-}"

clone_or_update() {
  local url="$1" dir="$2"
  if [[ -d "$dir/.git" ]]; then
    log "Atualizando $(basename "$dir")..."
    git -C "$dir" fetch --all --tags 2>/dev/null || true
    git -C "$dir" pull --ff-only 2>/dev/null || true
  else
    log "Clonando $(basename "$dir")..."
    git clone --depth=1 "$url" "$dir"
  fi
}

cmake_build_install() {
  local src="$1"; shift
  local build_dir="$src/build"
  rm -rf "$build_dir"
  log "Compilando $(basename "$src")..."
  cmake -B "$build_dir" -S "$src" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER="$CC_BIN" \
        -DCMAKE_CXX_COMPILER="$CXX_BIN" \
        -DCMAKE_CXX_STANDARD="$CXX_STD" \
        -DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
        -DCMAKE_EXE_LINKER_FLAGS="$LD_FLAGS" \
        -DCMAKE_SHARED_LINKER_FLAGS="$LD_FLAGS" \
        -DCMAKE_PREFIX_PATH=/usr/local \
        "$@"
  cmake --build "$build_dir" -j"$(nproc)"
  sudo cmake --install "$build_dir"
  sudo ldconfig
  ok "$(basename "$src") instalado."
}

meson_build_install() {
  local src="$1"; shift
  local build_dir="$src/build"
  rm -rf "$build_dir"
  log "Compilando $(basename "$src") com meson..."
  meson setup --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
    "$build_dir" "$src" "$@"
  ninja -C "$build_dir" -j"$(nproc)"
  sudo meson install --no-rebuild -C "$build_dir"
  sudo ldconfig
  ok "$(basename "$src") instalado."
}

# =============================================================================
# PASSO 1 — Clang 19
# =============================================================================
log "━━━ Passo 1: Clang 19 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v clang-19 &>/dev/null; then
  ok "Clang 19 ja instalado: $(clang-19 --version | head -1)"
else
  sudo apt-get install -y wget gnupg lsb-release software-properties-common
  wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key \
    | sudo gpg --dearmor -o /usr/share/keyrings/llvm-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] \
https://apt.llvm.org/jammy/ llvm-toolchain-jammy-19 main" \
    | sudo tee /etc/apt/sources.list.d/llvm-19.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y clang-19 clang++-19 libc++-19-dev libc++abi-19-dev lld-19
  sudo update-alternatives \
    --install /usr/bin/clang clang /usr/bin/clang-19 190 \
    --slave /usr/bin/clang++ clang++ /usr/bin/clang++-19
  ok "Clang 19 instalado."
fi

# =============================================================================
# PASSO 2 — Dependencias via apt
# =============================================================================
log "━━━ Passo 2: Dependencias via apt ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo apt-get update -qq
sudo apt-get install -y \
  build-essential git cmake ninja-build pkg-config \
  python3 python3-pip \
  libwayland-dev wayland-protocols libwayland-bin \
  libxkbcommon-dev libxkbcommon-x11-dev libxkbregistry-dev \
  libdrm-dev libgbm-dev \
  libegl-dev libgles2-mesa-dev \
  libvulkan-dev libvulkan1 mesa-vulkan-drivers vulkan-tools \
  libinput-dev libudev-dev libseat-dev seatd \
  libxcb1-dev libxcb-util0-dev libxcb-composite0-dev \
  libxcb-render0-dev libxcb-shape0-dev libxcb-icccm4-dev \
  libxcb-keysyms1-dev libxcb-randr0-dev libxcb-xfixes0-dev \
  libxcb-present-dev libxcb-dri3-dev libxcb-ewmh-dev \
  libxcb-xinput-dev libxcb-res0-dev \
  libx11-dev libx11-xcb-dev libxcomposite-dev libxrender-dev \
  libxfixes-dev libxcursor-dev xwayland \
  libcairo2-dev libpango1.0-dev libpangocairo-1.0-0 \
  libglib2.0-dev libffi-dev libxml2-dev \
  libavcodec-dev libavformat-dev libavutil-dev libswscale-dev \
  libglvnd-dev \
  glslang-tools spirv-tools \
  xdg-desktop-portal-gtk \
  libgdk-pixbuf2.0-dev libmagic-dev \
  libjpeg-dev libpng-dev libwebp-dev libzip-dev librsvg2-dev \
  hwdata \
  libmtdev-dev libevdev-dev libwacom-dev check \
  xcb-proto xutils-dev libtool \
  libpciaccess-dev \
  libfontconfig1-dev libfreetype-dev \
  liblcms2-dev \
  bison scdoc \
  brightnessctl \
  libgtk-3-dev libgtkmm-3.0-dev \
  libgirepository1.0-dev \
  libjack-dev libpipewire-0.3-dev \
  libpulse-dev libupower-glib-dev \
  libdbusmenu-gtk3-dev libmpdclient-dev \
  libnl-3-dev libnl-genl-3-dev \
  python3-jinja2 mm-common \
  libselinux1-dev libmount-dev \
  vim curl wget jq cpio zip unzip
ok "Dependencias apt instaladas."

# =============================================================================
# PASSO 3 — Meson novo via pip
# =============================================================================
log "━━━ Passo 3: Meson atualizado ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo pip3 install meson --upgrade --quiet
ok "Meson: $(meson --version)"

# =============================================================================
# PASSO 4 — Header dma-buf.h uapi
# =============================================================================
log "━━━ Passo 4: Header dma-buf.h uapi ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo mkdir -p /usr/local/include/linux
sudo tee /usr/local/include/linux/dma-buf.h > /dev/null << 'HDREOF'
#ifndef _UAPI_DMA_BUF_H_
#define _UAPI_DMA_BUF_H_
#include <linux/types.h>
#ifndef DMA_BUF_BASE
#define DMA_BUF_BASE 'b'
#endif
#ifndef DMA_BUF_IOCTL_SYNC
struct dma_buf_sync { __u64 flags; };
#define DMA_BUF_SYNC_READ  (1 << 0)
#define DMA_BUF_SYNC_WRITE (2 << 0)
#define DMA_BUF_SYNC_RW    (DMA_BUF_SYNC_READ | DMA_BUF_SYNC_WRITE)
#define DMA_BUF_SYNC_START (0 << 2)
#define DMA_BUF_SYNC_END   (1 << 2)
#define DMA_BUF_IOCTL_SYNC _IOW(DMA_BUF_BASE, 0, struct dma_buf_sync)
#endif
#ifndef DMA_BUF_IOCTL_EXPORT_SYNC_FILE
struct dma_buf_export_sync_file { __u32 flags; __s32 fd; };
struct dma_buf_import_sync_file { __u32 flags; __s32 fd; };
#define DMA_BUF_IOCTL_EXPORT_SYNC_FILE _IOWR(DMA_BUF_BASE, 2, struct dma_buf_export_sync_file)
#define DMA_BUF_IOCTL_IMPORT_SYNC_FILE _IOW(DMA_BUF_BASE,  3, struct dma_buf_import_sync_file)
#endif
#endif
HDREOF
ok "Header dma-buf.h uapi criado."

# =============================================================================
# PASSO 5 — Dependencias compiladas do fonte
# =============================================================================
log "━━━ Passo 5: Dependencias do fonte ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# pixman
clone_or_update https://gitlab.freedesktop.org/pixman/pixman.git "$SRC_DIR/pixman"
PIXMAN_BUILD="$SRC_DIR/pixman/build"; rm -rf "$PIXMAN_BUILD"
meson setup --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  -Dgtk=disabled -Dtests=disabled -Ddemos=disabled "$PIXMAN_BUILD" "$SRC_DIR/pixman"
ninja -C "$PIXMAN_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$PIXMAN_BUILD"; sudo ldconfig
ok "pixman $(pkg-config --modversion pixman-1 2>/dev/null) instalado."

# libdisplay-info
clone_or_update https://gitlab.freedesktop.org/emersion/libdisplay-info.git "$SRC_DIR/libdisplay-info"
meson_build_install "$SRC_DIR/libdisplay-info"

# tomlplusplus
clone_or_update https://github.com/marzer/tomlplusplus.git "$SRC_DIR/tomlplusplus"
TOML_BUILD="$SRC_DIR/tomlplusplus/build"; rm -rf "$TOML_BUILD"
CC="$CC_BIN" CXX="$CXX_BIN" CXXFLAGS="$CXX_FLAGS" LDFLAGS="$LD_FLAGS" \
meson setup --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  -Dbuild_tests=false -Dbuild_examples=false -Dcompile_library=true \
  "$TOML_BUILD" "$SRC_DIR/tomlplusplus"
ninja -C "$TOML_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$TOML_BUILD"; sudo ldconfig
ok "tomlplusplus instalado."

# pugixml
clone_or_update https://github.com/zeux/pugixml.git "$SRC_DIR/pugixml"
cmake_build_install "$SRC_DIR/pugixml" -DPUGIXML_BUILD_TESTS=OFF

# libdrm
clone_or_update https://gitlab.freedesktop.org/mesa/drm.git "$SRC_DIR/drm"
DRM_BUILD="$SRC_DIR/drm/build"; rm -rf "$DRM_BUILD"
meson setup --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  -Dtests=false -Dman-pages=disabled "$DRM_BUILD" "$SRC_DIR/drm"
ninja -C "$DRM_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$DRM_BUILD"; sudo ldconfig
ok "libdrm $(pkg-config --modversion libdrm 2>/dev/null) instalado."

# wayland
clone_or_update https://gitlab.freedesktop.org/wayland/wayland.git "$SRC_DIR/wayland"
git -C "$SRC_DIR/wayland" fetch --tags
WL_TAG=$(git -C "$SRC_DIR/wayland" tag | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
git -C "$SRC_DIR/wayland" checkout "$WL_TAG" 2>/dev/null || true
WL_BUILD="$SRC_DIR/wayland/build"; rm -rf "$WL_BUILD"
meson setup --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  -Ddocumentation=false -Dtests=false "$WL_BUILD" "$SRC_DIR/wayland"
ninja -C "$WL_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$WL_BUILD"; sudo ldconfig
ok "wayland $(pkg-config --modversion wayland-client 2>/dev/null) instalado."

# wayland-protocols
clone_or_update https://gitlab.freedesktop.org/wayland/wayland-protocols.git "$SRC_DIR/wayland-protocols"
git -C "$SRC_DIR/wayland-protocols" fetch --tags
WP_TAG=$(git -C "$SRC_DIR/wayland-protocols" tag | grep -E '^[0-9]+\.[0-9]+$' | sort -V | tail -1)
git -C "$SRC_DIR/wayland-protocols" checkout "$WP_TAG" 2>/dev/null || true
WP_BUILD="$SRC_DIR/wayland-protocols/build"; rm -rf "$WP_BUILD"
meson setup --buildtype=release --prefix=/usr/local -Dtests=false "$WP_BUILD" "$SRC_DIR/wayland-protocols"
ninja -C "$WP_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$WP_BUILD"; sudo ldconfig
ok "wayland-protocols $(pkg-config --modversion wayland-protocols 2>/dev/null) instalado."

# seatd
clone_or_update https://git.sr.ht/~kennylevinsen/seatd "$SRC_DIR/seatd"
SEATD_BUILD="$SRC_DIR/seatd/build"; rm -rf "$SEATD_BUILD"
meson setup --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  -Dserver=disabled -Dexamples=disabled -Dman-pages=disabled "$SEATD_BUILD" "$SRC_DIR/seatd"
ninja -C "$SEATD_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$SEATD_BUILD"; sudo ldconfig
ok "libseat $(pkg-config --modversion libseat 2>/dev/null) instalado."

# libinput
clone_or_update https://gitlab.freedesktop.org/libinput/libinput.git "$SRC_DIR/libinput"
git -C "$SRC_DIR/libinput" fetch --tags
LIBINPUT_TAG=$(git -C "$SRC_DIR/libinput" tag | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
git -C "$SRC_DIR/libinput" checkout "$LIBINPUT_TAG" 2>/dev/null || true
LIBINPUT_BUILD="$SRC_DIR/libinput/build"; rm -rf "$LIBINPUT_BUILD"
meson setup --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  -Ddocumentation=false -Dtests=false -Ddebug-gui=false "$LIBINPUT_BUILD" "$SRC_DIR/libinput"
ninja -C "$LIBINPUT_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$LIBINPUT_BUILD"; sudo ldconfig
ok "libinput $(pkg-config --modversion libinput 2>/dev/null) instalado."

# xcb-errors
clone_or_update https://gitlab.freedesktop.org/xorg/lib/libxcb-errors.git "$SRC_DIR/libxcb-errors"
git -C "$SRC_DIR/libxcb-errors" submodule update --init
XCB_ERR_BUILD="$SRC_DIR/libxcb-errors/build"; rm -rf "$XCB_ERR_BUILD"
cd "$SRC_DIR/libxcb-errors"
if [[ -f meson.build ]]; then
  meson setup --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib "$XCB_ERR_BUILD" .
  ninja -C "$XCB_ERR_BUILD" -j"$(nproc)"
  sudo meson install --no-rebuild -C "$XCB_ERR_BUILD"
else
  ./autogen.sh --prefix=/usr/local && make -j"$(nproc)" && sudo make install
fi
cd -; sudo ldconfig; ok "xcb-errors instalado."

# xkbcommon
clone_or_update https://github.com/xkbcommon/libxkbcommon.git "$SRC_DIR/libxkbcommon"
git -C "$SRC_DIR/libxkbcommon" fetch --tags
XKB_TAG=$(git -C "$SRC_DIR/libxkbcommon" tag | grep -E '^xkbcommon-[0-9]' | sort -V | tail -1)
git -C "$SRC_DIR/libxkbcommon" checkout "$XKB_TAG" 2>/dev/null || true
XKB_BUILD="$SRC_DIR/libxkbcommon/build"; rm -rf "$XKB_BUILD"
meson setup --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  -Denable-docs=false -Denable-wayland=true -Denable-x11=true "$XKB_BUILD" "$SRC_DIR/libxkbcommon"
ninja -C "$XKB_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$XKB_BUILD"; sudo ldconfig
ok "xkbcommon $(pkg-config --modversion xkbcommon 2>/dev/null) instalado."

# cairo
clone_or_update https://gitlab.freedesktop.org/cairo/cairo.git "$SRC_DIR/cairo"
git -C "$SRC_DIR/cairo" fetch --tags
CAIRO_TAG=$(git -C "$SRC_DIR/cairo" tag | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
git -C "$SRC_DIR/cairo" checkout "$CAIRO_TAG" 2>/dev/null || true
CAIRO_BUILD="$SRC_DIR/cairo/build"; rm -rf "$CAIRO_BUILD"
meson setup --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  -Dtests=disabled -Dspectre=disabled "$CAIRO_BUILD" "$SRC_DIR/cairo"
ninja -C "$CAIRO_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$CAIRO_BUILD"; sudo ldconfig
ok "cairo $(pkg-config --modversion cairo 2>/dev/null) instalado."

# muparser
clone_or_update https://github.com/beltoforion/muparser.git "$SRC_DIR/muparser"
cmake_build_install "$SRC_DIR/muparser" -DBUILD_SHARED_LIBS=ON -DENABLE_SAMPLES=OFF -DENABLE_OPENMP=OFF

# abseil-cpp
clone_or_update https://github.com/abseil/abseil-cpp.git "$SRC_DIR/abseil-cpp"
cmake_build_install "$SRC_DIR/abseil-cpp" -DBUILD_SHARED_LIBS=ON -DABSL_BUILD_TESTING=OFF

# re2
clone_or_update https://github.com/google/re2.git "$SRC_DIR/re2"
cmake_build_install "$SRC_DIR/re2" -DBUILD_SHARED_LIBS=ON -DRE2_BUILD_TESTING=OFF

# glslang
clone_or_update https://github.com/KhronosGroup/glslang.git "$SRC_DIR/glslang"
cd "$SRC_DIR/glslang" && python3 update_glslang_sources.py && cd -
GLSLANG_BUILD="$SRC_DIR/glslang/build"; rm -rf "$GLSLANG_BUILD"
cmake -B "$GLSLANG_BUILD" -S "$SRC_DIR/glslang" \
      -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_C_COMPILER="$CC_BIN" -DCMAKE_CXX_COMPILER="$CXX_BIN" \
      -DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
      -DCMAKE_EXE_LINKER_FLAGS="$LD_FLAGS" -DCMAKE_SHARED_LINKER_FLAGS="$LD_FLAGS" \
      -DBUILD_SHARED_LIBS=OFF -DENABLE_GLSLANG_BINARIES=ON \
      -DENABLE_SPVREMAPPER=ON -DENABLE_OPT=ON -DALLOW_EXTERNAL_SPIRV_TOOLS=ON
cmake --build "$GLSLANG_BUILD" -j"$(nproc)"
sudo cmake --install "$GLSLANG_BUILD"; sudo ldconfig
ok "glslang instalado."

# iniparser (exigido pelo hyprtoolkit — compila com cmake)
clone_or_update https://github.com/ndevilla/iniparser.git "$SRC_DIR/iniparser"
INIPARSER_BUILD="$SRC_DIR/iniparser/build"; rm -rf "$INIPARSER_BUILD"
cmake -B "$INIPARSER_BUILD" -S "$SRC_DIR/iniparser"       -DCMAKE_BUILD_TYPE=Release       -DCMAKE_INSTALL_PREFIX=/usr/local       -DCMAKE_C_COMPILER="$CC_BIN"       -DBUILD_SHARED_LIBS=ON
cmake --build "$INIPARSER_BUILD" -j"$(nproc)"
sudo cmake --install "$INIPARSER_BUILD"
# Garante que o pc file existe com o nome correto
if ! pkg-config --exists iniparser 2>/dev/null; then
  sudo tee /usr/local/lib/pkgconfig/iniparser.pc > /dev/null << 'PCEOF'
prefix=/usr/local
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include
Name: iniparser
Description: iniparser library
Version: 4.2.0
Libs: -L${libdir} -liniparser
Cflags: -I${includedir}
PCEOF
fi
sudo ldconfig; ok "iniparser instalado."

ok "Todas as dependencias do fonte instaladas."

# =============================================================================
# PASSO 6 — Libs hypr*
# =============================================================================
log "━━━ Passo 6: Compilando libs hypr* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

clone_or_update https://github.com/hyprwm/hyprutils           "$SRC_DIR/hyprutils"
clone_or_update https://github.com/hyprwm/hyprwayland-scanner "$SRC_DIR/hyprwayland-scanner"
clone_or_update https://github.com/hyprwm/hyprlang            "$SRC_DIR/hyprlang"
clone_or_update https://github.com/hyprwm/hyprcursor          "$SRC_DIR/hyprcursor"
clone_or_update https://github.com/hyprwm/hyprgraphics        "$SRC_DIR/hyprgraphics"
clone_or_update https://github.com/hyprwm/hyprwire            "$SRC_DIR/hyprwire"
clone_or_update https://github.com/hyprwm/hyprtoolkit         "$SRC_DIR/hyprtoolkit"
clone_or_update https://github.com/hyprwm/aquamarine          "$SRC_DIR/aquamarine"
clone_or_update https://github.com/hyprwm/hyprland-protocols  "$SRC_DIR/hyprland-protocols"

cmake_build_install "$SRC_DIR/hyprutils"
cmake_build_install "$SRC_DIR/hyprwayland-scanner"
cmake_build_install "$SRC_DIR/hyprlang"
cmake_build_install "$SRC_DIR/hyprcursor"
cmake_build_install "$SRC_DIR/hyprgraphics"
cmake_build_install "$SRC_DIR/hyprwire"
cmake_build_install "$SRC_DIR/hyprtoolkit"

# aquamarine (protocolos precisam ser regenerados com hyprwayland-scanner)
rm -f "$SRC_DIR/aquamarine/protocols/"*.hpp "$SRC_DIR/aquamarine/protocols/"*.cpp 2>/dev/null || true
AQ_BUILD="$SRC_DIR/aquamarine/build"; rm -rf "$AQ_BUILD"
log "Compilando aquamarine..."
PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:${PKG_CONFIG_PATH}" \
cmake -B "$AQ_BUILD" -S "$SRC_DIR/aquamarine" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER="$CC_BIN" -DCMAKE_CXX_COMPILER="$CXX_BIN" \
      -DCMAKE_CXX_STANDARD="$CXX_STD" \
      -DCMAKE_CXX_FLAGS="${CXX_FLAGS} -include algorithm" \
      -DCMAKE_EXE_LINKER_FLAGS="$LD_FLAGS" -DCMAKE_SHARED_LINKER_FLAGS="$LD_FLAGS" \
      -DCMAKE_PREFIX_PATH=/usr/local \
      -Dhyprwayland-scanner_DIR=/usr/local/lib/cmake/hyprwayland-scanner \
      -DWAYLAND_SCANNER_PKGDATA_DIR=/usr/local/share/wayland
cmake --build "$AQ_BUILD" -j"$(nproc)"
sudo cmake --install "$AQ_BUILD"; sudo ldconfig; ok "aquamarine instalado."

cmake_build_install "$SRC_DIR/hyprland-protocols"
ok "Todas as libs hypr* instaladas."

# =============================================================================
# PASSO 7 — Hyprland
# =============================================================================
log "━━━ Passo 7: Compilando Hyprland ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
clone_or_update https://github.com/hyprwm/Hyprland "$SRC_DIR/Hyprland"
cd "$SRC_DIR/Hyprland"
git submodule update --init --recursive
rm -rf build
cmake -B build -S . \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER="$CC_BIN" -DCMAKE_CXX_COMPILER="$CXX_BIN" \
      -DCMAKE_CXX_STANDARD="$CXX_STD" \
      -DCMAKE_CXX_FLAGS="${CXX_FLAGS} -isystem /usr/local/include" \
      -DCMAKE_C_FLAGS="-isystem /usr/local/include" \
      -DCMAKE_EXE_LINKER_FLAGS="$LD_FLAGS" -DCMAKE_SHARED_LINKER_FLAGS="$LD_FLAGS" \
      -DCMAKE_PREFIX_PATH=/usr/local \
      -G Ninja
ninja -C build -j"$(nproc)"
sudo cmake --install build; sudo ldconfig
ok "Hyprland instalado."

# =============================================================================
# PASSO 8 — Waybar e dependencias
# =============================================================================
log "━━━ Passo 8: Waybar ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# sigc++
clone_or_update https://github.com/libsigcplusplus/libsigcplusplus.git "$SRC_DIR/sigcplusplus"
SIGC_BUILD="$SRC_DIR/sigcplusplus/build"; rm -rf "$SIGC_BUILD"
meson setup "$SIGC_BUILD" "$SRC_DIR/sigcplusplus" \
  --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  --wrap-mode=nodownload -Dbuild-examples=false -Dbuild-documentation=false
ninja -C "$SIGC_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$SIGC_BUILD"; sudo ldconfig; ok "sigc++ instalado."

# glib 2.76
clone_or_update https://github.com/GNOME/glib.git "$SRC_DIR/glib"
git -C "$SRC_DIR/glib" fetch --tags
git -C "$SRC_DIR/glib" checkout 2.76.6 2>/dev/null || true
GLIB_BUILD="$SRC_DIR/glib/build"; rm -rf "$GLIB_BUILD"
meson setup "$GLIB_BUILD" "$SRC_DIR/glib" \
  --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  --wrap-mode=nodownload -Dtests=false -Dgtk_doc=false
ninja -C "$GLIB_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$GLIB_BUILD"; sudo ldconfig
ok "glib $(pkg-config --modversion glib-2.0 2>/dev/null) instalado."

# glibmm 2.76 (com fix de compatibilidade)
clone_or_update https://github.com/GNOME/glibmm.git "$SRC_DIR/glibmm"
git -C "$SRC_DIR/glibmm" fetch --tags
git -C "$SRC_DIR/glibmm" checkout 2.76.0 2>/dev/null || true
CONTENTTYPE_CC="$SRC_DIR/glibmm/gio/giomm/contenttype.cc"
sed -i 's/const std::basic_string<guchar>& data/const std::vector<guchar>\& data/g' "$CONTENTTYPE_CC"
sed -i 's/data\.c_str()/data.data()/g' "$CONTENTTYPE_CC"
grep -q '#include <vector>' "$CONTENTTYPE_CC" || sed -i '1s/^/#include <vector>\n/' "$CONTENTTYPE_CC"
GLIBMM_BUILD="$SRC_DIR/glibmm/build"; rm -rf "$GLIBMM_BUILD"
meson setup "$GLIBMM_BUILD" "$SRC_DIR/glibmm" \
  --buildtype=release --prefix=/usr/local --libdir=/usr/local/lib \
  --wrap-mode=nodownload -Dbuild-examples=false -Dbuild-documentation=false
ninja -C "$GLIBMM_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$GLIBMM_BUILD"; sudo ldconfig
ok "glibmm $(pkg-config --modversion glibmm-2.68 2>/dev/null) instalado."

# Waybar (C++17 com libstdc++ — compativel com GTK3 do sistema)
clone_or_update https://github.com/Alexays/Waybar.git "$SRC_DIR/Waybar"
sudo apt-get remove -y libfmt-dev libjsoncpp-dev 2>/dev/null || true
WAYBAR_BUILD="$SRC_DIR/Waybar/build"; rm -rf "$WAYBAR_BUILD"
CC=clang-19 CXX=clang++-19 \
meson setup "$WAYBAR_BUILD" "$SRC_DIR/Waybar" \
  --prefix=/usr/local --buildtype=release \
  --wrap-mode=forcefallback -Dexperimental=true \
  --force-fallback-for=spdlog,jsoncpp,fmt
ninja -C "$WAYBAR_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$WAYBAR_BUILD"; sudo ldconfig
ok "waybar instalado."

# =============================================================================
# PASSO 9 — Utilitarios extras
# =============================================================================
log "━━━ Passo 9: Utilitarios extras ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# grim
clone_or_update https://gitlab.freedesktop.org/emersion/grim.git "$SRC_DIR/grim"
meson_build_install "$SRC_DIR/grim" -Dman-pages=disabled

# slurp
clone_or_update https://github.com/emersion/slurp.git "$SRC_DIR/slurp"
meson_build_install "$SRC_DIR/slurp" -Dman-pages=disabled

# wl-clipboard
clone_or_update https://github.com/bugaevc/wl-clipboard.git "$SRC_DIR/wl-clipboard"
meson_build_install "$SRC_DIR/wl-clipboard"

# fuzzel
clone_or_update https://codeberg.org/dnkl/fuzzel.git "$SRC_DIR/fuzzel"
FUZZEL_BUILD="$SRC_DIR/fuzzel/build"; rm -rf "$FUZZEL_BUILD"
meson setup "$FUZZEL_BUILD" "$SRC_DIR/fuzzel" --buildtype=release --prefix=/usr/local
ninja -C "$FUZZEL_BUILD" -j"$(nproc)"
sudo meson install --no-rebuild -C "$FUZZEL_BUILD"
ok "fuzzel instalado."

# hyprpaper
clone_or_update https://github.com/hyprwm/hyprpaper.git "$SRC_DIR/hyprpaper"
cmake_build_install "$SRC_DIR/hyprpaper"

# Config do hyprpaper
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
if [[ ! -f "$HYPRPAPER_CONF" ]]; then
  cat > "$HYPRPAPER_CONF" << 'EOF'
# hyprpaper.conf
# preload = /caminho/para/wallpaper.jpg
# wallpaper = ,/caminho/para/wallpaper.jpg
EOF
fi
ok "Utilitarios extras instalados."

# =============================================================================
# PASSO 10 — Pos-instalacao
# =============================================================================
log "━━━ Passo 10: Pos-instalacao ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# .desktop pro GDM
WAYLAND_SESSIONS_DIR="/usr/share/wayland-sessions"
sudo mkdir -p "$WAYLAND_SESSIONS_DIR"
DESKTOP_SRC="$SRC_DIR/Hyprland/example/hyprland.desktop"
if [[ -f "$DESKTOP_SRC" ]]; then
  sudo cp "$DESKTOP_SRC" "$WAYLAND_SESSIONS_DIR/hyprland.desktop"
else
  sudo tee "$WAYLAND_SESSIONS_DIR/hyprland.desktop" > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
fi
ok ".desktop instalado."

# Config customizado
CONFIG_DIR="$HOME/.config/hypr"
mkdir -p "$CONFIG_DIR"
log "Instalando hyprland.conf customizado..."
cat > "$CONFIG_DIR/hyprland.conf" << 'CONFEOF'
# ============================================================
# hyprland.conf - Adaptado das binds do i3
# ============================================================
$mod = ALT
$mod2 = SUPER
$terminal = kitty
$launcher = fuzzel
$fileManager = ranger

monitor=,preferred,auto,1

exec-once = waybar
exec-once = hyprpaper
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = nm-applet --indicator

env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = HYPRLAND_NO_DIRECT_SCANOUT,1
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = NVD_BACKEND,direct
env = __NV_PRIME_RENDER_OFFLOAD,1

general {
  gaps_in = 6
  gaps_out = 0
  border_size = 3
  col.active_border = rgba(005fafff)
  col.inactive_border = rgba(333333ff)
  layout = dwindle
}

decoration {
  rounding = 4
  blur {
    enabled = true
    size = 3
    passes = 1
  }
}

animations {
  enabled = true
  bezier = myBezier, 0.05, 0.9, 0.1, 1.05
  animation = windows, 1, 5, myBezier
  animation = windowsOut, 1, 5, default, popin 80%
  animation = border, 1, 10, default
  animation = fade, 1, 7, default
  animation = workspaces, 1, 4, default
}

dwindle {
  pseudotile = true
  preserve_split = true
  smart_split = false
}

misc {
  force_default_wallpaper = 0
}

input {
  kb_layout = us
  follow_mouse = 0
  touchpad {
    natural_scroll = false
  }
  sensitivity = 0
}

bind = $mod, Return, exec, $terminal
bind = $mod SHIFT, Q, killactive,
bind = $mod, D, exec, $launcher
bind = $mod, F, fullscreen,
bind = $mod SHIFT, Space, togglefloating,
bind = $mod, Space, togglefloating,

bind = $mod, H, movefocus, l
bind = $mod, J, movefocus, d
bind = $mod, K, movefocus, u
bind = $mod, L, movefocus, r
bind = ALT, Tab, movefocus, r

bind = $mod SHIFT, H, movewindow, l
bind = $mod SHIFT, J, movewindow, d
bind = $mod SHIFT, K, movewindow, u
bind = $mod SHIFT, L, movewindow, r

bind = $mod, bracketright, layoutmsg, preselect r
bind = $mod, bracketleft, layoutmsg, preselect d
bind = $mod, E, pseudo,

bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod, 6, workspace, 6
bind = $mod, 7, workspace, 7
bind = $mod, 8, workspace, 8
bind = $mod, 9, workspace, 9
bind = $mod, 0, workspace, 10

bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5
bind = $mod SHIFT, 6, movetoworkspace, 6
bind = $mod SHIFT, 7, movetoworkspace, 7
bind = $mod SHIFT, 8, movetoworkspace, 8
bind = $mod SHIFT, 9, movetoworkspace, 9
bind = $mod SHIFT, 0, movetoworkspace, 10

bind = $mod, N, workspace, e+1
bind = $mod, M, workspace, e-1
bind = $mod, X, movecurrentworkspacetomonitor, r

bind = $mod, F5, exec, pamixer -d 10
bind = $mod, F6, exec, pamixer -i 10
bind = $mod, F7, exec, pamixer -t
bind = $mod, F8, exec, pamixer -s 100
bindel = , XF86AudioRaiseVolume, exec, pamixer -i 5
bindel = , XF86AudioLowerVolume, exec, pamixer -d 5
bindl  = , XF86AudioMute, exec, pamixer -t

bind = $mod, F1, exec, brightnessctl set 10%-
bind = $mod, F2, exec, brightnessctl set +10%
bind = $mod, F3, exec, brightnessctl set 50%
bind = $mod, F4, exec, brightnessctl set 100%
bindel = , XF86MonBrightnessUp, exec, brightnessctl set +10%
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

bind = , Print, exec, grim -g "$(slurp)" - | wl-copy

bind = $mod, R, submap, resize
submap = resize
binde = , H, resizeactive, -20 0
binde = , J, resizeactive, 0 20
binde = , K, resizeactive, 0 -20
binde = , L, resizeactive, 20 0
binde = , left,  resizeactive, -20 0
binde = , right, resizeactive, 20 0
binde = , up,    resizeactive, 0 -20
binde = , down,  resizeactive, 0 20
bind  = , Return, submap, reset
bind  = , Escape, submap, reset
submap = reset

bind = $mod SHIFT, G, submap, gaps
submap = gaps
bind = , plus,  exec, hyprctl keyword general:gaps_in $(($(hyprctl getoption general:gaps_in | awk 'NR==1{print $2}')+5))
bind = , minus, exec, hyprctl keyword general:gaps_in $(($(hyprctl getoption general:gaps_in | awk 'NR==1{print $2}')-5))
bind = , 0,     exec, hyprctl keyword general:gaps_in 0 && hyprctl keyword general:gaps_out 0
bind = , d,     exec, hyprctl keyword general:gaps_in 6 && hyprctl keyword general:gaps_out 0
bind = , Return, submap, reset
bind = , Escape, submap, reset
submap = reset

bind = $mod SHIFT, C, exec, hyprctl reload
bind = $mod SHIFT, X, exit,

bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow
CONFEOF
ok "hyprland.conf instalado em $CONFIG_DIR"

# Grupos e seatd
sudo usermod -aG seat "$USER" 2>/dev/null || true
sudo usermod -aG video "$USER" 2>/dev/null || true
sudo usermod -aG render "$USER" 2>/dev/null || true
sudo systemctl enable seatd 2>/dev/null || true
sudo systemctl start seatd 2>/dev/null || true
ok "seatd ativo e usuario nos grupos seat/video/render."

sudo ldconfig

# =============================================================================
# Resumo
# =============================================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      HYPRLAND + WAYBAR INSTALADOS COM SUCESSO!          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}IMPORTANTE — Para entrar no Hyprland:${NC}"
echo -e "  1. ${CYAN}sudo reboot${NC}"
echo -e "  2. Na tela GDM, clique na ${CYAN}engrenagem ⚙${NC} e selecione ${CYAN}Hyprland${NC}"
echo ""
echo -e "  ${YELLOW}Lembre de configurar o wallpaper:${NC}"
echo -e "  Edite ${CYAN}~/.config/hypr/hyprpaper.conf${NC}"
echo ""
echo -e "  ${YELLOW}Config:${NC} ${CYAN}~/.config/hypr/hyprland.conf${NC}"
echo -e "  ${YELLOW}Wiki:${NC}   ${CYAN}https://wiki.hypr.land${NC}"
echo -e "  ${YELLOW}NVIDIA:${NC} ${CYAN}https://wiki.hypr.land/Nvidia/${NC}"
echo ""
echo -e "  Fontes em: ${CYAN}$SRC_DIR${NC}"
echo ""
