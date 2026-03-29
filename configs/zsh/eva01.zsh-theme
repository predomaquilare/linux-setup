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