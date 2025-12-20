#!/usr/bin/env bash
# Launch Codex as a given persona for today, using name/emoji from Phyle.txt.
# Usage: bash Chaos/spawn-persona.sh [persona_name_or_emoji]
# Example: bash Chaos/spawn-persona.sh Chaos
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/boilerplate.sh"
PHYLE_FILE="$SCRIPT_DIR/Phyle.txt"

if [[ ! -f "$PHYLE_FILE" ]]; then
  fail "Phyle.txt not found at $PHYLE_FILE"
  exit 1
fi

requested="${1:-}"

need_fzf=false
if [[ -z "$requested" ]] && [[ -t 0 ]]; then
  need_fzf=true
fi

install_hint() {
  os="$(uname -s)"
  if [[ "$os" == "Darwin" ]]; then
    warn "Install fzf on macOS: brew install fzf && /opt/homebrew/opt/fzf/install (if prompted)"
  else
    # Linux: try common package managers
    if command -v apt >/dev/null 2>&1; then
      warn "Install fzf on Debian/Ubuntu: sudo apt update && sudo apt install fzf"
    elif command -v dnf >/dev/null 2>&1; then
      warn "Install fzf on Fedora: sudo dnf install fzf"
    elif command -v yum >/dev/null 2>&1; then
      warn "Install fzf on RHEL/CentOS: sudo yum install fzf"
    elif command -v pacman >/dev/null 2>&1; then
      warn "Install fzf on Arch: sudo pacman -S fzf"
    else
      warn "Install fzf via your package manager or https://github.com/junegunn/fzf#installation"
    fi
  fi
}

if $need_fzf && ! command -v fzf >/dev/null 2>&1; then
  fail "fzf is required to choose a persona interactively."
  install_hint
  exit 1
fi

info "Loading personas from $PHYLE_FILE"
mapfile -t phyle_lines < <(grep -v '^\s*$' "$PHYLE_FILE" | grep -v '^#')

selected_line=""
if [[ -n "$requested" ]]; then
  info "Looking for persona matching: $requested"
  for line in "${phyle_lines[@]}"; do
    if [[ "$line" == *"$requested"* ]]; then
      selected_line="$line"
      break
    fi
  done
else
  info "Prompting for persona via fzf"
  selected_line="$(printf '%s\n' "${phyle_lines[@]}" | fzf --prompt='Pick persona> ')"
fi

if [[ -z "$selected_line" ]]; then
  fail "No persona selected."
  exit 1
fi

emoji="$(printf '%s\n' "$selected_line" | awk '{print $1}')"
name="$(printf '%s\n' "$selected_line" | awk '{for(i=1;i<=NF;i++){if($i ~ /^[A-Z][A-Za-z0-9._-]*$/){print $i; exit}}}')"

if [[ -z "$name" ]]; then
  fail "Could not extract persona name from line: $selected_line"
  exit 1
fi

date_str="$(date '+%a %b %d')"
persona_label="$emoji $name $date_str"

cmd=(codex --search --full-auto --name "$persona_label")
warn "About to run: ${cmd[*]}"
read -rp "Proceed? [y/N]: " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { warn "Aborted."; exit 0; }

info "Launching Codex as: $persona_label"
"${cmd[@]}"
