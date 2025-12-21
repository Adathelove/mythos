#!/usr/bin/env bash
# Create mailbox directories for all personas and wire anybox symlinks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/boilerplate.sh"

REPO_ROOT="$(git -C "$SCRIPT_DIR/.." rev-parse --show-toplevel)"
PHYLE_FILE="$SCRIPT_DIR/Phyle.txt"
MAILBOX_ROOT="$REPO_ROOT/Mailbox"

if [[ ! -f "$PHYLE_FILE" ]]; then
  fail "Missing $PHYLE_FILE"
  exit 1
fi

mkdir -p "$MAILBOX_ROOT"

# Collect persona names (including Chaos)
personas=()
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "${line// }" ]] && continue
  [[ "$line" =~ ^# ]] && continue
  name="$(printf '%s\n' "$line" | awk '{for(i=1;i<=NF;i++){if($i ~ /^[A-Z][A-Za-z0-9._-]*$/){print $i; exit}}}')"
  [[ -z "$name" ]] && name="$(printf '%s\n' "$line" | awk '{print $1}')"
  [[ -z "$name" ]] && { warn "Skipping unparsable line: $line"; continue; }
  personas+=("$name")
done < "$PHYLE_FILE"

info "Personas detected: ${personas[*]}"

create_dirs() {
  local persona="$1"
  local base="$MAILBOX_ROOT/$persona"
  mkdir -p "$base/inbox" "$base/outbox" "$base/anybox"
  info "Ensured inbox/outbox/anybox for $persona"
}

wire_anybox() {
  local persona="$1"
  local base="$MAILBOX_ROOT/$persona/anybox"
  for target in "${personas[@]}"; do
    [[ "$target" == "$persona" ]] && continue
    local link_path="$base/$target"
    local target_path="../$target/inbox"
    if [[ -L "$link_path" ]]; then
      info "Anybox link exists for $persona -> $target"
      continue
    fi
    if [[ -e "$link_path" ]]; then
      warn "Anybox entry exists but is not a symlink: $link_path (skipping)"
      continue
    fi
    ln -s "$target_path" "$link_path"
    info "Linked $link_path -> $target_path"
  done
}

for p in "${personas[@]}"; do
  create_dirs "$p"
done

for p in "${personas[@]}"; do
  wire_anybox "$p"
done
