#!/usr/bin/env bash

# ---- Standard Colors and Messages ----
GREEN="$(tput setaf 2)"
RED="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
RESET="$(tput sgr0)"

info()  { echo "${GREEN}[Info]${RESET} $*"; }
warn()  { echo "${YELLOW}[Warn]${RESET} $*"; }
fail()  { echo "${RED}[Fail]${RESET} $*"; }
abort() { echo "${RED}[Abort]${RESET} $*"; }
