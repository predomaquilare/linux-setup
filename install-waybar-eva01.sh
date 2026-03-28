#!/usr/bin/env bash
# =============================================================================
#  install-waybar-eva01.sh — Instala tema Eva-01 no Waybar
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; CYAN='\033[0;36m'; NC='\033[0m'

log()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[ERRO]${NC} $*" >&2; exit 1; }

[[ "$EUID" -eq 0 ]] && die "Nao rode como root."

WAYBAR_DIR="$HOME/.config/waybar"

log "Verificando dependencias..."
if ! command -v waybar &>/dev/null; then
  die "Waybar nao encontrado."
fi

if ! command -v playerctl &>/dev/null; then
  log "Instalando playerctl..."
  sudo apt-get install -y playerctl
  ok "playerctl instalado."
else
  ok "playerctl ja instalado."
fi

# Nerd Font
if ! fc-list | grep -qi "JetBrainsMonoNL Nerd Font"; then
  log "Instalando JetBrainsMono Nerd Font..."
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
  wget -q --show-progress -O /tmp/JetBrainsMono.zip \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  unzip -q -o /tmp/JetBrainsMono.zip -d "$HOME/.local/share/fonts/JetBrainsMono"
  rm /tmp/JetBrainsMono.zip
  fc-cache -f
  ok "Fonte instalada."
else
  ok "JetBrainsMonoNL Nerd Font ja instalada."
fi

# Instala o que falta
sudo apt-get install -y \
  pipewire-pulse \
  wireplumber \
  libwireplumber-0.4-0 \
  pipewire-audio-client-libraries

# Inicia tudo
systemctl --user start pipewire-pulse wireplumber
systemctl --user enable pipewire-pulse wireplumber

# Verifica
systemctl --user status pipewire pipewire-pulse wireplumber

# cxxopts (dep do pamixer, header-only)
git clone --depth=1 https://github.com/jarro2783/cxxopts.git ~/HyprSource/cxxopts
cmake -B ~/HyprSource/cxxopts/build -S ~/HyprSource/cxxopts \
	-DCMAKE_INSTALL_PREFIX=/usr/local \
	-DCXXOPTS_BUILD_EXAMPLES=OFF -DCXXOPTS_BUILD_TESTS=OFF
	sudo cmake --install ~/HyprSource/cxxopts/build

# pamixer
git clone --depth=1 https://github.com/cdemoulins/pamixer.git ~/HyprSource/pamixer
meson setup ~/HyprSource/pamixer/build ~/HyprSource/pamixer \
	--buildtype=release --prefix=/usr/local
	ninja -C ~/HyprSource/pamixer/build -j$(nproc)
	sudo meson install --no-rebuild -C ~/HyprSource/pamixer/build

	pamixer --version

# Backup
mkdir -p "$WAYBAR_DIR"
for f in config.jsonc style.css; do
  [[ -f "$WAYBAR_DIR/$f" ]] && cp "$WAYBAR_DIR/$f" "$WAYBAR_DIR/$f.bak.$(date +%Y%m%d_%H%M%S)"
done

# =============================================================================
# config.jsonc
# =============================================================================
log "Instalando config.jsonc..."
cat > "$WAYBAR_DIR/config.jsonc" << 'JSONEOF'
{
  "layer": "top",
  "position": "top",
  "height": 36,
  "spacing": 0,

  "modules-left": [
    "hyprland/workspaces",
    "hyprland/window"
  ],

  "modules-center": [
    "clock"
  ],

  "modules-right": [
    "custom/visualizer",
    "cpu",
    "memory",
    "temperature",
    "backlight",
    "pulseaudio",
    "network",
    "battery",
    "tray"
  ],

  "hyprland/workspaces": {
    "format": "{id}",
    "on-click": "activate",
    "sort-by-number": true
  },

  "hyprland/window": {
    "format": "󰣆  {}",
    "max-length": 40,
    "separate-outputs": true,
    "rewrite": {
      "(.*) — Mozilla Firefox": "󰈹  $1",
      "kitty": "  terminal",
      "(.*) - nvim": "  $1"
    }
  },

  "clock": {
    "format": "{:%H:%M}",
    "tooltip-format": "<big>{:%A, %d %B %Y}</big>",
    "format-alt": "{:%H:%M:%S}",
    "interval": 1
  },

  "cpu": {
    "format": "󰍛  {usage:02}%",
    "tooltip-format": "CPU: {usage}%",
    "interval": 2,
    "states": { "warning": 70, "critical": 90 }
  },

  "memory": {
    "format": "󰘚  {used:0.1f}G",
    "tooltip-format": "Usado: {used:0.1f}G / {total:0.1f}G",
    "interval": 2,
    "states": { "warning": 70, "critical": 90 }
  },

  "temperature": {
    "critical-threshold": 80,
    "format": "󰔏  {temperatureC}°",
    "format-critical": "󰸁  {temperatureC}°"
  },

  "backlight": {
    "format": "{icon}  {percent}%",
    "format-icons": ["󰃞", "󰃟", "󰃠"]
  },

  "pulseaudio": {
    "format": "{icon}  {volume}%",
    "format-muted": "󰝟  mute",
    "format-icons": { "default": ["󰕿", "󰖀", "󰕾"] },
    "on-click": "pamixer -t",
    "on-scroll-up": "pamixer -i 5",
    "on-scroll-down": "pamixer -d 5"
  },

  "network": {
    "format-wifi": "󰤨  {signalStrength}%",
    "format-ethernet": "󰈀  {ipaddr}",
    "format-disconnected": "󰤭  offline",
    "tooltip-format-wifi": "{essid} | {ipaddr}"
  },

  "battery": {
    "states": { "good": 95, "warning": 30, "critical": 15 },
    "format": "{icon}  {capacity}%",
    "format-charging": "󰂄  {capacity}%",
    "format-plugged": "󰚥  {capacity}%",
    "format-icons": ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
  },

  "tray": {
    "icon-size": 14,
    "spacing": 8
  }
}
JSONEOF
ok "config.jsonc instalado."

# =============================================================================
# style.css
# =============================================================================
log "Instalando style.css..."
cat > "$WAYBAR_DIR/style.css" << 'CSSEOF'
/* ============================================================
   Waybar — Eva-01 Theme
   Roxo profundo + Verde AT Field neon
   ============================================================ */

* {
  font-family: "JetBrainsMonoNL Nerd Font", "JetBrains Mono", monospace;
  font-size: 12px;
  border: none;
  border-radius: 0;
  min-height: 0;
  padding: 0;
  margin: 0;
}

window#waybar {
  background: rgba(8, 4, 18, 0.95);
  border-bottom: 1px solid #2a1545;
  color: #c8a8f0;
}

/* ── Workspaces ── */
#workspaces {
  padding: 0 6px;
  background: rgba(10, 5, 22, 0.8);
}

#workspaces button {
  padding: 0 9px;
  color: #4a3060;
  background: transparent;
  border-bottom: 2px solid transparent;
  transition: all 0.15s;
}

#workspaces button:hover {
  background: rgba(74, 45, 122, 0.2);
  color: #9060c0;
  border-bottom: 2px solid #6a3fa8;
}

#workspaces button.active {
  color: #39ff6e;
  background: rgba(57, 255, 110, 0.08);
  border-bottom: 2px solid #39ff6e;
  font-weight: bold;
}

#workspaces button.urgent {
  color: #ff3333;
  border-bottom: 2px solid #ff3333;
}

/* ── Window title ── */
#window {
  color: #5a3a7a;
  padding: 0 12px;
  font-size: 11px;
  font-style: italic;
}

/* ── Relogio central ── */
#clock {
  font-size: 21px;
  font-weight: bold;
  color: #39ff6e;
  letter-spacing: 5px;
  padding: 0 24px;
  background: rgba(5, 2, 12, 0.92);
  border-left: 1px solid #1e0f35;
  border-right: 1px solid #1e0f35;
}

/* ── Visualizador de audio ── */
#custom-visualizer {
  color: #6a3fa8;
  padding: 0 10px;
  font-size: 14px;
  letter-spacing: 1px;
  border-left: 1px solid rgba(42, 21, 69, 0.5);
  min-width: 80px;
}

/* ── Modulos direita ── */
#cpu,
#memory,
#temperature,
#backlight,
#pulseaudio,
#network,
#battery {
  padding: 0 11px;
  color: #c8a8f0;
  border-left: 1px solid rgba(42, 21, 69, 0.5);
}

#cpu          { color: #b890e0; }
#cpu.warning  { color: #ffaa44; }
#cpu.critical { color: #ff4444; }

#memory         { color: #a870d0; }
#memory.warning { color: #ffaa44; }
#memory.critical{ color: #ff4444; }

#temperature          { color: #9858c0; }
#temperature.critical { color: #ff2222; }

#backlight  { color: #c090e8; }
#pulseaudio { color: #b878d8; }
#pulseaudio.muted { color: #3a2550; }

#network              { color: #39ff6e; }
#network.disconnected { color: #3a2550; }

#battery          { color: #39ff6e; }
#battery.warning  { color: #ffaa00; }
#battery.critical { color: #ff3333; }
#battery.charging { color: #39ff6e; }

#tray {
  padding: 0 10px;
  border-left: 1px solid rgba(42, 21, 69, 0.5);
}

tooltip { background: rgba(8, 4, 18, 0.98); border: 1px solid #4a2d7a; border-radius: 4px; padding: 6px 10px; }
tooltip label { color: #c8a8f0; font-size: 12px; }
CSSEOF
ok "style.css instalado."

# =============================================================================
# Reinicia waybar
# =============================================================================
log "Reiniciando waybar..."
pkill waybar 2>/dev/null || true
sleep 0.5
waybar &>/dev/null &
disown

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Tema Eva-01 instalado com sucesso!               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}Visualizador:${NC} anima automaticamente quando detectar musica tocando"
echo -e "  ${YELLOW}Config em:${NC}   ${CYAN}~/.config/waybar/${NC}"
echo ""
