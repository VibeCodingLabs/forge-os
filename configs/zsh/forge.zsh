# ForgeOS aliases and shell helpers
alias ll='eza -lah --group-directories-first 2>/dev/null || ls -lah'
alias la='ls -A'
alias gs='git status --short --branch'
alias gl='git log --oneline --decorate --graph -20'
alias ports='ss -tulpn'
alias c='clear'
alias path='echo $PATH | tr : "\n"'
alias disk='df -h && du -h -d 1 "$HOME" 2>/dev/null | sort -h | tail -25'
alias mem='free -h'
alias forge='cd "$HOME/forge-os"'
alias forgehome='cd "$FORGE_HOME"'
alias forge-tui='command forge-tui'
alias rich-demo='forge-rich-demo'

mkcd(){ mkdir -p "$1" && cd "$1"; }
serve(){ python3 -m http.server "${1:-8000}"; }
extract(){
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1";; *.tar.gz) tar xzf "$1";; *.bz2) bunzip2 "$1";; *.rar) unrar x "$1";;
      *.gz) gunzip "$1";; *.tar) tar xf "$1";; *.tbz2) tar xjf "$1";; *.tgz) tar xzf "$1";;
      *.zip) unzip "$1";; *.Z) uncompress "$1";; *.7z) 7z x "$1";; *) echo "cannot extract $1";;
    esac
  else
    echo "$1 is not a file"
  fi
}

forge-health(){
  echo "== ForgeOS Health =="
  uname -a
  df -h /
  free -h
  systemctl --user list-timers 'forge-*' 2>/dev/null || true
}
