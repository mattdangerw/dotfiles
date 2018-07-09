# Basic setup
# ==============================================================================

[[ $- == *i* ]] && source ~/.fzf/shell/completion.zsh 2> /dev/null

FZF_THEME="fg:-1,fg+:-1,bg:-1,bg+:-1,hl:13,hl+:13,marker:13,prompt:4,pointer:4,spinner:4,header:242,info:242,border:242"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --prompt='? ' --tabstop=2 --bind='ctrl-p:toggle-preview' --color=${FZF_THEME}"

# Directory switching (fzfz)
# ==============================================================================

if [[ $OSTYPE == darwin* ]]; then
    REVERSER='tail -r'
else
    REVERSER='tac'
fi

FZFZ_EXTRA_DIRS="~ ~/checkout"
FZFZ_UNIQUIFIER="awk '!seen[\$0]++'"

__fzfz() {
  EXTRA_DIRS="{ find $FZFZ_EXTRA_DIRS -maxdepth 1 -type d 2> /dev/null }"

  FZFZ_SUBDIR_LIMIT=0

  RECENTLY_USED_DIRS="{ z -l | $REVERSER | sed 's/^[[:digit:].]*[[:space:]]*//' }"

  FZF_COMMAND="fzf --bind='ctrl-g:abort' --tiebreak=end,index -m"

  local COMMAND="{ $RECENTLY_USED_DIRS ; $EXTRA_DIRS; } | $FZFZ_UNIQUIFIER | $FZF_COMMAND"

  eval "$COMMAND" | while read item; do
    printf '%q ' "$item"
  done
  echo
}

fzfz-file-widget() {
  LBUFFER="${LBUFFER}$(__fzfz)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}

zle     -N   fzfz-file-widget
bindkey '^G' fzfz-file-widget

# Select paths
# ==============================================================================

__fsel() {
  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail 2> /dev/null
  eval "$cmd" | FZF_DEFAULT_OPTS="--bind='ctrl-f:abort' --height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@" | while read item; do
    echo -n "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}

__fzf_use_tmux__() {
  [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ]
}

__fzfcmd() {
  __fzf_use_tmux__ &&
    echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}

fzf-file-widget() {
  LBUFFER="${LBUFFER}$(__fsel)"
  local ret=$?
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}
zle     -N   fzf-file-widget
bindkey '^F' fzf-file-widget

# Zsh history
# ==============================================================================

fzf-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail 2> /dev/null
  selected=( $(fc -rl 1 |
    FZF_DEFAULT_OPTS="--bind='ctrl-r:abort' --height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}
zle     -N   fzf-history-widget
bindkey '^R' fzf-history-widget

# Git magic
# ==============================================================================

is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

fbranch() {
  is_in_git_repo || return
  setopt localoptions pipefail 2> /dev/null
  local branches branch
  git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' |
  fzf --bind='ctrl-b:abort' --ansi --no-sort --reverse \
    --preview 'echo {} | awk "{print $1}" | sed "s/.* //" | xargs git graph | head -c 2M' |
  awk '{print $1}' | sed "s/.* //"
}

fzf-git-branch() {
  local branch="$(fbranch)"
  local ret=$?
  if [[ -n "$branch" ]]; then
    if [[ -z "$LBUFFER" ]]; then
      if [ $GIT_MODE ]; then
        LBUFFER="checkout ${branch}"
      else
        LBUFFER="git checkout ${branch}"
      fi
    else
      LBUFFER="${LBUFFER}${branch}"
    fi
  fi
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}
zle     -N   fzf-git-branch
bindkey '^B' fzf-git-branch

fhash() {
  is_in_git_repo || return
  git log --date=short --format='%C(green)%cd %C(auto)%h%d %s %C(242)(%ae)' --color=always $1 |
  fzf --bind='ctrl-h:abort' --ansi --height 100% --no-sort --reverse \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | diff-so-fancy | head -c 2M' |
  command grep -o "[a-f0-9]\{7,\}"
}
alias flog='fhash'

fzf-git-history() {
  local hash="$(fhash)"
  local ret=$?
  if [[ -n "$hash" ]]; then
    if [[ -z "$LBUFFER" ]]; then
      if [ $GIT_MODE ]; then
        LBUFFER="show ${hash}"
      else
        LBUFFER="git show ${hash}"
      fi
    else
      LBUFFER="${LBUFFER}${hash}"
    fi
  fi
  zle redisplay
  typeset -f zle-line-init >/dev/null && zle zle-line-init
  return $ret
}
zle     -N   fzf-git-history
bindkey '^H' fzf-git-history

# fkill
# ==============================================================================

fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}
