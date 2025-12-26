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

parse_persona_line() {
  bann "${FUNCNAME[0]}"
  local line="$1"
  persona_emoji="$(printf '%s\n' "$line" | awk '{print $1}')"
  persona_name="$(printf '%s\n' "$line" | awk '{for(i=1;i<=NF;i++){if($i ~ /^[A-Z][A-Za-z0-9._-]*$/){print $i; exit}}}')"
  if [[ -z "$persona_name" ]]; then
    fail "Could not extract persona name from line: $line"
    exit 1
  fi
}

ensure_log_dir() {
  bann "${FUNCNAME[0]}"
  local dir="$1"
  if [[ -d "$dir" ]]; then
    return 0
  fi
  if [[ -e "$dir" && ! -d "$dir" ]]; then
    warn "$dir exists but is not a directory; skipping log dir creation"
    return 1
  fi
  mkdir -p "$dir"
  info "Created $dir"
}

next_version_for_today() {
  local persona="$1"
  local logdir="$2"
  local dow mon day
  dow="$(date '+%a')"
  mon="$(date '+%b')"
  day="$(date '+%d')"
  local max_v=0
  shopt -s nullglob
  for f in "$logdir"/${persona}_${dow}_${mon}_${day}_v*; do
    local base
    base="$(basename "$f")"
    if [[ "$base" =~ _v([0-9]+) ]]; then
      local v="${BASH_REMATCH[1]}"
      if (( v > max_v )); then
        max_v="$v"
      fi
    fi
  done
  shopt -u nullglob
  echo $((max_v + 1))
}

seed_log_stub() {
  local path="$1"
  local persona="$2"
  local emoji="$3"
  local version="$4"
  if [[ -f "$path" ]]; then
    info "Log stub already present: $path"
    echo "$path"
    return 0
  fi
  {
    printf "# %s %s %s v%s\n\n" "$emoji" "$persona" "$(date '+%a %b %d')" "$version"
    printf "_Created by spawn-persona.sh to mark version %s for %s._\n" "$version" "$persona"
  } > "$path"
  echo "$path"
}

build_label() {
  bann "${FUNCNAME[0]}"
  local emoji="$1"
  local name="$2"
  local version="$3"
  local date_str
  date_str="$(date '+%a %b %d')"
  persona_label="$emoji $name $date_str v$version"
}

confirm_and_launch() {
  bann "${FUNCNAME[0]}"
  local label="$1"
  local stub_path="$2"
  local persona="$3"
  local emoji="$4"
  local version="$5"
  local launch_prompt
  launch_prompt="$label"
  # Set working dir to repo root so personas can write to shared paths (Mailbox, etc.)
  cmd=(codex -C "$REPO_ROOT" --search --full-auto "$launch_prompt")
  warn "About to run: ${cmd[*]}"
  if ask_yesno_default_no "Proceed"; then
    seed_log_stub "$stub_path" "$persona" "$emoji" "$version" >/dev/null
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
  parse_persona_line "$selected_line"
  persona_dir="$REPO_ROOT/$persona_name"
  if [[ ! -d "$persona_dir" ]]; then
    fail "Persona directory missing: $persona_dir"
    exit 1
  fi
  log_dir="$persona_dir/DailyLogs"
  ensure_log_dir "$log_dir"
  next_version="$(next_version_for_today "$persona_name" "$log_dir")"
  date_slug="$(date '+%a_%b_%d')"
  log_stub_path="$log_dir/${persona_name}_${date_slug}_v${next_version}__startup.md"
  build_label "$persona_emoji" "$persona_name" "$next_version"
  info "Next version: v$next_version"
  info "Startup stub (on launch): $log_stub_path"
  info "Using persona label: $persona_label"
  confirm_and_launch "$persona_label" "$log_stub_path" "$persona_name" "$persona_emoji" "$next_version"
}

main "$@"
