# xarepe-setup

Setup completo para Ubuntu 22.04 com Hyprland + tema Eva-01 x Gundam.

```
xarepe-setup/
├── install.sh              ← Script principal (rode esse)
├── scripts/
│   ├── 01-hyprland.sh      ← Hyprland + Waybar + dependencias (~60-120min)
│   ├── 02-waybar.sh        ← Tema Eva-01 no Waybar
│   ├── 03-tools.sh         ← tmux, vim, zsh, ROS2, YCM, Copilot, etc.
│   ├── 04-dotfiles.sh      ← Aplica todas as configs/dotfiles
│   └── 05-wallpaper.sh     ← Configura wallpaper via swaybg
├── configs/
│   ├── hypr/
│   │   └── hyprland.conf   ← Config do Hyprland (binds, gaps, bordas)
│   ├── waybar/
│   │   ├── config.jsonc    ← Modulos do Waybar
│   │   └── style.css       ← Tema visual Eva-01
│   ├── kitty/
│   │   └── kitty.conf      ← Terminal: zsh, transparencia, bordas, keymaps
│   ├── tmux/
│   │   └── tmux.conf       ← Prefixo Ctrl+a, splits, vim-nav, status bar
│   ├── ranger/
│   │   └── rc.conf         ← File manager: vim keys, fzf, git
│   ├── zathura/
│   │   └── zathurarc       ← PDF viewer: vim keys, clipboard
│   ├── vim/
│   │   ├── vimrc           ← Vim: eva01, YCM, Copilot, airline, etc.
│   │   └── ycm_extra_conf.py ← Config YCM para C++17/ROS2
│   └── zsh/
│       ├── zshrc           ← .zshrc limpo
│       ├── zshrc_laser_aliases ← Aliases, funções, auto-tmux
│       └── eva01.zsh-theme ← Tema do prompt
└── wallpapers/             ← Coloque seus wallpapers aqui (.jpg/.png)
    └── README.md
```

## Uso

```bash
chmod +x install.sh
./install.sh
```

Ou modo não-interativo:
```bash
./install.sh --all          # Instala tudo
./install.sh --hyprland     # Só Hyprland
./install.sh --waybar       # Só Waybar
./install.sh --tools        # Só ferramentas
./install.sh --dotfiles     # Só configs
./install.sh --wallpaper    # Só wallpaper
```

## Ordem recomendada (fresh install)

1. `./install.sh --hyprland` → reinicia → entra no Hyprland
2. `./install.sh --waybar`
3. `./install.sh --tools`
4. `./install.sh --dotfiles`
5. `./install.sh --wallpaper`

## Customização

Todos os arquivos em `configs/` são a fonte da verdade.
Edite eles antes de rodar os scripts — os scripts copiam de lá.

### Trocar wallpaper

Coloque sua imagem em `wallpapers/` e rode:
```bash
./install.sh --wallpaper
```

### Ajustar tema do Waybar

Edite `configs/waybar/style.css` e rode:
```bash
./install.sh --waybar
```

### Ajustar binds do Hyprland

Edite `configs/hypr/hyprland.conf` e rode:
```bash
./install.sh --dotfiles
# ou aplica direto:
cp configs/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
hyprctl reload
```

## Pós-instalação (vim)

```bash
vim +PlugInstall +qall
# No vim:
:Copilot setup
# YCM:
cd ~/.vim/plugged/YouCompleteMe
python3.12 install.py --clangd-completer
```

## Paleta Eva-01 x Gundam

| Cor | Hex | Uso |
|-----|-----|-----|
| Verde neon | `#00af5f` | Pane ativo, janela ativa, prompt `❯` |
| Roxo claro | `#af87ff` | Nome no prompt, seleção |
| Roxo médio | `#875f87` | Sessão tmux, keywords vim |
| Roxo escuro | `#5f5f87` | Inativo, comentários |
| Preto | `#0d0d0d` | Fundo |

## Keybinds tmux

| Bind | Ação |
|------|------|
| `Ctrl+a` | Prefixo |
| `F2` | Copy mode (vim) |
| `Ctrl+9` | Split horizontal |
| `Ctrl+0` | Split vertical |
| `Ctrl+t` | Nova janela |
| `Alt+u/i` | Janela anterior/próxima |
| `Ctrl+hjkl` | Navegar panes (integrado com vim) |
| `Alt+setas` | Navegar panes |

## Keybinds Hyprland

| Bind | Ação |
|------|------|
| `Alt+Enter` | Terminal (kitty) |
| `Alt+D` | Launcher (fuzzel) |
| `Alt+hjkl` | Foco entre janelas |
| `Alt+1-9` | Workspace |
| `Alt+Shift+Q` | Fechar janela |
| `Alt+F` | Fullscreen |
| `Alt+R` | Modo resize |
| `Alt+Shift+C` | Reload config |
| `PrintScreen` | Screenshot (slurp+grim) |
