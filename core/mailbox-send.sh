#!/usr/bin/env bash
# Write a message into a persona inbox with a simple YAML-ish header.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR/.." rev-parse --show-toplevel)"

# Prefer Chaos boilerplate for consistent logging
if [[ -f "$REPO_ROOT/Chaos/boilerplate.sh" ]]; then
  # shellcheck source=/dev/null
  source "$REPO_ROOT/Chaos/boilerplate.sh"
else
  info(){ printf '[Info] %s\n' "$*"; }
  warn(){ printf '[Warn] %s\n' "$*"; }
fi

PHYLE_FILE="$REPO_ROOT/Chaos/Phyle.txt"

# Prefer a Mailbox directory in the current working directory (e.g., persona-local symlink)
if [[ -d "$PWD/Mailbox" ]]; then
  MAILBOX_ROOT="$PWD/Mailbox"
else
  MAILBOX_ROOT="$REPO_ROOT/Mailbox"
fi

usage() {
  cat <<'EOF'
Usage: mailbox-send.sh -t <to> -s <subject-slug> [-f <from>] [-b <bodyfile>]
Creates Mailbox/<to>/inbox/<subject>.new.msg with header+body.
Body: from stdin by default, or -b file.
EOF
}

from="${FROM:-Chaos}"
to=""
subject=""
bodyfile=""

while getopts "t:s:f:b:h" opt; do
  case "$opt" in
    t) to="$OPTARG" ;;
    s) subject="$OPTARG" ;;
    f) from="$OPTARG" ;;
    b) bodyfile="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

[[ -z "$to" || -z "$subject" ]] && { usage; exit 1; }

# Validate recipient exists in Phyle
if ! grep -qE "\\b${to}\\b" "$PHYLE_FILE"; then
  warn "Recipient $to not in Phyle.txt; proceeding but check spelling."
fi

inbox="$MAILBOX_ROOT/$to/inbox"
mkdir -p "$inbox"

msg_path="$inbox/${subject}.new.msg"
created="$(date +%Y-%m-%d)"

{
  echo "from: $from"
  echo "to: $to"
  echo "subject: $subject"
  echo "status: new"
  echo "created: $created"
  echo "updated: $created"
  echo "---"
  if [[ -n "$bodyfile" ]]; then
    cat "$bodyfile"
  else
    cat
  fi
} > "$msg_path"

info "Wrote $msg_path"
