#!/usr/bin/env bash
# Bootstrap submodules from Chaos/Phyle.txt entries.
# For each line like "⚫️ Chaos" it:
#   - extracts the persona name (first alphanumeric token after the emoji),
#   - ensures a folder exists at repo root,
#   - initializes and pushes a public repo on GitHub via `gh`,
#   - converts the folder into a git submodule of the current repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/boilerplate.sh"

REPO_ROOT="$(git -C "$SCRIPT_DIR/.." rev-parse --show-toplevel)"
PHYLE_FILE="$SCRIPT_DIR/Phyle.txt"

if [[ ! -f "$PHYLE_FILE" ]]; then
  fail "Missing $PHYLE_FILE"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  fail "GitHub CLI (gh) is required."
  exit 1
fi

# Determine protocol preference (default to https)
GH_PROTOCOL="$(gh config get -h github.com git_protocol 2>/dev/null || echo https)"
info "Using git protocol: $GH_PROTOCOL"

# Determine GH owner (order: env -> gh auth -> origin URL owner -> git config github.user -> git config user.name -> prompt)
GH_OWNER="${GH_OWNER:-}"
if [[ -z "$GH_OWNER" ]]; then
  if gh auth status >/dev/null 2>&1; then
    GH_OWNER="$(gh auth status 2>/dev/null | awk '/github\\.com as/{print $NF; exit}')"
  else
    warn "gh auth status not available or not logged in; will try git config."
  fi
fi
if [[ -z "$GH_OWNER" ]]; then
  origin_url="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)"
  if [[ "$origin_url" =~ github.com[:/]+([^/]+)/[^/]+(.git)?$ ]]; then
    GH_OWNER="${BASH_REMATCH[1]}"
  fi
fi
if [[ -z "$GH_OWNER" ]]; then
  GH_OWNER="$(git config --global github.user 2>/dev/null || true)"
fi
if [[ -z "$GH_OWNER" ]]; then
  GH_OWNER="$(git config --global user.name 2>/dev/null | awk '{print $1}')"
fi
if [[ -z "$GH_OWNER" ]]; then
  read -rp "GitHub owner (user or org) to use for new repos: " GH_OWNER
fi
if [[ -z "$GH_OWNER" ]]; then
  fail "No GitHub owner provided."
  exit 1
fi
info "Using GitHub owner: $GH_OWNER"

while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip blanks or comments
  [[ -z "${line// }" ]] && { warn "Skipping blank line"; continue; }
  [[ "$line" =~ ^# ]] && { warn "Skipping comment: $line"; continue; }

  # Extract first capitalized token as persona name
  name="$(printf '%s\n' "$line" | awk '{for(i=1;i<=NF;i++){if($i ~ /^[A-Z][A-Za-z0-9._-]*$/){print $i; exit}}}')"
  [[ -z "$name" ]] && name="$(printf '%s\n' "$line" | awk '{print $1}')"

  if [[ -z "$name" ]]; then
    warn "Skipping unparsable line: $line"
    continue
  fi

  # Skip Chaos itself (root repo)
  if [[ "$name" == "Chaos" ]]; then
    warn "Skipping Chaos (handled by root repo)"
    continue
  fi

  info "Parsed entry: '$line' -> name='$name'"

  # Confirm before processing each entry (default Yes unless PHYLE_ASSUME_NO=1)
  default_choice="${PHYLE_ASSUME_NO:-0}"
  prompt_default=$([[ "$default_choice" -eq 1 ]] && echo "N" || echo "Y")
  if [[ -t 0 ]]; then
    read -rp "$(printf '[%s] process %s? [%s]: ' "$(basename "$0")" "$name" "$prompt_default")" confirm || true
  else
    confirm="$prompt_default"
  fi
  if [[ -z "$confirm" ]]; then
    confirm="$prompt_default"
  fi
  info "User choice for $name: $confirm"
  [[ "$confirm" =~ ^[Yy]$ ]] || { warn "Skipped $name"; continue; }

  path="$REPO_ROOT/$name"

  # If already a submodule, leave it alone
  if git -C "$REPO_ROOT" submodule status -- "$name" >/dev/null 2>&1; then
    info "Submodule already present: $name (skipping)"
    continue
  fi

  # Clean any leftover directory
  rm -rf "$path"

  if [[ "$GH_PROTOCOL" == "ssh" ]]; then
    remote_url="git@github.com:$GH_OWNER/$name.git"
  else
    remote_url="https://github.com/$GH_OWNER/$name.git"
  fi

  if ! gh repo view "$GH_OWNER/$name" >/dev/null 2>&1; then
    # Remote does not exist: create local seed repo, create remote, push
    mkdir -p "$path"
    (cd "$path" && git init -q
      : > README.md
      printf "# %s.Settings.md Settings version 1.0\n" "$name" > "${name}.Settings.md"
      git add README.md "${name}.Settings.md"
      git commit -qm "Initial commit")
    info "Initialized repo for $name with README and ${name}.Settings.md"

    info "Creating GitHub repo $GH_OWNER/$name (public)"
    (cd "$path" && gh repo create "$GH_OWNER/$name" --public --source=. --remote=origin --push)
  else
    info "Remote already exists: $GH_OWNER/$name; will add as submodule"
  fi

  # Clean any working copy before adding submodule
  rm -rf "$path"

  # Add as submodule pointing to remote
  git -C "$REPO_ROOT" submodule add -f "$remote_url" "$name"

  info "Submodule added: $name -> $remote_url"
done < "$PHYLE_FILE"
