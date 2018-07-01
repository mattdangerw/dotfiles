function rm-git-mode()
{
  if git rev-parse --git-dir > /dev/null 2>&1; then
    local output
    output=`git rm $@ 2>&1`
    local ret="$?"
    if [ $ret -ne 128 ]; then
      echo $output
      return $ret
    fi
  fi
  command rm "$@"
}

function mv-git-mode()
{
  if git rev-parse --git-dir > /dev/null 2>&1; then
    local output
    output=`git mv $@ 2>&1`
    local ret="$?"
    if [ $ret -ne 128 ]; then
      echo $output
      return $ret
    fi
  fi
  command mv "$@"
}

function alias-git-mode()
{
  local aliases="$(git config --get-regexp '^alias.' | sed s/alias.// | awk '{print $1}')"
  local git_builtins="add apply blame branch checkout cherry cherry-pick clean \
    clone commit config describe diff fetch format-patch gc grep help init log merge \
    prune pull push rebase reflog remote reset revert show stash status tag"
  _git_mode_commands=(${(ps:\n:)${aliases}} ${(ps: :)${git_builtins}})
  if which hub >/dev/null; then
    local hub_builtins="create browse compare fork pull-request ci-status"
    _git_mode_commands+=(${(ps: :)${hub_builtins}})
  fi
  for word in $_git_mode_commands; do
    alias "$word"="git $word"
  done
  alias mv="mv-git-mode"
  alias rm="rm-git-mode"
}

function unalias-git-mode()
{
  for word in $_git_mode_commands; do
    unalias "$word"
  done
  unalias mv
  unalias rm
}

# toggle git mode or run a single command with git
function toggle-git-mode()
{
  if [ "$#" -eq 0 ]; then
    if [ $GIT_MODE ]; then
      unset GIT_MODE
      unset VCS_MODE_TOKEN
      unalias-git-mode
    else
      export GIT_MODE=true
      export VCS_MODE_TOKEN='gm'
      alias-git-mode
    fi
  else
    git $@
  fi
}

if [ $GIT_MODE ]; then
  alias-git-mode
fi
