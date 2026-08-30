#!/usr/bin/env bash
# x-cmd-action/gitconfig — pure-shell implementation.
# Two modes (mutually exclusive: config wins):
#   1. config=<file>   — copy that file to ~/.gitconfig, skip name/email
#   2. no config input  — set user.name and user.email globally

set -euo errexit

# Mode 1: include a .gitconfig file via git's native [include] mechanism.
# Adds 'include.path = <file>' to ~/.gitconfig — the existing global
# config is preserved (merge, not wholesale replace). Git reads the
# included file's values when looking up keys globally. This is also
# where Git 2.54+ inline [hook "name"] stanzas go.
if [ -n "$INPUT_CONFIG" ]; then
    if [ ! -f "$INPUT_CONFIG" ]; then
        echo "ERROR: config file not found: $INPUT_CONFIG" >&2
        exit 1
    fi
    git config --global include.path "$INPUT_CONFIG"
    echo "gitconfig: include.path=$INPUT_CONFIG (added to ~/.gitconfig)"
    exit 0
fi

# Mode 2: set individual keys globally. Each is opt-in.
# - user.name / user.email have safe CI defaults from action.yml.
# - hooks-path sets core.hooksPath for pre-2.54 / script-based hooks.

if [ -n "$INPUT_HOOKS_PATH" ]; then
    if [ ! -d "$INPUT_HOOKS_PATH" ]; then
        echo "ERROR: hooks-path not a directory: $INPUT_HOOKS_PATH" >&2
        exit 1
    fi
    git config --global core.hooksPath "$INPUT_HOOKS_PATH"
    echo "gitconfig: core.hooksPath=$INPUT_HOOKS_PATH"
fi

if [ -n "$INPUT_NAME" ]; then
    git config --global user.name "$INPUT_NAME"
    echo "gitconfig: user.name=$INPUT_NAME"
fi

if [ -n "$INPUT_EMAIL" ]; then
    git config --global user.email "$INPUT_EMAIL"
    echo "gitconfig: user.email=$INPUT_EMAIL"
fi