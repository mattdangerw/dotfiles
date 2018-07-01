# Basic setup
# ==============================================================================

[[ $- == *i* ]] && source ~/.fzf/shell/completion.zsh 2> /dev/null
FZF_THEME="fg:-1,fg+:-1,bg:-1,bg+:-1,hl:13,hl+:13,marker:13,prompt:4,pointer:4,spinner:4,header:242,info:242,border:242"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --prompt='? ' --color=${FZF_THEME}"

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

  FZF_COMMAND="fzf --tiebreak=end,index -m"

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
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) -m "$@" | while read item; do
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
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
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

# Git branches
# ==============================================================================

__fbranch() {
  setopt localoptions pipefail 2> /dev/null
  local branches branch
  branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format='%(refname:short)') &&
  branch=$(echo "$branches" | fzf +m)
  local ret=$?
  branch=$(echo "$branch" | awk '{print $1}' | sed "s/.* //")
  echo -n "$branch"
  return $ret
}

fzf-git-branch() {
  local branch="$(__fbranch)"
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
