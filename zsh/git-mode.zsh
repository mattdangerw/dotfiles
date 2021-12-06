function git-mode-rm()
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

function git-mode-mv()
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

function git-mode-alias()
{
  _git_mode_commands+=($1)
  alias "$1"="$2"
}

function git-mode-alias-all()
{
  git-mode-unalias-all
  for cmd in $(git --list-cmds=main); do
    alias=$cmd
    if which $alias >/dev/null; then
      # avoid collisions in builtins and unix commands by prefixing with "g"
      # e.g. git grep -> ggrep
      alias="g$alias"
      if which "$alias" >/dev/null; then
        # if another collion, give up
        continue
      fi
    fi
    git-mode-alias "$alias" "git $cmd"
  done
  for cmd in $(git --list-cmds=alias); do
    # don't avoid collisions with aliases, we control these and can choose names
    # as we please
    git-mode-alias "$cmd" "git $cmd"
  done
  git-mode-alias 'mv' 'git-mode-mv'
  git-mode-alias 'rm' 'git-mode-rm'
}

function git-mode-unalias-all()
{
  for cmd in $_git_mode_commands; do
    unalias "$cmd"
  done
  _git_mode_commands=()
}

function git-mode-list()
{
  for cmd in $_git_mode_commands; do
    which "$cmd"
  done
}

# toggle git mode or run a single command with git
function git-mode-toggle()
{
  if [ "$#" -eq 0 ]; then
    if [ $GIT_MODE ]; then
      unset GIT_MODE
      unset VCS_MODE_TOKEN
      git-mode-unalias-all
    else
      export GIT_MODE=true
      export VCS_MODE_TOKEN='gm'
      git-mode-alias-all
    fi
  else
    git $@
  fi
}

if [ $GIT_MODE ]; then
  git-mode-alias-all
fi
