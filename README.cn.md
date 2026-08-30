# x-cmd-action/gitconfig

> 纯 shell 的**全局** git config 设置。不依赖 Node.js，不依赖 x-cmd。

[English](./README.md)

## 做什么

四个可选 input，各自独立可自由组合：

- **`name`** —— `git config --global user.name`
- **`email`** —— `git config --global user.email`
- **`hooks-path`** —— `git config --global core.hooksPath <dir>`。兼容选项，用于 2.54 之前的 Git 或基于脚本的 hooks。
- **`config`** —— 给 `~/.gitconfig` 加 `[include] path = <file>`，保留现有设置（git 原生 include 机制合并）。2.54+ 时的 `[hook "name"]` stanzas、alias、签名等用这个。

这个 step 跑完后，job 里所有 git 命令都看到这份 config（全局生效）。设了 `config` 后，`name` / `email` / `hooks-path` 都跳过（include 的文件是 authoritative）。

## 用法

### 1. 设 CI 身份

```yaml
- uses: x-cmd-action/gitconfig@v1
    with:
      name: ci-bot
      email: ci@example.com
```

省略 `name` / `email` 时，应用合理的 CI 默认（`github-actions[bot]`）。

### 2. 通过脚本目录设 hooks（任何 Git 版本）

```yaml
- uses: x-cmd-action/gitconfig@v1
    with:
      hooks-path: .github/hooks
```

`core.hooksPath` 全局设好，job 里后续任何 `git` 命令都用 `.github/hooks/` 里的 hooks。2.54 之前的 Git 或已有的可执行脚本（legacy husky 等）用这种。

`.github/hooks/pre-commit`：

```bash
#!/usr/bin/env bash
./node_modules/.bin/eslint --fix-dry-run
```

### 3. 通过内联 `[hook "name"]` stanzas 设 hooks（Git 2.54+）

```yaml
- uses: x-cmd-action/gitconfig@v1
    with:
      config: .github/global.gitconfig
```

`.github/global.gitconfig`：

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

; Git 2.54+（2026/5）—— 内联定义 hooks，不用脚本文件
[hook "pre-commit-lint"]
    event = pre-commit
    command = ./node_modules/.bin/eslint --fix-dry-run

[hook "commit-msg-sign"]
    event = commit-msg
    command = ./scripts/sign-commit-msg.sh
```

设了 `config` 后，`name` / `email` / `hooks-path` 跳过。

### 4. 组合

```yaml
- uses: x-cmd-action/gitconfig@v1
    with:
      name: ci-bot
      email: ci@example.com
      config: .github/global.gitconfig
```

## Hooks：两种方式选一

| 机制 | 适用场景 | Git 版本 |
| --- | --- | --- |
| `hooks-path: <dir>`（这个 action 的 input）| 已有基于脚本的 hooks、husky 风格、任何旧版 | 任意 |
| `config:` 文件里的 `[hook "name"]` stanzas | 新搭建、想跟代码一起 version control、偏好声明式 | Git 2.54+（2026/5）|

action 同时支持两种。按 git 版本和团队偏好选一个。

## 作用域

这个 action 写的是 **runner 的 `~/.gitconfig`** —— 对 job 里所有 git 命令、所有 repo 生效。如果只想给**某一个 checkout** 设 config，用 `x-cmd-action/checkout` 的 `gitconfig` input（用 `[include]` 把文件 scope 到那个 repo）。

| 需求 | 用 |
| --- | --- |
| 只给一个特定 repo 设 config | `x-cmd-action/checkout` 的 `gitconfig` input |
| 给整个 job 设 config（所有 repo、所有命令）| `x-cmd-action/gitconfig`（本 action） |

## 接线方式

```yaml
# action.yml（节选）
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
# lib/gitconfig.sh（简化）
if [ -n "$INPUT_CONFIG" ]; then
    git config --global include.path "$INPUT_CONFIG"
    exit 0
fi
[ -n "$INPUT_NAME"  ] && git config --global user.name  "$INPUT_NAME"
[ -n "$INPUT_EMAIL" ] && git config --global user.email "$INPUT_EMAIL"
```

## 许可证

Apache 2.0 —— 见 [`LICENSE`](LICENSE)。

## 相关链接

- [`x-cmd-action/checkout`](../checkout) —— 有个 `gitconfig` input 是 **repo-scoped**（用 `[include]`）。给单个 checkout 设 config 时用它。
- [x-cmd/action](https://github.com/x-cmd/action) —— 这个逻辑原本内联在它里面。
- [x-cmd-action/.github](https://github.com/x-cmd-action/.github) —— org 主页 + 路线图
- [Git 2.54 release notes](https://www.dsebastien.net/git-2-54-config-based-hooks-replace-husky-and-pre-commit) —— config-based hooks stanzas