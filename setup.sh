#!/bin/bash
# =============================================================================
# Setup Script - Ubuntu 22.04 (Hyprland)
# Ferramentas: tmux, ranger, vim, htop, zsh+oh-my-zsh, fonts-powerline,
#              latex, pdfpc, multimedia, zathura, vimiv, ag, fzf,
#              tmuxinator, angry-ip-scanner, ROS 2 Humble
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

sudo apt update && sudo apt upgrade -y

# =============================================================================
# TMUX
# =============================================================================
info "Instalando tmux..."
sudo apt install -y tmux

# =============================================================================
# RANGER
# =============================================================================
info "Instalando ranger..."
sudo apt install -y ranger

# =============================================================================
# VIM
# =============================================================================
info "Instalando vim..."
sudo apt install -y vim vim-gtk3

# =============================================================================
# HTOP
# =============================================================================
info "Instalando htop..."
sudo apt install -y htop

# =============================================================================
# FONTS POWERLINE
# =============================================================================
info "Instalando fonts-powerline..."
sudo apt install -y fonts-powerline

# =============================================================================
# ZSH + OH MY ZSH
# =============================================================================
info "Instalando zsh..."
sudo apt install -y zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Instalando Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  warn "Oh My Zsh já instalado, pulando..."
fi

info "Definindo zsh como shell padrão..."
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
info "Instalando LaTeX e suporte a PDF..."
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
info "Instalando pdfpc..."
sudo apt install -y pdfpc

# =============================================================================
# MULTIMEDIA
# =============================================================================
info "Instalando suporte a multimídia..."
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
info "Instalando zathura..."
sudo apt install -y zathura zathura-pdf-poppler

# =============================================================================
# VIMIV (visualizador de imagens com vim keybindings)
# =============================================================================
info "Instalando vimiv..."
sudo apt install -y vimiv || {
  warn "vimiv não disponível via apt, tentando via pip..."
  pip3 install vimiv 2>/dev/null || warn "vimiv não instalado. Instale manualmente: https://karlch.github.io/vimiv-qt/"
}

# =============================================================================
# SILVER SEARCHER (ag)
# =============================================================================
info "Instalando silver searcher (ag)..."
sudo apt install -y silversearcher-ag

# =============================================================================
# FZF (fuzzy finder)
# =============================================================================
info "Instalando fzf..."
sudo apt install -y fzf

# TMUXINATOR
# =============================================================================
info "Instalando tmuxinator..."
sudo apt install -y ruby ruby-dev
sudo gem install tmuxinator

# =============================================================================
# ANGRY IP SCANNER
# =============================================================================
info "Instalando Angry IP Scanner..."
sudo apt install -y default-jre

IPSCAN_VERSION=$(curl -s https://api.github.com/repos/angryip/ipscan/releases/latest \
  | grep '"tag_name"' | awk -F'"' '{print $4}')

IPSCAN_DEB="/tmp/ipscan_${IPSCAN_VERSION}_amd64.deb"
curl -L -o "$IPSCAN_DEB" \
  "https://github.com/angryip/ipscan/releases/download/${IPSCAN_VERSION}/ipscan_${IPSCAN_VERSION}_amd64.deb"
sudo dpkg -i "$IPSCAN_DEB"
rm -f "$IPSCAN_DEB"

# =============================================================================
# ROS 2 HUMBLE
# =============================================================================
info "Instalando ROS 2 Humble..."

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
sudo dpkg -i /tmp/ros2-apt-source.deb

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
# DOTFILES — gera e instala todas as configs
# =============================================================================
info "Gerando dotfiles de configuração..."

# -----------------------------------------------------------------------------
# ~/.tmux.conf
# -----------------------------------------------------------------------------
info "Escrevendo ~/.tmux.conf..."
python3 - << 'PYEOF'
import os
content = r"""# =============================================================================
# ~/.tmux.conf — baseado no linux-setup do LASER-Robotics
# =============================================================================

# Geral
set-option -g assume-paste-time 1
set-option -g destroy-unattached off
set-option -g detach-on-destroy on
set-option -g display-panes-active-colour red
set-option -g display-panes-colour blue
set-option -g display-time 750
set-option -g history-limit 5000
set-option -g mouse off
set-option -g renumber-windows on
set-option -g repeat-time 500
set-option -g status-keys vi
set-option -g aggressive-resize on
set-option -g visual-activity off
set-option -g visual-bell off
set-option -g visual-silence off
set-option -g bell-action none
set-option -g word-separators " -_@"
set-window-option -g allow-rename off
set-window-option -g automatic-rename off
set-window-option -g monitor-activity off
set -sg escape-time 0
set -g default-terminal "screen-256color"

# Vi mode — F2 entra em copy mode (igual ao setup original)
setw -g mode-keys vi
bind -n F2 copy-mode
bind-key -Tcopy-mode-vi 'v'   send -X begin-selection
bind-key -Tcopy-mode-vi 'y'   send -X copy-pipe-and-cancel "xclip -selection clipboard -i"
bind-key -Tcopy-mode-vi 'C-V' send -X rectangle-toggle
unbind p
bind p run-shell "tmux set-buffer \"$(xclip -o)\"; tmux paste-buffer"

# Navegacao entre panes sem prefixo — Alt+setas
bind-key -n M-Left  select-pane -L
bind-key -n M-Right select-pane -R
bind-key -n M-Up    select-pane -U
bind-key -n M-Down  select-pane -D

# Alt+y/u/i/o — igual ao setup original
bind-key -n M-y select-pane -L
bind-key -n M-o select-pane -R
bind-key -n M-i select-pane -U
bind-key -n M-u select-pane -D

# Ctrl+hjkl com integracao vim (vim-tmux-navigator)
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\S+\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
bind-key -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
bind-key -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
bind-key -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"

# Ctrl+p — abre vim com CtrlP se nao estiver no vim
bind-key -n C-p   if-shell "$is_vim" "send-keys C-p"   "send-keys 'vim -c :Startify\r:CtrlP\r'"
bind-key -n C-F12 if-shell "$is_vim" "send-keys C-F12" "send-keys 'vim -c :Startify\r:CtrlP ~/\r'"

# Redimensionar panes (prefixo + Ctrl+hjkl, repetivel)
bind -r C-h resize-pane -L 5
bind -r C-j resize-pane -D 5
bind -r C-k resize-pane -U 5
bind -r C-l resize-pane -R 5

# Splits sem prefixo
# M-9 -> split horizontal (um embaixo do outro), M-0 -> split vertical (lado a lado)
bind -n M-9 split-window -v -c "#{pane_current_path}"
bind -n M-0 split-window -h -c "#{pane_current_path}"

# Janelas sem prefixo
bind -n C-t       new-window -a -c "#{pane_current_path}"
bind -n M-u       next
bind -n M-i       prev
bind -n S-Right   next
bind -n S-Left    prev
bind -n C-S-Left  swap-window -t -1
bind -n C-S-Right swap-window -t +1

# Sincronizar panes — prefixo + s
bind s \
    set synchronize-panes \;\
    display "Sync #{?synchronize-panes,ON,OFF}"

# Reload config — prefixo + r
bind r source-file ~/.tmux.conf

# Prefixo: Ctrl+a (redefinido aqui no final, como no original do LASER)
set-option -g prefix C-a
unbind C-b
bind C-a send-prefix

# =============================================================================
# Status bar — Eva-01 x Gundam
# Paleta: preto #080808(232) | roxo #875f87(96) | verde neon #00af5f(35)
# =============================================================================
set -g status-position bottom
set -g status-justify left
set -g status-interval 2

set -g status-bg colour232         # preto profundo
set -g status-fg colour35          # verde neon

# Esquerdo: sessao em roxo -> verde neon
set -g status-left "#[fg=colour232,bg=colour96,bold] #S #[fg=colour96,bg=colour35,nobold]#[fg=colour232,bg=colour35,bold] ❯ #[fg=colour35,bg=colour232,nobold] "
set -g status-left-length 35

# Direito: ROS + hora + host
set -g status-right "#[fg=colour60,bg=colour232] #(echo $ROS_MASTER_URI) #[fg=colour35,bg=colour232]#[fg=colour232,bg=colour35,bold] %H:%M #[fg=colour96,bg=colour35]#[fg=colour232,bg=colour96,bold] #H "
set -g status-right-length 65

# Janela ativa — verde neon
setw -g window-status-current-format "#[fg=colour232,bg=colour35,nobold]#[fg=colour232,bg=colour35,bold] #I ❙ #W #[fg=colour35,bg=colour232,nobold]"

# Janelas inativas — roxo apagado
setw -g window-status-format "#[fg=colour60,bg=colour232] #I ❙ #W "

# Pane border — verde neon em todos os panes
set -g pane-border-style fg=colour35
set -g pane-active-border-style fg=colour35
set -g pane-border-lines single

setw -g clock-mode-colour colour35
set-option -g default-shell /usr/bin/zsh
"""
with open(os.path.expanduser("~/.tmux.conf"), "w") as f:
    f.write(content)
print("Escrito: ~/.tmux.conf")
PYEOF

# -----------------------------------------------------------------------------
# ~/.config/ranger/rc.conf
# -----------------------------------------------------------------------------
info "Escrevendo ~/.config/ranger/rc.conf..."
mkdir -p "$HOME/.config/ranger"
cat > "$HOME/.config/ranger/rc.conf" << 'RANGER_EOF'
# =============================================================================
# ~/.config/ranger/rc.conf — baseado no linux-setup do LASER-Robotics
# =============================================================================

# Layout e visualizacao
set column_ratios 1,3,4
set show_hidden false
set line_numbers relative
set preview_files true
set preview_directories true
set collapse_preview true
set scroll_offset 8
set unicode_ellipsis false
set draw_borders false
set dirname_in_tabs true
set status_bar_on_top false
set draw_progress_bar_in_status_bar true
set hidden_filter ^\\.|\\.(?:pyc|pyo|bak|swp)$|^lost\+found$|^__(py)?cache__$

# Preview de imagens
set preview_images true
set preview_images_method w3m
set open_all_images true

# VCS (git)
set vcs_aware true
set vcs_backend_git enabled
set vcs_backend_hg disabled
set vcs_backend_bzr disabled

# Ordenacao
set sort natural
set sort_reverse false
set sort_case_insensitive true
set sort_directories_first true

# Historico e bookmarks
set max_history_size 20
set max_console_history_size 50
set autosave_bookmarks false
set show_hidden_bookmarks true
set cd_bookmarks true
set save_console_history true

# Misc
set confirm_on_delete multiple
set preview_script ~/.config/ranger/scope.sh
set use_preview_script true
set automatically_count_files true
set flushinput true
set padding_right true
set show_cursor false
set mouse_enabled true
set display_size_in_main_column true
set display_size_in_status_bar true
set display_tags_in_all_columns true
set update_title false
set update_tmux_title false
set shorten_title 3
set tilde_in_titlebar false
set idle_delay 2000
set metadata_deep_search false
set show_selection_in_titlebar true
set xterm_alt_key false
set autoupdate_cumulative_size false
set preview_max_size 0

# Aliases de console
alias e    edit
alias q    quit
alias q!   quitall
alias qa   quitall
alias qall quitall
alias setl setlocal
alias filter     scout -prt
alias find       scout -aeit
alias mark       scout -mr
alias unmark     scout -Mr
alias search     scout -rs
alias search_inc scout -rts
alias travel     scout -aefiklst

# Navegacao basica
map Q quit!
map q quit
copymap q ZZ ZQ
map R     reload_cwd
map <C-r> reset
map <C-l> redraw_window
map <C-c> abort
map <esc> change_mode normal
map i display_file
map ? help
map W display_log
map w taskview_open
map S shell $SHELL
map :  console
map ;  console
map !  console shell%space
map @  console -p6 shell  %%s
map #  console shell -p%space
map s  console shell%space
map r  chain draw_possible_programs; console open_with%space
map f  console find%space
map cd console cd%space

# Line mode
map Mf linemode filename
map Mi linemode fileinfo
map Mp linemode permissions
map Mt linemode metatitle

# Tagging e marking
map t       tag_toggle
map ut      tag_remove
map "<any>  tag_toggle tag=%any
map <Space> mark_files toggle=True
map v       mark_files all=True toggle=True
map uv      mark_files all=True val=False
map V       toggle_visual_mode
map uV      toggle_visual_mode reverse=True

# F-keys (Midnight Commander style)
map <F1> help
map <F3> display_file
map <F4> edit
map <F5> copy
map <F6> cut
map <F7> console mkdir%space
map <F8> console delete
map <F10> exit

# Movement
map <UP>       move up=1
map <DOWN>     move down=1
map <LEFT>     move left=1
map <RIGHT>    move right=1
map <HOME>     move to=0
map <END>      move to=-1
map <PAGEDOWN> move down=1   pages=True
map <PAGEUP>   move up=1     pages=True
map <CR>       move right=1
map <INSERT>   console touch%space
copymap <UP>       k
copymap <DOWN>     j
copymap <LEFT>     h
copymap <RIGHT>    l
copymap <HOME>     gg
copymap <END>      G
copymap <PAGEDOWN> <C-F>
copymap <PAGEUP>   <C-B>
map J  move down=0.5  pages=True
map K  move up=0.5    pages=True
copymap J <C-D>
copymap K <C-U>

# Jumping
map H     history_go -1
map L     history_go 1
map ]     move_parent 1
map [     move_parent -1
map }     traverse
map gh cd ~

# Operacoes em arquivos
map E  edit
map du shell -p du --max-depth=1 -h --apparent-size
map dU shell -p du --max-depth=1 -h --apparent-size | sort -rh
map yp shell -f echo -n %d/%f | xsel -i; xsel -o | xsel -i -b
map yd shell -f echo -n %d    | xsel -i; xsel -o | xsel -i -b
map yn shell -f echo -n %f    | xsel -i; xsel -o | xsel -i -b
map =  chmod
map cw console rename%space
map a  rename_append
map A  eval fm.open_console('rename ' + fm.thisfile.basename)
map I  eval fm.open_console('rename ' + fm.thisfile.basename, position=7)
map pp paste
map po paste overwrite=True
map pl paste_symlink relative=False
map pL paste_symlink relative=True
map phl paste_hardlink
map pht paste_hardlinked_subtree
map dD console delete
map dd cut
map ud uncut
map da cut mode=add
map dr cut mode=remove
map yy copy
map uy uncut
map ya copy mode=add
map yr copy mode=remove
map dgg eval fm.cut(dirarg=dict(to=0), narg=quantifier)
map dG  eval fm.cut(dirarg=dict(to=-1), narg=quantifier)
map dj  eval fm.cut(dirarg=dict(down=1), narg=quantifier)
map dk  eval fm.cut(dirarg=dict(up=1), narg=quantifier)
map ygg eval fm.copy(dirarg=dict(to=0), narg=quantifier)
map yG  eval fm.copy(dirarg=dict(to=-1), narg=quantifier)
map yj  eval fm.copy(dirarg=dict(down=1), narg=quantifier)
map yk  eval fm.copy(dirarg=dict(up=1), narg=quantifier)

# Busca
map /  console search%space
map n  search_next
map N  search_next forward=False
map ct search_next order=tag
map cs search_next order=size
map ci search_next order=mimetype
map cc search_next order=ctime
map cm search_next order=mtime
map ca search_next order=atime

# fzf — Ctrl+f ou Ctrl+p
map <C-f> fzf_select
map <C-p> fzf_select

# editar em split do tmux
map ef eval if not os.environ.get('TMUX') == '': fm.execute_console("shell tmux splitw -h 'bash -c \"$EDITOR " + fm.thisfile.basename + "\"'")

# Tabs
map <C-n>     tab_new ~
map <C-w>     tab_close
map <TAB>     tab_move 1
map <S-TAB>   tab_move -1
map <A-Right> tab_move 1
map <A-Left>  tab_move -1
map uq        tab_restore
map <a-1>     tab_open 1
map <a-2>     tab_open 2
map <a-3>     tab_open 3
map <a-4>     tab_open 4
map <a-5>     tab_open 5
map <a-6>     tab_open 6
map <a-7>     tab_open 7
map <a-8>     tab_open 8
map <a-9>     tab_open 9

# Ordenacao
map or toggle_option sort_reverse
map oz set sort=random
map os chain set sort=size;      set sort_reverse=False
map ob chain set sort=basename;  set sort_reverse=False
map on chain set sort=natural;   set sort_reverse=False
map om chain set sort=mtime;     set sort_reverse=False
map oc chain set sort=ctime;     set sort_reverse=False
map oa chain set sort=atime;     set sort_reverse=False
map ot chain set sort=type;      set sort_reverse=False
map oe chain set sort=extension; set sort_reverse=False
map oS chain set sort=size;      set sort_reverse=True
map oB chain set sort=basename;  set sort_reverse=True
map oN chain set sort=natural;   set sort_reverse=True
map oM chain set sort=mtime;     set sort_reverse=True
map oC chain set sort=ctime;     set sort_reverse=True
map oA chain set sort=atime;     set sort_reverse=True
map oT chain set sort=type;      set sort_reverse=True
map oE chain set sort=extension; set sort_reverse=True
map dc get_cumulative_size

# Settings toggle
map zc    toggle_option collapse_preview
map zd    toggle_option sort_directories_first
map zh    toggle_option show_hidden
map <C-h> toggle_option show_hidden
map zi    toggle_option flushinput
map zm    toggle_option mouse_enabled
map zp    toggle_option preview_files
map zP    toggle_option preview_directories
map zs    toggle_option sort_case_insensitive
map zu    toggle_option autoupdate_cumulative_size
map zv    toggle_option use_preview_script
map zf    console filter%space

# Bookmarks
map `<any>  enter_bookmark %any
map '<any>  enter_bookmark %any
map m<any>  set_bookmark %any
map um<any> unset_bookmark %any
map m<bg>   draw_bookmarks
copymap m<bg> um<bg> `<bg> '<bg>

# chmod bindings
eval for arg in "rwxXst": cmd("map +u{0} shell -f chmod u+{0} %s".format(arg))
eval for arg in "rwxXst": cmd("map +g{0} shell -f chmod g+{0} %s".format(arg))
eval for arg in "rwxXst": cmd("map +o{0} shell -f chmod o+{0} %s".format(arg))
eval for arg in "rwxXst": cmd("map +a{0} shell -f chmod a+{0} %s".format(arg))
eval for arg in "rwxXst": cmd("map +{0}  shell -f chmod u+{0} %s".format(arg))
eval for arg in "rwxXst": cmd("map -u{0} shell -f chmod u-{0} %s".format(arg))
eval for arg in "rwxXst": cmd("map -g{0} shell -f chmod g-{0} %s".format(arg))
eval for arg in "rwxXst": cmd("map -o{0} shell -f chmod o-{0} %s".format(arg))
eval for arg in "rwxXst": cmd("map -a{0} shell -f chmod a-{0} %s".format(arg))
eval for arg in "rwxXst": cmd("map -{0}  shell -f chmod u-{0} %s".format(arg))

# Console keybindings
cmap <tab>   eval fm.ui.console.tab()
cmap <s-tab> eval fm.ui.console.tab(-1)
cmap <ESC>   eval fm.ui.console.close()
cmap <CR>    eval fm.ui.console.execute()
cmap <C-l>   redraw_window
copycmap <ESC> <C-c>
copycmap <CR>  <C-j>
cmap <up>    eval fm.ui.console.history_move(-1)
cmap <down>  eval fm.ui.console.history_move(1)
cmap <left>  eval fm.ui.console.move(left=1)
cmap <right> eval fm.ui.console.move(right=1)
cmap <home>  eval fm.ui.console.move(right=0, absolute=True)
cmap <end>   eval fm.ui.console.move(right=-1, absolute=True)
cmap <backspace>  eval fm.ui.console.delete(-1)
cmap <delete>     eval fm.ui.console.delete(0)
cmap <C-w>        eval fm.ui.console.delete_word()
cmap <C-k>        eval fm.ui.console.delete_rest(1)
cmap <C-u>        eval fm.ui.console.delete_rest(-1)
cmap <C-y>        eval fm.ui.console.paste()
copycmap <up>        <C-p>
copycmap <down>      <C-n>
copycmap <left>      <C-b>
copycmap <right>     <C-f>
copycmap <home>      <C-a>
copycmap <end>       <C-e>
copycmap <delete>    <C-d>
copycmap <backspace> <C-h>
copycmap <backspace> <backspace2>
cmap <allow_quantifiers> false

# Pager keybindings
pmap  <down>      pager_move  down=1
pmap  <up>        pager_move  up=1
pmap  <left>      pager_move  left=4
pmap  <right>     pager_move  right=4
pmap  <home>      pager_move  to=0
pmap  <end>       pager_move  to=-1
pmap  <pagedown>  pager_move  down=1.0  pages=True
pmap  <pageup>    pager_move  up=1.0    pages=True
pmap  <C-d>       pager_move  down=0.5  pages=True
pmap  <C-u>       pager_move  up=0.5    pages=True
copypmap <UP>       k  <C-p>
copypmap <DOWN>     j  <C-n> <CR>
copypmap <LEFT>     h
copypmap <RIGHT>    l
copypmap <HOME>     g
copypmap <END>      G
copypmap <C-d>      d
copypmap <C-u>      u
copypmap <PAGEDOWN> n  f  <C-F>  <Space>
copypmap <PAGEUP>   p  b  <C-B>
pmap     <C-l> redraw_window
pmap     <ESC> pager_close
copypmap <ESC> q Q i <F3>
pmap E      edit_file

# Taskview keybindings
tmap <up>        taskview_move up=1
tmap <down>      taskview_move down=1
tmap <home>      taskview_move to=0
tmap <end>       taskview_move to=-1
tmap <pagedown>  taskview_move down=1.0  pages=True
tmap <pageup>    taskview_move up=1.0    pages=True
tmap <C-d>       taskview_move down=0.5  pages=True
tmap <C-u>       taskview_move up=0.5    pages=True
copytmap <UP>       k  <C-p>
copytmap <DOWN>     j  <C-n> <CR>
copytmap <HOME>     g
copytmap <END>      G
copytmap <C-u>      u
copytmap <PAGEDOWN> n  f  <C-F>  <Space>
copytmap <PAGEUP>   p  b  <C-B>
tmap J          eval -q fm.ui.taskview.task_move(-1)
tmap K          eval -q fm.ui.taskview.task_move(0)
tmap dd         eval -q fm.ui.taskview.task_remove()
tmap <pagedown> eval -q fm.ui.taskview.task_move(-1)
tmap <pageup>   eval -q fm.ui.taskview.task_move(0)
tmap <delete>   eval -q fm.ui.taskview.task_remove()
tmap <C-l> redraw_window
tmap <ESC> taskview_close
copytmap <ESC> q Q w <C-c>
RANGER_EOF

# -----------------------------------------------------------------------------
# ~/.config/zathura/zathurarc
# -----------------------------------------------------------------------------
info "Escrevendo ~/.config/zathura/zathurarc..."
mkdir -p "$HOME/.config/zathura"
cat > "$HOME/.config/zathura/zathurarc" << 'ZATHURA_EOF'
# =============================================================================
# ~/.config/zathura/zathurarc — baseado no linux-setup do LASER-Robotics
# =============================================================================
map s toggle_statusbar
map a adjust_window best-fit
map w adjust_window width
map c set recolor true
map u navigate next
map i navigate previous
set selection-clipboard clipboard
ZATHURA_EOF

# -----------------------------------------------------------------------------
# ~/.config/kitty/kitty.conf
# -----------------------------------------------------------------------------
info "Configurando kitty..."
mkdir -p "$HOME/.config/kitty"

# Garante que nao ha entradas duplicadas
grep -v "shell /usr\|send_text.*x1b\|send_key ctrl\|Passa Ctrl\|map ctrl+9\|map ctrl+0" \
  "$HOME/.config/kitty/kitty.conf" 2>/dev/null > /tmp/kitty_clean.conf || true

cat >> /tmp/kitty_clean.conf << 'KITTY_EOF'

# Shell padrao
shell /usr/bin/zsh

# Transparencia 65% opaco
background_opacity 0.65

# Bordas da janela — verde neon ativo, roxo apagado inativo
active_border_color #00af5f
inactive_border_color #5f5f87

# Ctrl+9 e Ctrl+0 -> envia ESC+9 e ESC+0 pro tmux (M-9 / M-0)
map ctrl+9 send_text all \x1b9
map ctrl+0 send_text all \x1b0
KITTY_EOF

cp /tmp/kitty_clean.conf "$HOME/.config/kitty/kitty.conf"


# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# ~/.vimrc — Eva-01 theme
# Baseado no vimrc do linux-setup com colorscheme eva01
# -----------------------------------------------------------------------------
info "Escrevendo ~/.vimrc com tema Eva-01..."

# Instala vim-plug se nao existir
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

cat > "$HOME/.vimrc" << 'VIMRC_EOF'
set nocompatible
set t_Co=256
set encoding=utf-8
set lazyredraw
set termguicolors

call plug#begin("~/.vim/plugged")
  " Status bar
  Plug 'bling/vim-airline'
  Plug 'vim-airline/vim-airline-themes'

  " Git integration
  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'

  " Navegacao tmux+vim
  Plug 'christoomey/vim-tmux-navigator'

  " Fuzzy finder
  Plug 'ctrlpvim/ctrlp.vim'

  " Comentarios
  Plug 'tpope/vim-commentary'

  " Surround
  Plug 'tpope/vim-surround'

  " File manager
  Plug 'scrooloose/nerdtree'

  " Repeat
  Plug 'tpope/vim-repeat'

  " ROS support
  Plug 'klaxalk/vim-ros'

  " C++ highlight
  Plug 'octol/vim-cpp-enhanced-highlight'

  " Home screen
  Plug 'mhinz/vim-startify'
call plug#end()

" === Auto-instala plugins na primeira vez ===
if empty(glob("~/.vim/plugged/vim-airline"))
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" === Colorscheme Eva-01 x Gundam — inline, sem plugin externo ===
" Paleta: preto fundo | roxo #875f87 | verde neon #00af5f | branco #dadada
set background=dark
highlight clear
if exists("syntax_on") | syntax reset | endif
let g:colors_name = "eva01gundam"

hi Normal          guifg=#dadada   guibg=#0d0d0d   ctermfg=253  ctermbg=232
hi LineNr          guifg=#5f5f87   guibg=#0d0d0d   ctermfg=60   ctermbg=232
hi CursorLineNr    guifg=#00af5f   guibg=#1a001a   ctermfg=35   ctermbg=234  gui=bold
hi CursorLine                      guibg=#1a001a                ctermbg=234
hi Visual                          guibg=#3d005f                ctermbg=54
hi Search          guifg=#0d0d0d   guibg=#00af5f   ctermfg=232  ctermbg=35
hi IncSearch       guifg=#0d0d0d   guibg=#875f87   ctermfg=232  ctermbg=96
hi Comment         guifg=#5f5f87                   ctermfg=60               gui=italic
hi String          guifg=#00af5f                   ctermfg=35
hi Keyword         guifg=#875f87                   ctermfg=96   gui=bold
hi Statement       guifg=#875f87                   ctermfg=96   gui=bold
hi Function        guifg=#00d75f                   ctermfg=41   gui=bold
hi Identifier      guifg=#00af5f                   ctermfg=35
hi Type            guifg=#af87af                   ctermfg=139
hi PreProc         guifg=#5f87af                   ctermfg=67
hi Constant        guifg=#87af87                   ctermfg=108
hi Number          guifg=#87d787                   ctermfg=114
hi Boolean         guifg=#875f87                   ctermfg=96   gui=bold
hi Special         guifg=#af87d7                   ctermfg=140
hi Error           guifg=#ff0000   guibg=#0d0d0d   ctermfg=196  ctermbg=232
hi Todo            guifg=#00af5f   guibg=#1a001a   ctermfg=35   ctermbg=234  gui=bold
hi MatchParen      guifg=#0d0d0d   guibg=#00af5f   ctermfg=232  ctermbg=35   gui=bold
hi StatusLine      guifg=#0d0d0d   guibg=#875f87   ctermfg=232  ctermbg=96   gui=bold
hi StatusLineNC    guifg=#5f5f87   guibg=#1a001a   ctermfg=60   ctermbg=234
hi VertSplit       guifg=#5f005f                   ctermfg=53
hi Pmenu           guifg=#dadada   guibg=#1a001a   ctermfg=253  ctermbg=234
hi PmenuSel        guifg=#0d0d0d   guibg=#00af5f   ctermfg=232  ctermbg=35
hi PmenuSbar                       guibg=#3d005f                ctermbg=54
hi PmenuThumb                      guibg=#875f87                ctermbg=96
hi TabLine         guifg=#5f5f87   guibg=#0d0d0d   ctermfg=60   ctermbg=232
hi TabLineSel      guifg=#0d0d0d   guibg=#875f87   ctermfg=232  ctermbg=96   gui=bold
hi TabLineFill                     guibg=#0d0d0d                ctermbg=232
hi FoldColumn      guifg=#5f5f87   guibg=#0d0d0d   ctermfg=60   ctermbg=232
hi Folded          guifg=#875f87   guibg=#1a001a   ctermfg=96   ctermbg=234  gui=italic
hi SignColumn                      guibg=#0d0d0d                ctermbg=232
hi GitGutterAdd    guifg=#00af5f                   ctermfg=35
hi GitGutterChange guifg=#875f87                   ctermfg=96
hi GitGutterDelete guifg=#870000                   ctermfg=88
hi DiffAdd         guifg=#00af5f   guibg=#001a00   ctermfg=35   ctermbg=22
hi DiffDelete      guifg=#870000   guibg=#1a0000   ctermfg=88   ctermbg=52
hi DiffChange                      guibg=#1a001a                ctermbg=234
hi DiffText        guifg=#875f87   guibg=#2d0040   ctermfg=96   ctermbg=53   gui=bold
hi NonText         guifg=#3d003d                   ctermfg=53
hi SpecialKey      guifg=#3d003d                   ctermfg=53
hi Title           guifg=#00af5f                   ctermfg=35   gui=bold
hi Directory       guifg=#00af5f                   ctermfg=35   gui=bold

let g:airline_theme = 'dark'
autocmd VimEnter * AirlineRefresh

" === Configuracoes gerais ===
set clipboard=unnamedplus
syntax enable
set splitbelow
set splitright
set number
set relativenumber
set expandtab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set autoindent
set smartindent
set scrolloff=10
set showmatch
set ignorecase
set smartcase
set hlsearch
set incsearch
set wildmenu
set wildmode=full
set wrap
set linebreak
set synmaxcol=400

" === Leader ===
nnoremap , <NOP>
let mapleader = ","
nmap <space> ,
let maplocalleader = "\`"

" === Splits com vim keys ===
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" === Tabs ===
nnoremap <Tab>   :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <S-J>   :tabn<CR>
nnoremap <S-K>   :tabp<CR>

" === Escape no insert mode ===
imap <expr> jk (pumvisible()?(empty(v:completed_item)?("<Esc>l"):("\<C-n>\<C-p>")):("\<Esc>l"))

" === H e L para inicio/fim de linha ===
nmap H ^
vmap H ^
nmap L $
vmap L $

" === Busca visual ===
vnoremap // y/<C-R>"<CR>

" === nao pula pro proximo na busca ===
nmap * *N

" === Salvar com maiuscula ===
command! WQ wq
command! Wq wq
command! W w
command! Q q

" === NERDTree ===
nnoremap <leader>n :NERDTreeToggle<CR>

" === CtrlP ===
let g:ctrlp_map = '<C-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'

" === Startify bookmarks Eva-01 ===
let g:startify_bookmarks = [
      \ { 'r': '~/.config/ranger/rc.conf' },
      \ { 't': '~/.tmux.conf' },
      \ { 'v': '~/.vimrc' },
      \ { 'z': '~/.zshrc' },
      \ { 'a': '~/.zshrc_laser_aliases' },
      \ ]

" === Airline Eva-01 x Gundam ===
let g:airline_powerline_fonts = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#hunks#enabled = 1
let g:airline_theme = 'violet'

" Cores customizadas da airline pra bater com o wallpaper
let g:airline#themes#violet#palette = {}
function! AirlineThemeEva()
  let l:gui_bg   = '#0d0d1a'
  let l:gui_roxo = '#a800c0'
  let l:gui_verde= '#4d8c57'
  let l:gui_amar = '#c8b400'
  let l:gui_fg   = '#dadada'
  let g:airline_theme_patch_func = ''
endfunction

" === Fix cores no tmux ===
if !has("nvim")
  set term=screen-256color
  cnoreabbrev vt vertical terminal
  cnoreabbrev st terminal
endif
VIMRC_EOF

# ~/.zshrc_laser_aliases — aliases e funcoes do LASER, source no .zshrc
# -----------------------------------------------------------------------------
info "Escrevendo ~/.zshrc_laser_aliases..."
cat > "$HOME/.zshrc_laser_aliases" << 'ALIASES_EOF'
# =============================================================================
# ~/.zshrc_laser_aliases
# Aliases e funcoes baseados no linux-setup do LASER-Robotics
# =============================================================================

# FZF
export FZF_DEFAULT_OPTS='--height 25%'
export FZF_DEFAULT_COMMAND='ag -l -f --nocolor -g ""'

# Vi mode no zsh + hjkl no menu de completion
bindkey -v
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
unsetopt share_history

# Aliases gerais
alias :q=exit
alias sb="source ~/.zshrc"
alias ra=ranger
alias demangle="c++filt"

# Ranger: volta pro diretorio certo ao sair
ranger() {
  command ranger --choosedir="/tmp/lastrangerdir" "$@"
  LASTDIR=$(cat "/tmp/lastrangerdir")
  cd "$LASTDIR"
}

# Git
alias gs="git status"
alias gcmp="git checkout master; git pull"
alias gr="git submodule foreach git"
alias glog="git log --graph --abbrev-commit --date=relative --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"

git2ssh() {
  old_remote=$(git remote get-url origin)
  echo "Old remote: $old_remote"
  new_remote=$(echo $old_remote | sed -r 's|https://([^/]+)/(.+)|git@\1:\2|' | head -n 1)
  echo "New remote: $new_remote"
  [ -n "$new_remote" ] && git remote set-url origin "$new_remote"
}

git2https() {
  old_remote=$(git remote get-url origin)
  echo "Old remote: $old_remote"
  new_remote=$(echo $old_remote | sed -r 's|.*git@(.+):(.+)|https://\1/\2|' | head -n 1)
  echo "New remote: $new_remote"
  [ -n "$new_remote" ] && git remote set-url origin "$new_remote"
}

gitUpdateSubmodules() {
  echo "Syncing git submodules"
  command git submodule sync
  echo "Updating git submodules"
  command git submodule update --init --recursive
}

# Tmux
alias :qa="quitTmuxSession"

quitTmuxSession() {
  if [ ! -z "$TMUX" ]; then
    echo "Matando sessao tmux..."
    pids=$(tmux list-panes -s -F "#{pane_pid} #{pane_current_command}" | grep -v tmux | awk '{print $1}')
    for pid in $pids; do
      kill -9 "$pid" 2>/dev/null &
    done
    SESSION_NAME=$(tmux display-message -p '#S')
    tmux kill-session -t "$SESSION_NAME"
  else
    exit
  fi
}

killp() {
  if [ $# -eq 0 ]; then
    echo "killp() precisa de um argumento (PID)"
    return
  fi
  for child in $(ps -o pid,ppid -ax | awk "{ if (\$2 == $1) { print \$1 }}"); do
    killp $child
  done
  kill -9 "$1" 2>/dev/null
}

# Auto-tmux: sessao unica por janela de terminal (baseado no PID do zsh pai)
runTmux() {
  SESSION_NAME="T$PPID"
  EXISTING=$(tmux ls 2>/dev/null | grep "$SESSION_NAME" | wc -l)
  if [ "$EXISTING" -gt "0" ]; then
    tmux -2 attach-session -t "$SESSION_NAME"
  else
    tmux new-session -s "$SESSION_NAME"
  fi
  # restaura ultimo diretorio ao sair
  FILENAME="/tmp/tmux_restore_path.txt"
  if [ -f "$FILENAME" ]; then
    MY_PATH=$(tail -n 1 "$FILENAME")
    rm "$FILENAME"
    [ -d "$MY_PATH" ] && cd "$MY_PATH"
  fi
}

zshexit() {
  pwd >> /tmp/tmux_restore_path.txt
}

# Roda auto-tmux somente em shells interativos fora do tmux
case "$-" in
  *i*)
    [[ ! $TERM =~ screen ]] && [ -z "$TMUX" ] && runTmux
    ;;
esac

# Utilitarios
getVideoThumbnail() {
  if [ $# -eq 0 ]; then
    echo "Uso: getVideoThumbnail <arquivo> [timestamp=00:00:01]"
    return 1
  fi
  file="$1"
  frame="${2:-00:00:01}"
  output="${file%.*}_thumbnail.jpg"
  ffmpeg -i "$file" -ss "$frame" -vframes 1 "$output"
  echo "Thumbnail salvo em: $output"
}

auto-retry() {
  false
  while [ $? -ne 0 ]; do
    "$@" || (sleep 1; false)
  done
}

ssh-auto-retry() {
  auto-retry ssh "$@"
}

cd_media() {
  cd /media/$USER
  ranger
}

# Toggle entre zsh e bash no kitty
toggle-shell() {
  current=$(grep "^shell" ~/.config/kitty/kitty.conf 2>/dev/null | awk '{print $2}')
  if [[ "$current" == "/usr/bin/zsh" ]]; then
    sed -i 's|^shell /usr/bin/zsh|shell /bin/bash|' ~/.config/kitty/kitty.conf
    echo "Kitty agora vai abrir com: bash (abre novo terminal pra aplicar)"
  else
    sed -i 's|^shell /bin/bash|shell /usr/bin/zsh|' ~/.config/kitty/kitty.conf
    echo "Kitty agora vai abrir com: zsh (abre novo terminal pra aplicar)"
  fi
}
ALIASES_EOF



# =============================================================================
# Tema oh-my-zsh Eva-01 customizado
# =============================================================================
info "Criando tema oh-my-zsh Eva-01..."
cat > "$HOME/.oh-my-zsh/custom/themes/eva01.zsh-theme" << 'EVA_EOF'
# Eva-01 x Gundam theme for oh-my-zsh
# Paleta: preto | roxo #875f87(96) | verde neon #00af5f(35) | branco #dadada(253)

EVA_ROXO='%F{135}'        # roxo claro #af87ff
EVA_VERDE='%F{35}'         # verde neon #00af5f
EVA_CINZA='%F{60}'         # roxo apagado #5f5f87
EVA_BRANCO='%F{253}'       # branco suave #dadada
RESET='%f'

# Git info — mostra branch e dirty flag
eva_git_info() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  local dirty=""
  [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty=" ✦"
  echo " ${EVA_VERDE}⎇ ${branch}${EVA_ROXO}${dirty}${RESET}"
}

# Prompt numa linha so: user@host roxo | path branco | branch | ❯ verde
PROMPT='${EVA_ROXO}%n@%m${RESET} ${EVA_BRANCO}%~${RESET}$(eva_git_info) ${EVA_VERDE}❯${RESET} '

# Prompt direito: hora em cinza
RPROMPT='${EVA_CINZA}[%T]${RESET}'
EVA_EOF

# =============================================================================
# ~/.zshrc — gerado limpo, sem lixo acumulado
# =============================================================================
info "Escrevendo ~/.zshrc limpo..."
cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="eva01"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# fzf
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ]   && source /usr/share/doc/fzf/examples/completion.zsh

# ROS 2 Humble
source /opt/ros/humble/setup.zsh

# LASER aliases, funcoes e auto-tmux
source $HOME/.zshrc_laser_aliases
ZSHRC_EOF


# =============================================================================
# SWAYBG — papel de parede (mais estavel que hyprpaper no Ubuntu 22)
# =============================================================================
info "Instalando swaybg..."
sudo apt install -y swaybg

info "Configurando wallpaper..."
mkdir -p "$HOME/Pictures"

# Copia o wallpaper pra ~/Pictures/gundam.jpeg se existir no Downloads
WALL_SRC=$(find "$HOME/Downloads" -iname "*.jpeg" -o -iname "*.jpg" -o -iname "*.png" 2>/dev/null | head -1)
WALL_DST="$HOME/Pictures/gundam.jpeg"

if [ -n "$WALL_SRC" ] && [ ! -f "$WALL_DST" ]; then
  cp "$WALL_SRC" "$WALL_DST"
  info "Wallpaper copiado: $WALL_SRC -> $WALL_DST"
fi

# Substitui exec-once de hyprpaper por swaybg no hyprland.conf
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
  # Remove entradas antigas de wallpaper
  sed -i '/exec-once = hyprpaper/d' "$HYPR_CONF"
  sed -i '/exec-once = swaybg/d' "$HYPR_CONF"
  # Adiciona swaybg
  echo "exec-once = swaybg -i $HOME/Pictures/gundam.jpeg -m fill" >> "$HYPR_CONF"
  info "swaybg adicionado ao autostart do Hyprland"
fi

warn "Wallpaper configurado em ~/Pictures/gundam.jpeg"
warn "Para trocar: edite o exec-once do swaybg em ~/.config/hypr/hyprland.conf"

# =============================================================================
# HYPRLAND — bordas das janelas
# =============================================================================
info "Configurando bordas do Hyprland..."
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
  sed -i 's/col\.active_border\s*=.*/col.active_border = rgba(00af5fff)/' "$HYPR_CONF"
  sed -i 's/col\.inactive_border\s*=.*/col.inactive_border = rgba(5f5f87ff)/' "$HYPR_CONF"
  warn "Bordas do Hyprland atualizadas. Recarregue com: hyprctl reload"
else
  warn "hyprland.conf nao encontrado em $HYPR_CONF, pulando..."
fi

# =============================================================================
# DESABILITA TIMERS DO APT (menos interrupção em background)
# =============================================================================
info "Desabilitando apt timers automáticos..."
sudo systemctl disable apt-daily.service          2>/dev/null || true
sudo systemctl disable apt-daily.timer            2>/dev/null || true
sudo systemctl disable apt-daily-upgrade.timer    2>/dev/null || true
sudo systemctl disable apt-daily-upgrade.service  2>/dev/null || true

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Instalação concluída!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "  Dotfiles instalados (tema Eva-01):"
echo "    ~/.tmux.conf"
echo "    ~/.config/ranger/rc.conf"
echo "    ~/.config/zathura/zathurarc"
echo "    ~/.zshrc_laser_aliases"
  echo "    ~/.vimrc  (eva01 + plugins)"
  echo "    ~/.oh-my-zsh/custom/themes/eva01.zsh-theme"
echo ""
echo "  Proximos passos:"
echo "  1. Abra um novo terminal (ou rode: exec zsh)"
echo "  2. Verifique o ROS: ros2 --version"
echo "  3. Angry IP Scanner: ipscan"
  echo "  4. Instalar plugins vim: vim +PlugInstall +qall"
echo ""
