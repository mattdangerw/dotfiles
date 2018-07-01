#!/usr/bin/env zsh
#
# Based on https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh
# (MIT licensed, as of 2016-05-05).

FZFZ_EXTRA_DIRS="~ ~/checkout"

if [[ $OSTYPE == darwin* ]]; then
    REVERSER='tail -r'
else
    REVERSER='tac'
fi

command -v tree >/dev/null 2>&1
if [ $? -eq 0 ]; then
    PREVIEW_COMMAND='tree -L 2 -x --noreport --dirsfirst {}'
else
    PREVIEW_COMMAND='ls -1 -R {}'
fi

FZFZ_EXCLUDE_PATTERN=${FZFZ_EXCLUDE_PATTERN:="\/.git"}
FZFZ_UNIQUIFIER="awk '!seen[\$0]++'"

__fzfz() {
    if (($+FZFZ_EXCLUDE_PATTERN)); then
        EXCLUDER="egrep -v '$FZFZ_EXCLUDE_PATTERN'"
    else
        EXCLUDER="cat"
    fi

    # EXCLUDER is applied directly only to searches that need it (i.e. not
    # `z`). That improvements performance, and makes sure that the
    # FZFZ_SUBDIR_LIMIT is applied on the post-excluded list.

    if (($+FZFZ_EXTRA_DIRS)); then
        EXTRA_DIRS="{ find $FZFZ_EXTRA_DIRS -maxdepth 1 -type d 2> /dev/null | $EXCLUDER }"
    else
        EXTRA_DIRS="{ true }"
    fi

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
