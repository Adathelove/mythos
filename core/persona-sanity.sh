#!/usr/bin/env bash
# Sanity checker to align shared persona assets (mailboxes, shared helpers/symlinks).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR/.." rev-parse --show-toplevel)"
PHYLE_FILE="$REPO_ROOT/Chaos/Phyle.txt"
MAILBOX_SYNC="$REPO_ROOT/Chaos/mailbox-sync.sh"
SEND_HELPER="$REPO_ROOT/core/mailbox-send.sh"
SPAWN_HELPER="$REPO_ROOT/core/spawn-persona.sh"
GENERICS_DIR="$REPO_ROOT/Generics"
MAILBOX_ROOT="$REPO_ROOT/Mailbox"

# Fallback logging if Chaos/boilerplate.sh missing
if [[ -f "$REPO_ROOT/Chaos/boilerplate.sh" ]]; then
  # shellcheck source=/dev/null
  source "$REPO_ROOT/Chaos/boilerplate.sh"
else
  info(){ printf '[Info] %s\n' "$*"; }
  warn(){ printf '[Warn] %s\n' "$*"; }
  fail(){ printf '[Fail] %s\n' "$*"; }
fi

if [[ ! -f "$PHYLE_FILE" ]]; then
  fail "Missing $PHYLE_FILE"; exit 1; fi

if [[ ! -x "$SEND_HELPER" ]]; then
  chmod +x "$SEND_HELPER" || true
  info "Ensured executable: $SEND_HELPER"
fi
if [[ ! -x "$SPAWN_HELPER" ]]; then
  chmod +x "$SPAWN_HELPER" || true
  info "Ensured executable: $SPAWN_HELPER"
fi

# Run mailbox sync if available
if [[ -x "$MAILBOX_SYNC" ]]; then
  "$MAILBOX_SYNC"
else
  warn "Mailbox sync script missing at $MAILBOX_SYNC; skipping mailbox alignment"
fi

# Build persona list
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

# Ensure symlinks for shared helpers in each persona (if directory exists)
for p in "${personas[@]}"; do
  persona_dir="$REPO_ROOT/$p"
  [[ -d "$persona_dir" ]] || { warn "$p directory missing at $persona_dir"; continue; }
  # mailbox-send
  link_path="$persona_dir/mailbox-send.sh"
  target_rel="../core/mailbox-send.sh"
  if [[ -L "$link_path" ]]; then
    : # ok
  elif [[ -e "$link_path" ]]; then
    warn "$link_path exists (not symlink); leaving as-is"
  else
    ln -s "$target_rel" "$link_path"
    info "Linked $link_path -> $target_rel"
  fi
  # spawn-persona
  spawn_link="$persona_dir/spawn-persona.sh"
  spawn_target_rel="../core/spawn-persona.sh"
  if [[ -L "$spawn_link" ]]; then
    : # ok
  elif [[ -e "$spawn_link" ]]; then
    warn "$spawn_link exists (not symlink); leaving as-is"
  else
    ln -s "$spawn_target_rel" "$spawn_link"
    info "Linked $spawn_link -> $spawn_target_rel"
  fi

  # Mailbox symlink to keep writes within persona path
  mbox_link="$persona_dir/Mailbox"
  mbox_target_rel="../Mailbox"
  if [[ -L "$mbox_link" ]]; then
    : # ok
  elif [[ -e "$mbox_link" ]]; then
    warn "$mbox_link exists (not symlink); leaving as-is"
  else
    if [[ -d "$MAILBOX_ROOT" ]]; then
      ln -s "$mbox_target_rel" "$mbox_link"
      info "Linked $mbox_link -> $mbox_target_rel"
    else
      warn "Mailbox dir missing at $MAILBOX_ROOT; cannot link for $p"
    fi
  fi

  # Generics symlink
  gen_link="$persona_dir/Generics"
  gen_target_rel="../Generics"
  if [[ -L "$gen_link" ]]; then
    : # ok
  elif [[ -e "$gen_link" ]]; then
    warn "$gen_link exists (not symlink); leaving as-is"
  else
    if [[ -d "$GENERICS_DIR" ]]; then
      ln -s "$gen_target_rel" "$gen_link"
      info "Linked $gen_link -> $gen_target_rel"
    else
      warn "Generics dir missing at $GENERICS_DIR; cannot link for $p"
    fi
  fi

  # Ensure persona DailyLogs directory exists (per Persona.Modes expectations)
  dlogs_dir="$persona_dir/DailyLogs"
  if [[ -d "$dlogs_dir" ]]; then
    : # ok
  elif [[ -e "$dlogs_dir" ]]; then
    warn "$dlogs_dir exists but is not a directory; leaving as-is"
  else
    mkdir -p "$dlogs_dir"
    info "Created $dlogs_dir"
  fi

done

info "Sanity check complete"
