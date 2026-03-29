#!/usr/bin/env bash
# =============================================================================
#  06-lockscreen.sh — Instala hyprlock + menu power Eva-01
#  Wayland-nativo, funciona no Hyprland
#  Alt+Shift+X → menu: Lock | Suspend | Hibernate | Reboot | Shutdown | Cancel
# =============================================================================

set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGS_DIR="$SETUP_DIR/configs"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[ERRO]${NC} $*" >&2; exit 1; }

[[ "$EUID" -eq 0 ]] && die "Nao rode como root."

SRC_DIR="$HOME/HyprSource"
mkdir -p "$SRC_DIR"

CC_BIN="/usr/bin/clang-19"
CXX_BIN="/usr/bin/clang++-19"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH:-}"

clone_or_update() {
  local url="$1" dir="$2"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" pull --ff-only 2>/dev/null || true
  else
    git clone --depth=1 "$url" "$dir"
  fi
}

# =============================================================================
# DEPENDENCIAS
# =============================================================================
log "Instalando dependencias..."
sudo apt install -y \
  libpam-dev libcairo2-dev libpango1.0-dev libpangocairo-1.0-0 \
  libgdk-pixbuf2.0-dev libgles2-mesa-dev libdrm-dev libgbm-dev \
  libxkbcommon-dev libwayland-dev wayland-protocols \
  libhowardhinnant-date-dev libsystemd-dev imagemagick

# =============================================================================
# SDBUS-CPP
# =============================================================================
if ! pkg-config --exists sdbus-c++ 2>/dev/null; then
  log "Compilando sdbus-cpp..."
  clone_or_update https://github.com/Kistler-Group/sdbus-cpp.git "$SRC_DIR/sdbus-cpp"
  cd "$SRC_DIR/sdbus-cpp"
  rm -rf build
  cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="$CC_BIN" \
    -DCMAKE_CXX_COMPILER="$CXX_BIN" \
    -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
    -DCMAKE_SHARED_LINKER_FLAGS="-stdlib=libc++ -lc++abi" \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DSDBUSCPP_BUILD_TESTS=OFF \
    -DSDBUSCPP_BUILD_DOCS=OFF
  cmake --build build -j"$(nproc)"
  sudo cmake --install build
  sudo ldconfig
  ok "sdbus-cpp instalado."
  cd "$HOME"
fi

# =============================================================================
# DATE (Howard Hinnant)
# =============================================================================
if [[ ! -f /usr/local/lib/libdate-tz.so ]]; then
  log "Compilando date/tz..."
  clone_or_update https://github.com/HowardHinnant/date.git "$SRC_DIR/date"
  cd "$SRC_DIR/date"
  rm -rf build
  cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="$CC_BIN" \
    -DCMAKE_CXX_COMPILER="$CXX_BIN" \
    -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
    -DCMAKE_SHARED_LINKER_FLAGS="-stdlib=libc++ -lc++abi" \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_TZ_LIB=ON \
    -DUSE_SYSTEM_TZ_DB=ON \
    -DBUILD_SHARED_LIBS=ON
  cmake --build build -j"$(nproc)"
  sudo cmake --install build
  sudo ldconfig
  ok "date/tz instalado."
  cd "$HOME"
fi

# =============================================================================
# HYPRLOCK
# =============================================================================
if ! command -v hyprlock &>/dev/null; then
  log "Compilando hyprlock..."
  clone_or_update https://github.com/hyprwm/hyprlock.git "$SRC_DIR/hyprlock"
  cd "$SRC_DIR/hyprlock"

  # Fix: mover date-tz para posicao correta no target_link_libraries
  python3 -c "
content = open('CMakeLists.txt').read()
content = content.replace(
    'target_link_libraries(hyprlock\n    date-tz PRIVATE',
    'target_link_libraries(hyprlock\n    PRIVATE date-tz'
)
# Caso ainda nao tenha date-tz, adiciona
if 'date-tz' not in content:
    content = content.replace(
        'target_link_libraries(hyprlock PRIVATE',
        'target_link_libraries(hyprlock PRIVATE date-tz'
    )
    content = content.replace(
        'target_link_libraries(hyprlock\n    PRIVATE',
        'target_link_libraries(hyprlock\n    PRIVATE date-tz'
    )
open('CMakeLists.txt', 'w').write(content)
print('CMakeLists.txt corrigido')
"

  rm -rf build
  cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="$CC_BIN" \
    -DCMAKE_CXX_COMPILER="$CXX_BIN" \
    -DCMAKE_CXX_STANDARD=23 \
    -DCMAKE_CXX_FLAGS="-stdlib=libc++ -I/usr/lib/llvm-19/include/c++/v1" \
    -DCMAKE_EXE_LINKER_FLAGS="-stdlib=libc++ -lc++abi" \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_PREFIX_PATH=/usr/local
  cmake --build build -j"$(nproc)"
  sudo cmake --install build
  sudo ldconfig
  ok "hyprlock $(hyprlock --version 2>/dev/null | head -1) instalado."
  cd "$HOME"
else
  ok "hyprlock ja instalado: $(hyprlock --version 2>/dev/null | head -1)"
fi

# =============================================================================
# CONFIG DO HYPRLOCK — wallpaper da pasta + tema Eva-01
# =============================================================================
log "Configurando hyprlock..."
mkdir -p "$HOME/.config/hypr"

# Descobre o wallpaper atual
WALL_DST="$HOME/Pictures/wallpapers/current.jpeg"
WALL_FALLBACK="$HOME/Pictures/gundam.jpeg"
SETUP_WALL="$SETUP_DIR/wallpapers/current.jpeg"

if [[ -f "$SETUP_WALL" ]]; then
  LOCKWALL="$SETUP_WALL"
elif [[ -f "$WALL_DST" ]]; then
  LOCKWALL="$WALL_DST"
elif [[ -f "$WALL_FALLBACK" ]]; then
  LOCKWALL="$WALL_FALLBACK"
else
  LOCKWALL=""
fi

cat > "$HOME/.config/hypr/hyprlock.conf" << HYPRLOCK_EOF
# hyprlock.conf — Eva-01 x Gundam theme

background {
    monitor =
    path = ${LOCKWALL}
    blur_passes = 3
    blur_size = 7
    brightness = 0.6
}

input-field {
    monitor =
    size = 300, 50
    outline_thickness = 3
    dots_size = 0.33
    dots_spacing = 0.15
    dots_center = true
    outer_color = rgb(875f87)
    inner_color = rgb(0d0d0d)
    font_color = rgb(00af5f)
    fade_on_empty = true
    placeholder_text = <span foreground="##00af5f">󰌾 senha...</span>
    check_color = rgb(00af5f)
    fail_color = rgb(ff3333)
    fail_text = <i>\$FAIL (\$ATTEMPTS)</i>
    capslock_color = rgb(ffaa00)
    position = 0, -100
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:1000] echo "\$(date +'%H:%M')"
    color = rgb(00af5f)
    font_size = 72
    font_family = JetBrainsMonoNL Nerd Font
    position = 0, 200
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:60000] echo "\$(date +'%A, %d %B')"
    color = rgb(875f87)
    font_size = 18
    font_family = JetBrainsMonoNL Nerd Font
    position = 0, 120
    halign = center
    valign = center
}
HYPRLOCK_EOF

ok "hyprlock.conf configurado com wallpaper: ${LOCKWALL:-nenhum}"

# =============================================================================
# POWER MENU
# =============================================================================
log "Criando power-menu.sh..."
mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/power-menu.sh" << 'POWER_EOF'
#!/usr/bin/env bash

LOCK="󰌾  Lock"
LOGOUT="󰍃  Logout"
REBOOT="󰑓  Reboot"
SHUTDOWN="󰐥  Shutdown"

show_menu() {
  printf '%s\n' "$LOCK" "$LOGOUT" "$REBOOT" "$SHUTDOWN"
}

FUZZEL_OPTS=(
  --font="JetBrainsMonoNL Nerd Font:size=14"
  --background=0d0d0dee
  --text-color=00af5fff
  --match-color=af87ffff
  --selection-color=1a0030ff
  --selection-text-color=00af5fff
  --border-color=00af5fff
  --border-width=2
  --border-radius=8
  --width=20
  --lines=4
  --prompt="  Power  "
)

CHOICE=$(show_menu | fuzzel --dmenu "${FUZZEL_OPTS[@]}")

[[ -z "$CHOICE" ]] && exit 0

case "$CHOICE" in
  "$LOCK")     hyprlock ;;
  "$LOGOUT")   hyprctl dispatch exit ;;
  "$REBOOT")   systemctl reboot ;;
  "$SHUTDOWN") systemctl poweroff ;;
esac
POWER_EOF

chmod +x "$HOME/.local/bin/power-menu.sh"
ok "power-menu.sh criado."

# PATH
if ! grep -q ".local/bin" "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

# =============================================================================
# ATUALIZA hyprland.conf
# =============================================================================
update_hypr() {
  local conf="$1"
  sed -i 's|bind = \$mod SHIFT, X, exit,|bind = $mod SHIFT, X, exec, ~/.local/bin/power-menu.sh|' "$conf"
  sed -i 's|bind = \$mod SHIFT, X, exec,.*|bind = $mod SHIFT, X, exec, ~/.local/bin/power-menu.sh|' "$conf"
}

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
CONFIGS_HYPR="$CONFIGS_DIR/hypr/hyprland.conf"

[[ -f "$HYPR_CONF" ]]    && update_hypr "$HYPR_CONF"    && ok "hyprland.conf atualizado."
[[ -f "$CONFIGS_HYPR" ]] && update_hypr "$CONFIGS_HYPR" && ok "configs/hypr/hyprland.conf atualizado."
command -v hyprctl &>/dev/null && hyprctl reload 2>/dev/null && ok "Hyprland recarregado." || true

# =============================================================================
# RESUMO
# =============================================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         hyprlock + Power Menu instalados!                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}Atalho:${NC}   ${CYAN}Alt+Shift+X${NC} → Power menu"
echo -e "  ${YELLOW}Testar:${NC}   ${CYAN}hyprlock${NC}"
echo -e "  ${YELLOW}Config:${NC}   ${CYAN}~/.config/hypr/hyprlock.conf${NC}"
echo ""
