function rm_git_mode()
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

function mv_git_mode()
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

function alias_git_mode()
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
  alias mv="mv_git_mode"
  alias rm="rm_git_mode"
}

function unalias_git_mode()
{
  for word in $_git_mode_commands; do
    unalias "$word"
  done
  unalias mv
  unalias rm
}

# toggle git mode or run a single command with git
function g()
{
  if [ "$#" -eq 0 ]; then
    if [ $GIT_MODE ]; then
      unset GIT_MODE
      unalias_git_mode
    else
      export GIT_MODE=true
      alias_git_mode
    fi
  else
    git $@
  fi
}
if [ $GIT_MODE ]; then
  alias_git_mode
fi
