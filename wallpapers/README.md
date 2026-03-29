# Wallpapers

Coloque seus wallpapers aqui (.jpg, .jpeg, .png, .webp).

Ao rodar `./install.sh --wallpaper`, o script lista os arquivos desta pasta
e te deixa escolher qual aplicar.

O wallpaper escolhido é copiado para `~/Pictures/wallpapers/current.jpg`
e configurado no `~/.config/hypr/hyprland.conf` via swaybg.

## Trocar wallpaper depois

```bash
./install.sh --wallpaper
```

Ou manualmente:
```bash
pkill swaybg
swaybg -i ~/Pictures/wallpapers/current.jpg -m fill &
```
