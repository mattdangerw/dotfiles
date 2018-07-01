# Setup fzf
# ---------

# Auto-completion
# ---------------
[[ $- == *i* ]] && source ~/.fzf/shell/completion.zsh 2> /dev/null

# Key bindings
# ------------
source ~/.fzf/shell/key-bindings.zsh

# Fzfz
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

    FZF_COMMAND="fzf ${FZF_DEFAULT_OPTS} --tiebreak=end,index -m"

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