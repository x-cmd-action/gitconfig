# x-cmd-action/gitconfig

> Pure-shell **global** git config setup. No Node.js, no x-cmd needed.

[中文文档](./README.cn.md)

## What it does

Four optional inputs that compose freely:

- **`name`** — `git config --global user.name`
- **`email`** — `git config --global user.email`
- **`hooks-path`** — `git config --global core.hooksPath <dir>`. Compatibility option for pre-2.54 Git or script-based hooks.
- **`config`** — adds an `[include] path = <file>` to `~/.gitconfig`. Existing settings are preserved (merge via git's native include mechanism). Use this for `[hook "name"]` stanzas on Git 2.54+, aliases, signing, etc.

After this step runs, subsequent git commands in the job see the applied config globally. When `config` is set, `name` / `email` / `hooks-path` are skipped (the file is authoritative).

## Usage

### 1. Set CI identity

```yaml
- uses: x-cmd-action/gitconfig@v1
  with:
    name: ci-bot
    email: ci@example.com
```

If `name` / `email` are omitted, sensible CI defaults (`github-actions[bot]`) are applied.

### 2. Hooks via script directory (any Git version)

```yaml
- uses: x-cmd-action/gitconfig@v1
  with:
    hooks-path: .github/hooks
```

`core.hooksPath` is set globally, so any subsequent `git` command in the job runs the hooks in `.github/hooks/`. Use this on pre-2.54 Git or when you have existing executable scripts (e.g., legacy husky setup).

`.github/hooks/pre-commit`:

```bash
#!/usr/bin/env bash
./node_modules/.bin/eslint --fix-dry-run
```

### 3. Hooks via inline `[hook "name"]` stanzas (Git 2.54+)

```yaml
- uses: x-cmd-action/gitconfig@v1
  with:
    config: .github/global.gitconfig
```

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

; Git 2.54+ (May 2026) — define hooks inline, no script files needed
[hook "pre-commit-lint"]
    event = pre-commit
    command = ./node_modules/.bin/eslint --fix-dry-run

[hook "commit-msg-sign"]
    event = commit-msg
    command = ./scripts/sign-commit-msg.sh
```

When `config` is set, `name` / `email` / `hooks-path` are skipped.

### 4. Combine

```yaml
- uses: x-cmd-action/gitconfig@v1
  with:
    name: ci-bot
    email: ci@example.com
    config: .github/global.gitconfig
```

## Hooks: choose your style

Two equivalent mechanisms for "give me custom git hooks in CI":

| Mechanism | Best when | Git version |
| --- | --- | --- |
| `hooks-path: <dir>` (this action's input) | existing script-based hooks, husky-style, anything older | Any |
| `[hook "name"]` stanzas in `config:` file | new setup, want version-controlled hooks next to the code, prefer declarative | Git 2.54+ (May 2026) |

The action supports both. Pick one based on your git version and team preference.

## Scope

This action writes to the **runner's `~/.gitconfig`** — applies to every git command in the job, every repo. If you want config that applies **only to a specific checkout**, use `x-cmd-action/checkout` (or `x-cmd-action/this-repo`) with its `local-config` input instead — that writes `[include]` to **one repo's** `.git/config`.

| Want | Use |
| --- | --- |
| Config for one specific repo | `x-cmd-action/checkout` / `x-cmd-action/this-repo`'s `local-config` input |
| Config for the whole job (all repos, all commands) | `x-cmd-action/gitconfig` (this) |

## License

Apache 2.0 — see [`LICENSE`](LICENSE).

## Related

- [`x-cmd-action/checkout`](https://github.com/x-cmd-action/checkout) — has a `local-config` input that is **repo-scoped** (via `[include]`). Use when you want config for one checkout only.
- [`x-cmd-action/this-repo`](https://github.com/x-cmd-action/this-repo) — minimal "current repo only" checkout, also has `local-config`.
- [x-cmd/action](https://github.com/x-cmd/action) — the parent that historically had this logic inline.
- [x-cmd-action/.github](https://github.com/x-cmd-action/.github) — org profile + roadmap.
- [Git 2.54 release notes](https://www.dsebastien.net/git-2-54-config-based-hooks-replace-husky-and-pre-commit) — config-based hooks stanzas.
