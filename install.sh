#!/usr/bin/env bash
# =============================================================================
#  xarepe-setup — Script Principal
#  Ubuntu 22.04 + Hyprland + Eva-01 Theme
#
#  USO:
#    chmod +x install.sh
#    ./install.sh [opcoes]
#
#  OPCOES:
#    --all           Instala tudo (ordem correta)
#    --hyprland      Apenas Hyprland + dependencias
#    --waybar        Apenas tema Waybar Eva-01
#    --tools         Apenas ferramentas (tmux, vim, zsh, ROS, etc.)
#    --dotfiles      Apenas aplica dotfiles/configs
#    --wallpaper     Apenas configura wallpaper
#    --lockscreen    Apenas instala betterlockscreen + power menu
# =============================================================================

set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SETUP_DIR/scripts"
CONFIGS_DIR="$SETUP_DIR/configs"
WALLPAPERS_DIR="$SETUP_DIR/wallpapers"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()     { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
section() { echo -e "\n${BOLD}${CYAN}━━━ $* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
die()     { echo -e "${RED}[ERRO]${NC} $*" >&2; exit 1; }

[[ "$EUID" -eq 0 ]] && die "Nao rode como root."

# =============================================================================
# Banner
# =============================================================================
print_banner() {
  echo -e "${CYAN}"
  echo "  ██╗  ██╗ █████╗ ██████╗ ████████╗██████╗ ███████╗"
  echo "  ╚██╗██╔╝██╔══██╗██╔══██╗██╔═══██║██╔══██╗██╔════╝"
  echo "   ╚███╔╝ ███████║██████╔╝██║   ██║██████╔╝█████╗  "
  echo "   ██╔██╗ ██╔══██║██╔══██╗██║   ██║██╔═══╝ ██╔══╝  "
  echo "  ██╔╝ ██╗██║  ██║██║  ██║████████║██║     ███████╗"
  echo "  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═══════╝╚═╝     ╚══════╝"
  echo -e "${NC}"
  echo -e "  ${YELLOW}Ubuntu 22.04 + Hyprland + Eva-01 Theme${NC}"
  echo -e "  ${CYAN}Setup by xarepe${NC}"
  echo ""
}

# =============================================================================
# Menu interativo
# =============================================================================
print_menu() {
  echo -e "${BOLD}Selecione o que instalar:${NC}"
  echo ""
  echo "  ${CYAN}1)${NC} Tudo (ordem recomendada)"
  echo "  ${CYAN}2)${NC} Hyprland + Waybar (base do sistema)"
  echo "  ${CYAN}3)${NC} Ferramentas (vim, tmux, zsh, ROS, etc.)"
  echo "  ${CYAN}4)${NC} Dotfiles / Configs"
  echo "  ${CYAN}5)${NC} Wallpaper"
  echo "  ${CYAN}6)${NC} Lockscreen + Power Menu"
  echo "  ${CYAN}7)${NC} Sair"
  echo ""
}

run_step() {
  local name="$1"
  local script="$2"
  section "$name"
  if [[ -f "$script" ]]; then
    bash "$script"
    ok "$name concluido."
  else
    die "Script nao encontrado: $script"
  fi
}

main() {
  print_banner

  # Modo nao-interativo via argumento
  if [[ $# -gt 0 ]]; then
    case "$1" in
      --all)
        run_step "Hyprland"  "$SCRIPTS_DIR/01-hyprland.sh"
        run_step "Waybar"    "$SCRIPTS_DIR/02-waybar.sh"
        run_step "Tools"     "$SCRIPTS_DIR/03-tools.sh"
        run_step "Dotfiles"  "$SCRIPTS_DIR/04-dotfiles.sh"
        run_step "Wallpaper"   "$SCRIPTS_DIR/05-wallpaper.sh"
        run_step "Lockscreen" "$SCRIPTS_DIR/06-lockscreen.sh"
        ;;
      --hyprland) run_step "Hyprland"  "$SCRIPTS_DIR/01-hyprland.sh" ;;
      --waybar)   run_step "Waybar"    "$SCRIPTS_DIR/02-waybar.sh"   ;;
      --tools)    run_step "Tools"     "$SCRIPTS_DIR/03-tools.sh"    ;;
      --dotfiles) run_step "Dotfiles"  "$SCRIPTS_DIR/04-dotfiles.sh" ;;
      --wallpaper)  run_step "Wallpaper"   "$SCRIPTS_DIR/05-wallpaper.sh"  ;;
      --lockscreen) run_step "Lockscreen" "$SCRIPTS_DIR/06-lockscreen.sh";;
      *) die "Opcao desconhecida: $1" ;;
    esac
    print_summary
    return
  fi

  # Modo interativo
  while true; do
    print_menu
    read -rp "  Opcao [1-6]: " choice
    echo ""
    case "$choice" in
      1)
        run_step "Hyprland"  "$SCRIPTS_DIR/01-hyprland.sh"
        run_step "Waybar"    "$SCRIPTS_DIR/02-waybar.sh"
        run_step "Tools"     "$SCRIPTS_DIR/03-tools.sh"
        run_step "Dotfiles"  "$SCRIPTS_DIR/04-dotfiles.sh"
        run_step "Wallpaper" "$SCRIPTS_DIR/05-wallpaper.sh"
        break
        ;;
      2)
        run_step "Hyprland" "$SCRIPTS_DIR/01-hyprland.sh"
        run_step "Waybar"   "$SCRIPTS_DIR/02-waybar.sh"
        break
        ;;
      3) run_step "Tools"     "$SCRIPTS_DIR/03-tools.sh";    break ;;
      4) run_step "Dotfiles"  "$SCRIPTS_DIR/04-dotfiles.sh"; break ;;
      5) run_step "Wallpaper" "$SCRIPTS_DIR/05-wallpaper.sh";break ;;
      6) echo "Saindo."; exit 0 ;;
      *) warn "Opcao invalida. Digite 1-7." ;;
    esac
  done

  print_summary
}

print_summary() {
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║              Setup concluido com sucesso!                ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${YELLOW}Proximos passos:${NC}"
  echo -e "  1. ${CYAN}sudo reboot${NC} — reinicie para entrar no Hyprland"
  echo -e "  2. Na tela GDM, clique na engrenagem e selecione ${CYAN}Hyprland${NC}"
  echo -e "  3. Abra um terminal (${CYAN}Alt+Enter${NC})"
  echo -e "  4. ${CYAN}vim +PlugInstall +qall${NC} — instala plugins do vim"
  echo -e "  5. No vim: ${CYAN}:Copilot setup${NC} — autentica GitHub Copilot"
  echo -e "  6. ${CYAN}cd ~/.vim/plugged/YouCompleteMe${NC}"
  echo -e "     ${CYAN}python3.12 install.py --clangd-completer${NC}"
  echo ""
  echo -e "  ${YELLOW}Configs em:${NC} ${CYAN}$SETUP_DIR/configs/${NC}"
  echo -e "  ${YELLOW}Wallpapers:${NC} ${CYAN}$SETUP_DIR/wallpapers/${NC}"
  echo ""
}

main "$@"
