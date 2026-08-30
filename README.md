# x-cmd-action/gitconfig

> Pure-shell **global** git config setup. No Node.js, no x-cmd needed.

[中文文档](./README.cn.md)

## What it does

Three optional inputs that compose freely:

- **`name`** — `git config --global user.name`
- **`email`** — `git config --global user.email`
- **`config`** — adds an `[include] path = <file>` to `~/.gitconfig`. Existing settings are preserved (merge via git's native include mechanism).

Anything else (hooks, signing, aliases, etc.) goes through `config:` — point it at a `.gitconfig` file that uses Git's native config syntax.

After this step runs, subsequent git commands in the job see the applied config globally.

## Usage

### 1. Set CI identity

```yaml
- uses: x-cmd-action/gitconfig@v1
    with:
      name: ci-bot
      email: ci@example.com
```

If `name` / `email` are omitted, sensible CI defaults (`github-actions[bot]`) are applied.

### 2. Include a full .gitconfig file

```yaml
- uses: x-cmd-action/gitconfig@v1
    with:
      config: .github/global.gitconfig
```

Convention: name the file `global.gitconfig` and check it into `.github/` so each workflow repo ships its own global git config. Anything git-format is supported — aliases, signing, `[includeIf "gitdir:..."]`, and (on Git 2.54+) inline hooks.

`.github/global.gitconfig`:

```ini
[user]
    name = ci-bot
    email = ci@example.com

[commit]
    gpgsign = true

[gpg "format:ssh"]
    program = /path/to/ssh-keygen-wrapper

[alias]
    co = checkout

; Inline hooks — Git 2.54+ (May 2026). Replaces core.hooksPath + script files.
[hook "pre-commit-lint"]
    event = pre-commit
    command = ./node_modules/.bin/eslint --fix-dry-run

[hook "commit-msg-sign"]
    event = commit-msg
    command = ./scripts/sign-commit-msg.sh
```

When `config` is set, `name` / `email` are skipped (the included file is authoritative).

### 3. Combine

```yaml
- uses: x-cmd-action/gitconfig@v1
    with:
      name: ci-bot
      email: ci@example.com
      config: .github/global.gitconfig
```

## Git 2.54+ note: inline hooks via `[hook "name"]` stanzas

Pre-2.54 (the old way):

```bash
# Ship a directory of executable scripts; point git at it
git config --global core.hooksPath .github/hooks
# .github/hooks/pre-commit, .github/hooks/commit-msg, etc.
```

2.54+ (the new way, May 2026):

```ini
# Define hooks inline in any git config file — no script files needed.
[hook "pre-commit-lint"]
    event = pre-commit
    command = ./node_modules/.bin/eslint --fix-dry-run

[hook "commit-msg-sign"]
    event = commit-msg
    command = ./scripts/sign-commit-msg.sh
```

Inline hooks live in `~/.gitconfig` (or any included file). Multiple hooks per event supported. Legacy `.git/hooks/` scripts still run last for backward compatibility.

`x-cmd-action/gitconfig` doesn't need a separate input for hooks — just put them in the `config:` file.

## Scope

This action writes to the **runner's `~/.gitconfig`** — applies to every git command in the job, every repo. If you want config that applies **only to a specific checkout**, use `x-cmd-action/checkout`'s `gitconfig` input instead (it uses `[include]` to scope the file to one repo).

| Want | Use |
| --- | --- |
| Config for one specific repo | `x-cmd-action/checkout`'s `gitconfig` input |
| Config for the whole job (all repos, all commands) | `x-cmd-action/gitconfig` (this) |

## How it's wired

```yaml
# action.yml (excerpt)
runs:
  using: composite
  steps:
    - shell: bash
      env:
        INPUT_NAME: ${{ inputs.name }}
        INPUT_EMAIL: ${{ inputs.email }}
        INPUT_CONFIG: ${{ inputs.config }}
      run: bash ${{ github.action_path }}/lib/gitconfig.sh
```

```bash
# lib/gitconfig.sh (simplified)
if [ -n "$INPUT_CONFIG" ]; then
    git config --global include.path "$INPUT_CONFIG"
    exit 0
fi
[ -n "$INPUT_NAME"  ] && git config --global user.name  "$INPUT_NAME"
[ -n "$INPUT_EMAIL" ] && git config --global user.email "$INPUT_EMAIL"
```

## License

Apache 2.0 — see [`LICENSE`](LICENSE).

## Related

- [`x-cmd-action/checkout`](../checkout) — has a `gitconfig` input that is **repo-scoped** (via `[include]`). Use when you want config for one checkout only.
- [x-cmd/action](https://github.com/x-cmd/action) — the parent that historically had this logic inline.
- [x-cmd-action/.github](https://github.com/x-cmd-action/.github) — org profile + roadmap.
- [Git 2.54 release notes](https://www.dsebastien.net/git-2-54-config-based-hooks-replace-husky-and-pre-commit) — config-based hooks stanzas.