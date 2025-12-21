#!/usr/bin/env bash
# Launch Codex as a persona. Works from repo root or inside a persona directory.
# Usage:
#   ./core/spawn-persona.sh [persona_or_emoji]
#   (from a persona dir) ./spawn-persona.sh   # auto-selects that persona
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR/.." rev-parse --show-toplevel)"

# Prefer Chaos boilerplate for consistent logging
if [[ -f "$REPO_ROOT/Chaos/boilerplate.sh" ]]; then
  source "$REPO_ROOT/Chaos/boilerplate.sh"
else
  info(){ printf '[Info] %s\n' "$*"; }
  warn(){ printf '[Warn] %s\n' "$*"; }
  fail(){ printf '[Fail] %s\n' "$*"; }
fi

PHYLE_FILE="$REPO_ROOT/Chaos/Phyle.txt"

bann() {
  local fn="${1:-}"
  local width="${BANN_WIDTH:-66}"
  [[ -z "$fn" ]] && return 0
  local base="=== ${fn} ==="
  local pad=$(( width - ${#base} ))
  (( pad < 0 )) && pad=0
  local left=$(( pad / 2 ))
  local right=$(( pad - left ))
  local lfill rfill
  printf -v lfill "%*s" "$left" ""
  printf -v rfill "%*s" "$right" ""
  lfill="${lfill// /=}"
  rfill="${rfill// /=}"
  info "${lfill}${base}${rfill}"
}

install_hint() {
  bann "${FUNCNAME[0]}"
  os="$(uname -s)"
  if [[ "$os" == "Darwin" ]]; then
    warn "Install fzf on macOS: brew install fzf && /opt/homebrew/opt/fzf/install (if prompted)"
  else
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

ask_yesno_default_no() {
  bann "${FUNCNAME[0]}"
  local prompt="$1"
  local ans
  read -rp "$prompt [y/N]: " ans
  case "${ans,,}" in
    y|yes) return 0 ;;
    *)     return 1 ;;
  esac
}

load_personas() {
  bann "${FUNCNAME[0]}"
  if [[ ! -f "$PHYLE_FILE" ]]; then
    fail "Phyle.txt not found at $PHYLE_FILE"
    exit 1
  fi
  mapfile -t phyle_lines < <(grep -v '^\s*$' "$PHYLE_FILE" | grep -v '^#')
  mapfile -t phyle_names < <(printf '%s\n' "${phyle_lines[@]}" | awk '{for(i=1;i<=NF;i++){if($i ~ /^[A-Z][A-Za-z0-9._-]*$/){print $i; break}}}')
  info "phyle_names: ${phyle_names[*]}"
}

detect_persona_from_cwd() {
  bann "${FUNCNAME[0]}"
  local cwd
  cwd="$(pwd -P)"
  info "cwd (resolved): $cwd"
  info "repo root:       $REPO_ROOT"
  DETECTED_CWD=""
  for p in "${phyle_names[@]}"; do
    local prefix="$REPO_ROOT/$p"
    info "checking prefix: $prefix"
    if [[ "$cwd" == "$prefix" || "$cwd" == "$prefix"* ]]; then
      info "Detected persona context from cwd: $p (matched prefix $prefix)"
      DETECTED_CWD="$p"
      return 0
    fi
  done
  info "No persona detected from cwd"
  return 1
}

select_persona() {
  bann "${FUNCNAME[0]}"
  local requested="$1"
  local selected_line=""
  if [[ -n "$requested" ]]; then
    info "Looking for persona matching: $requested"
    for line in "${phyle_lines[@]}"; do
      if [[ "$line" == *"$requested"* ]]; then
        selected_line="$line"
        break
      fi
    done
    if [[ -z "$selected_line" ]]; then
      fail "Persona '$requested' not found in Phyle.txt"
      exit 1
    fi
  else
    if ! command -v fzf >/dev/null 2>&1; then
      fail "fzf is required to choose a persona interactively."
      install_hint
      exit 1
    fi
    info "Prompting for persona via fzf"
    selected_line="$(printf '%s\n' "${phyle_lines[@]}" | fzf --prompt='Pick persona> ')"
  fi

  if [[ -z "$selected_line" ]]; then
    fail "No persona selected."
    exit 1
  fi
  echo "$selected_line"
}

build_label() {
  bann "${FUNCNAME[0]}"
  local line="$1"
  emoji="$(printf '%s\n' "$line" | awk '{print $1}')"
  name="$(printf '%s\n' "$line" | awk '{for(i=1;i<=NF;i++){if($i ~ /^[A-Z][A-Za-z0-9._-]*$/){print $i; exit}}}')"
  if [[ -z "$name" ]]; then
    fail "Could not extract persona name from line: $line"
    exit 1
  fi
  date_str="$(date '+%a %b %d')"
  persona_label="$emoji $name $date_str"
}

confirm_and_launch() {
  bann "${FUNCNAME[0]}"
  local label="$1"
  cmd=(codex --search --full-auto "$label")
  warn "About to run: codex --search --full-auto \"$label\""
  if ask_yesno_default_no "Proceed"; then
    info "Launching Codex as: $label"
    "${cmd[@]}"
  else
    warn "Aborted."
    exit 0
  fi
}

main() {
  bann "main"
  requested="${1:-}"
  info "requested arg: ${requested:-<empty>}"
  load_personas
  if [[ -z "$requested" ]]; then
    if detect_persona_from_cwd; then
      requested="$DETECTED_CWD"
    fi
  fi
  info "requested after detection: ${requested:-<empty>}"
  # capture only the last line (selection) to avoid mixing with banner logs
  selected_line="$(select_persona "$requested" | tail -n 1)"
  build_label "$selected_line"
  confirm_and_launch "$persona_label"
}

main "$@"
