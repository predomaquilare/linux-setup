#!/usr/bin/env bash
# =============================================================================
#  05-wallpaper.sh — Configura wallpaper via swaybg
#  Chamado pelo install.sh principal
# =============================================================================

set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WALLPAPERS_DIR="$SETUP_DIR/wallpapers"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC}   $1"; }

[[ "$EUID" -eq 0 ]] && { echo "Nao rode como root."; exit 1; }

# =============================================================================
# Instala swaybg
# =============================================================================
info "Instalando swaybg..."
sudo apt install -y swaybg
ok "swaybg instalado."

# =============================================================================
# Escolhe wallpaper
# =============================================================================
mkdir -p "$HOME/Pictures/wallpapers"

# Lista wallpapers disponíveis na pasta
AVAILABLE=()
while IFS= read -r -d $'\0' f; do
  AVAILABLE+=("$f")
done < <(find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0 2>/dev/null)

WALL_DST="$HOME/Pictures/wallpapers/current.jpg"

if [[ ${#AVAILABLE[@]} -gt 0 ]]; then
  info "Wallpapers disponíveis em $WALLPAPERS_DIR:"
  for i in "${!AVAILABLE[@]}"; do
    echo "  $((i+1))) $(basename "${AVAILABLE[$i]}")"
  done
  echo "  $((${#AVAILABLE[@]}+1))) Usar imagem existente em ~/Pictures/"
  echo ""
  read -rp "  Escolha [1-$((${#AVAILABLE[@]}+1))]: " choice

  if [[ "$choice" -ge 1 && "$choice" -le "${#AVAILABLE[@]}" ]]; then
    SELECTED="${AVAILABLE[$((choice-1))]}"
    cp "$SELECTED" "$WALL_DST"
    info "Wallpaper selecionado: $(basename "$SELECTED")"
  else
    # Tenta encontrar no Downloads
    FOUND=$(find "$HOME/Downloads" "$HOME/Pictures" -maxdepth 2 \
      \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | head -1)
    if [[ -n "$FOUND" ]]; then
      cp "$FOUND" "$WALL_DST"
      info "Usando: $FOUND"
    else
      warn "Nenhuma imagem encontrada. Coloque uma em $WALLPAPERS_DIR/ e rode novamente."
      exit 0
    fi
  fi
else
  # Sem wallpapers na pasta — tenta Downloads
  FOUND=$(find "$HOME/Downloads" "$HOME/Pictures" -maxdepth 2 \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | head -1)
  if [[ -n "$FOUND" ]]; then
    cp "$FOUND" "$WALL_DST"
    info "Wallpaper encontrado: $FOUND"
  else
    warn "Coloque uma imagem .jpg/.png em $WALLPAPERS_DIR/ e rode novamente."
    exit 0
  fi
fi

# =============================================================================
# Configura hyprland.conf para usar swaybg
# =============================================================================
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [[ -f "$HYPR_CONF" ]]; then
  sed -i '/exec-once = hyprpaper/d'   "$HYPR_CONF"
  sed -i '/exec-once = swaybg/d'      "$HYPR_CONF"
  echo "exec-once = swaybg -i $WALL_DST -m fill" >> "$HYPR_CONF"
  ok "swaybg adicionado ao autostart do Hyprland."
fi

# =============================================================================
# Aplica imediatamente se Hyprland estiver rodando
# =============================================================================
if command -v swaybg &>/dev/null; then
  pkill swaybg 2>/dev/null || true
  sleep 0.3
  swaybg -i "$WALL_DST" -m fill &
  disown
  ok "Wallpaper aplicado: $WALL_DST"
fi

echo ""
ok "Wallpaper configurado em: $WALL_DST"
warn "Para trocar: edite exec-once do swaybg em ~/.config/hypr/hyprland.conf"
warn "Ou adicione wallpapers em $WALLPAPERS_DIR/ e rode: ./install.sh --wallpaper"
