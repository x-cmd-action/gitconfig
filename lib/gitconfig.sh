#!/usr/bin/env bash
# x-cmd-action/gitconfig — pure-shell implementation.
# Two modes (mutually exclusive: config wins):
#   1. config=<file>   — copy that file to ~/.gitconfig, skip name/email
#   2. no config input  — set user.name and user.email globally

set -euo errexit

# Mode 1: copy a full .gitconfig file.
if [ -n "$INPUT_CONFIG" ]; then
    if [ ! -f "$INPUT_CONFIG" ]; then
        echo "ERROR: config file not found: $INPUT_CONFIG" >&2
        exit 1
    fi
    cp "$INPUT_CONFIG" "$HOME/.gitconfig"
    chmod 600 "$HOME/.gitconfig"
    echo "gitconfig: copied $INPUT_CONFIG -> ~/.gitconfig"
    exit 0
fi

# Mode 2: set name/email globally. Both inputs default to safe values
# from action.yml, so we always set them unless explicitly cleared.
if [ -n "$INPUT_NAME" ]; then
    git config --global user.name "$INPUT_NAME"
    echo "gitconfig: user.name=$INPUT_NAME"
fi

if [ -n "$INPUT_EMAIL" ]; then
    git config --global user.email "$INPUT_EMAIL"
    echo "gitconfig: user.email=$INPUT_EMAIL"
fi