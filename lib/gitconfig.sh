#!/usr/bin/env bash
# x-cmd-action/gitconfig — pure-shell implementation.
# Global scope only: writes to ~/.gitconfig. Position-independent.
#
# Inputs (any subset may be combined):
#   config=<file>    → add [include] path to ~/.gitconfig (merges with existing)
#   hooks-path=<dir> → git config --global core.hooksPath <dir>
#   name=<str>       → git config --global user.name <str>
#   email=<str>      → git config --global user.email <str>
#
# Precedence:
#   When config is set, name / email / hooks-path are skipped (the included
#   file is authoritative for global scope).
#
# For repo-scoped config, use the `local-config` input on
# `x-cmd-action/checkout` or `x-cmd-action/this-repo` instead — those
# write to a specific repo's .git/config (which would implicitly depend
# on cwd if it lived here).

set -euo errexit

if [ -n "$INPUT_CONFIG" ]; then
    if [ ! -f "$INPUT_CONFIG" ]; then
        echo "ERROR: config file not found: $INPUT_CONFIG" >&2
        exit 1
    fi
    git config --global include.path "$INPUT_CONFIG"
    echo "gitconfig: include.path=$INPUT_CONFIG (added to ~/.gitconfig)"
    exit 0
fi

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
