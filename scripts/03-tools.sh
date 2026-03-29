#!/usr/bin/env bash
# =============================================================================
#  03-tools.sh — Instala ferramentas: tmux, vim, zsh, ROS2, YCM, Copilot, etc.
#  Chamado pelo install.sh principal
# =============================================================================

set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGS_DIR="$SETUP_DIR/configs"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; NC='\033[0m'

log()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[ERRO]${NC} $*" >&2; exit 1; }

[[ "$EUID" -eq 0 ]] && die "Nao rode como root."

sudo apt update && sudo apt upgrade -y

# =============================================================================
# TMUX
# =============================================================================
log "Instalando tmux..."
sudo apt install -y tmux

# =============================================================================
# RANGER
# =============================================================================
log "Instalando ranger..."
sudo apt install -y ranger

# =============================================================================
# VIM 9.1+ (necessario para YCM e Copilot) — compilado do fonte
# =============================================================================
log "Instalando dependencias para compilar Vim 9.1+..."
sudo apt install -y   libncurses-dev libgtk2.0-dev libatk1.0-dev   libcairo2-dev libx11-dev libxpm-dev libxt-dev   ruby-dev lua5.2 liblua5.2-dev libperl-dev

# Instala Python 3.12 pra YCM (sem mudar o python3 do sistema)
log "Instalando Python 3.12..."
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.12 python3.12-dev python3.12-venv

# Compila Vim 9.2 do fonte com suporte a Python 3.12
log "Compilando Vim 9.2 do fonte..."
cd /tmp
rm -rf vim
git clone --depth=1 https://github.com/vim/vim.git
cd vim
./configure --with-features=huge   --enable-multibyte   --enable-python3interp=yes   --with-python3-command=python3.12   --enable-gtk2-interp=yes   --enable-cscope   --prefix=/usr/local
make -j$(nproc)
sudo make install

# Garante que o vim compilado é o padrao
sudo update-alternatives --install /usr/bin/vim vim /usr/local/bin/vim 100
sudo update-alternatives --set vim /usr/local/bin/vim

cd "$HOME"
log "Vim $(vim --version | head -1) instalado com sucesso"

# =============================================================================
# HTOP
# =============================================================================
log "Instalando htop..."
sudo apt install -y htop

# =============================================================================
# FONTS POWERLINE
# =============================================================================
log "Instalando fonts-powerline..."
sudo apt install -y fonts-powerline

# =============================================================================
# ZSH + OH MY ZSH
# =============================================================================
log "Instalando zsh..."
sudo apt install -y zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Instalando Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  warn "Oh My Zsh já instalado, pulando..."
fi

log "Definindo zsh como shell padrão..."
chsh -s /usr/bin/zsh

# Plugins: zsh-autosuggestions e zsh-syntax-highlighting
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# =============================================================================
# LATEX + PDF
# =============================================================================
log "Instalando LaTeX e suporte a PDF..."
sudo apt install -y \
  texlive \
  texlive-latex-extra \
  texlive-fonts-recommended \
  texlive-lang-portuguese \
  latexmk \
  poppler-utils \
  pdf2svg \
  evince

# =============================================================================
# PDFPC
# =============================================================================
log "Instalando pdfpc..."
sudo apt install -y pdfpc

# =============================================================================
# MULTIMEDIA
# =============================================================================
log "Instalando suporte a multimídia..."
sudo apt install -y \
  vlc \
  ffmpeg \
  mpv \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-libav \
  ubuntu-restricted-extras

# =============================================================================
# ZATHURA (leitor de PDF com vim keybindings)
# =============================================================================
log "Instalando zathura..."
sudo apt install -y zathura zathura-pdf-poppler

# =============================================================================
# VIMIV (visualizador de imagens com vim keybindings)
# =============================================================================
log "Instalando vimiv..."
sudo apt install -y vimiv || {
  warn "vimiv não disponível via apt, tentando via pip..."
  pip3 install vimiv 2>/dev/null || warn "vimiv não instalado. Instale manualmente: https://karlch.github.io/vimiv-qt/"
}

# =============================================================================
# SILVER SEARCHER (ag)
# =============================================================================
log "Instalando silver searcher (ag)..."
sudo apt install -y silversearcher-ag

# =============================================================================
# FZF (fuzzy finder)
# =============================================================================
log "Instalando fzf..."
sudo apt install -y fzf

# TMUXINATOR
# =============================================================================
log "Instalando tmuxinator..."
sudo apt install -y ruby ruby-dev
sudo gem install tmuxinator

# =============================================================================
# ANGRY IP SCANNER
# =============================================================================
log "Instalando Angry IP Scanner..."
sudo apt install -y default-jre

IPSCAN_VERSION=$(curl -s https://api.github.com/repos/angryip/ipscan/releases/latest \
  | grep '"tag_name"' | awk -F'"' '{print $4}')

IPSCAN_DEB="/tmp/ipscan_${IPSCAN_VERSION}_amd64.deb"
curl -L -o "$IPSCAN_DEB" \
  "https://github.com/angryip/ipscan/releases/download/${IPSCAN_VERSION}/ipscan_${IPSCAN_VERSION}_amd64.deb"
sudo apt install -y "$IPSCAN_DEB"
rm -f "$IPSCAN_DEB"

# =============================================================================
# ROS 2 HUMBLE
# =============================================================================
log "Instalando ROS 2 Humble..."

# Locale
sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# Repositório
sudo apt install -y software-properties-common
sudo add-apt-repository universe -y
sudo apt update && sudo apt install -y curl

export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
  | grep -F "tag_name" | awk -F'"' '{print $4}')

curl -L -o /tmp/ros2-apt-source.deb \
  "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
sudo apt install -y /tmp/ros2-apt-source.deb

sudo apt update
sudo apt upgrade -y

# Instala ROS 2 desktop (inclui RViz, demos, etc.)
sudo apt install -y ros-humble-desktop

# Ferramentas de dev
sudo apt install -y python3-colcon-common-extensions ros-dev-tools

# Inicializa rosdep
sudo rosdep init 2>/dev/null || warn "rosdep já inicializado"
rosdep update

# Source automático no .zshrc e .bashrc

# Source do ROS no .bashrc
if ! grep -q "ros/humble" "$HOME/.bashrc"; then
  echo "source /opt/ros/humble/setup.bash" >> "$HOME/.bashrc"
fi

# =============================================================================
# NODE.JS 20 — necessario para Copilot
# =============================================================================
log "Instalando Node.js 20..."
sudo apt remove -y nodejs nodejs-doc libnode-dev 2>/dev/null || true
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
ok "Node.js $(node --version) instalado."

# =============================================================================
# VIM-PLUG + PLUGINS (inclui YCM e Copilot)
# =============================================================================
log "Instalando vim-plug e plugins..."
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if [[ -f "$CONFIGS_DIR/vim/vimrc" ]]; then
  cp "$CONFIGS_DIR/vim/vimrc" "$HOME/.vimrc"
  ok "vimrc copiado."
fi

mkdir -p "$HOME/.vim"
if [[ -f "$CONFIGS_DIR/vim/ycm_extra_conf.py" ]]; then
  cp "$CONFIGS_DIR/vim/ycm_extra_conf.py" "$HOME/.vim/.ycm_extra_conf.py"
fi

vim +PlugInstall +qall 2>/dev/null || true
ok "Plugins vim instalados."

# =============================================================================
# YOUCOMPLETEME — compila com python3.12 e clangd
# =============================================================================
log "Instalando dependencias do YCM..."
sudo apt install -y build-essential cmake clangd clang libclang-dev

log "Compilando YouCompleteMe com python3.12 e clangd..."
if [ -d "$HOME/.vim/plugged/YouCompleteMe" ]; then
  cd "$HOME/.vim/plugged/YouCompleteMe"
  python3.12 install.py --clangd-completer
  cd "$HOME"
  ok "YCM compilado com sucesso."
else
  warn "YCM nao encontrado. Abre o vim, rode :PlugInstall e depois:"
  warn "  cd ~/.vim/plugged/YouCompleteMe && python3.12 install.py --clangd-completer"
fi

# Suprime avisos de unused-includes do clangd
cat > "$HOME/.clangd" << 'CLANGD_EOF'
Diagnostics:
  UnusedIncludes: None
CLANGD_EOF
ok "clangd configurado."

# =============================================================================
# GITHUB COPILOT
# =============================================================================
ok "Copilot instalado via vim-plug com Node.js $(node --version)."
ok "Para autenticar: abra o vim e rode :Copilot setup"
