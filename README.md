# x-cmd-action/gitconfig

> Pure-shell **global** git config setup. No Node.js, no x-cmd needed.

[中文文档](./README.cn.md)

## What it does

Two modes (mutually exclusive):

1. **Default** — set `user.name` and `user.email` globally (with sensible CI defaults: `github-actions[bot]`).
2. **`config=<file>`** — replace `~/.gitconfig` with the contents of `<file>` (wholesale copy).

After this step runs, subsequent git commands in the job see the applied config globally.

## Usage

```yaml
steps:
  - uses: x-cmd-action/gitconfig@v1
    with:
      name: ci-bot
      email: ci@example.com
```

Or copy a full `.gitconfig` from a path in your workflow:

```yaml
- uses: x-cmd-action/gitconfig@v1
  with:
    config: .github/.gitconfig
```

| Input set | Behavior |
| --- | --- |
| All three | name + email set globally |
| Just `name` + `email` | name + email set globally |
| Just `config` | file copied to `~/.gitconfig` (overrides name/email) |
| Nothing | no-op |

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
# lib/gitconfig.sh
if [ -n "$INPUT_CONFIG" ]; then
    cp "$INPUT_CONFIG" "$HOME/.gitconfig"
    chmod 600 "$HOME/.gitconfig"
    exit 0
fi
git config --global user.name "$INPUT_NAME"
git config --global user.email "$INPUT_EMAIL"
```

## License

Apache 2.0 — see [`LICENSE`](LICENSE).

## Related

- [`x-cmd-action/checkout`](../checkout) — has a `gitconfig` input that is **repo-scoped** (via `[include]`). Use when you want config for one checkout only.
- [x-cmd/action](https://github.com/x-cmd/action) — the parent that historically had this logic inline.
- [x-cmd-action/.github](https://github.com/x-cmd-action/.github) — org profile + roadmap.