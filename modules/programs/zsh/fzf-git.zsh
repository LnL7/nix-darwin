__fzf_is_git__() {
  git rev-parse HEAD > /dev/null 2>&1
}

__fzfcmd_down() {
  fzf --height 50% "$@" --border
}

fzf-gitf() {
  __fzf_is_git__ || return
  git -c color.status=always status --short |
  __fzfcmd_down -m --ansi --nth 2..,.. \
    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
  cut -c4- | sed 's/.* -> //'
}

fzf-gitb() {
  __fzf_is_git__ || return
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  __fzfcmd_down --ansi --multi --tac --preview-window right:70% \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

fzf-gitt() {
  __fzf_is_git__ || return
  git tag --sort -version:refname |
  __fzfcmd_down --multi --preview-window right:70% \
    --preview 'git show --color=always {} | head -'$LINES
}

fzf-gith() {
  __fzf_is_git__ || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  __fzfcmd_down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always | head -'$LINES |
  grep -o "[a-f0-9]\{7,\}"
}

fzf-gitr() {
  __fzf_is_git__ || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  __fzfcmd_down --tac \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1} | head -200' |
  cut -d$'\t' -f1
}

join-lines() {
  local item
  while read item; do
    echo -n "${(q)item} "
  done
}

bind-git-helper() {
  local char
  for c in $@; do
    eval "fzf-git$c-widget() { local result=\$(fzf-git$c | join-lines); zle reset-prompt; LBUFFER+=\$result }"
    eval "zle -N fzf-git$c-widget"
    eval "bindkey '^g$c' fzf-git$c-widget"
  done
}

bind-git-helper f b t r h
unset -f bind-git-helper
