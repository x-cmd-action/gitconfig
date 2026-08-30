# x-cmd-action/gitconfig

> 纯 shell 的**全局** git config 设置。不依赖 Node.js，不依赖 x-cmd。

[English](./README.md)

## 做什么

三个可选 input，各自独立可自由组合：

- **`name`** —— `git config --global user.name`
- **`email`** —— `git config --global user.email`
- **`config`** —— 给 `~/.gitconfig` 加 `[include] path = <file>`，保留现有设置（通过 git 原生 include 机制合并）

其他配置（hooks、签名、alias 等）都通过 `config:` 指向一个 `.gitconfig` 文件，用 git 原生 config 语法表达。

这个 step 跑完后，job 里所有 git 命令都看到这份 config（全局生效）。

## 用法

### 1. 设 CI 身份

```yaml
- uses: x-cmd-action/gitconfig@v1
    with:
      name: ci-bot
      email: ci@example.com
```

省略 `name` / `email` 时，应用合理的 CI 默认（`github-actions[bot]`）。

### 2. 整体 include 一份 .gitconfig 文件

```yaml
- uses: x-cmd-action/gitconfig@v1
    with:
      config: .github/global.gitconfig
```

约定：文件名用 `global.gitconfig`，放在 `.github/` 下，每个 workflow 仓库自带全局 git 配置。任何 git 格式的配置都支持 —— alias、签名、`[includeIf "gitdir:..."]`、（Git 2.54+）内联 hooks。

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

; 内联 hooks —— Git 2.54+（2026/5）。替代 core.hooksPath + 脚本文件。
[hook "pre-commit-lint"]
    event = pre-commit
    command = ./node_modules/.bin/eslint --fix-dry-run

[hook "commit-msg-sign"]
    event = commit-msg
    command = ./scripts/sign-commit-msg.sh
```

设了 `config` 后，`name` / `email` 跳过（include 的文件是 authoritative）。

### 3. 组合

```yaml
- uses: x-cmd-action/gitconfig@v1
    with:
      name: ci-bot
      email: ci@example.com
      config: .github/global.gitconfig
```

## Git 2.54+ 提示：内联 hooks via `[hook "name"]` stanzas

2.54 之前（旧方式）：

```bash
# 提交一个目录的可执行脚本，让 git 指向它
git config --global core.hooksPath .github/hooks
# .github/hooks/pre-commit、.github/hooks/commit-msg 等
```

2.54+（2026/5 新方式）：

```ini
# 在任何 git config 文件里直接定义 hooks —— 不用脚本文件。
[hook "pre-commit-lint"]
    event = pre-commit
    command = ./node_modules/.bin/eslint --fix-dry-run

[hook "commit-msg-sign"]
    event = commit-msg
    command = ./scripts/sign-commit-msg.sh
```

内联 hooks 写在 `~/.gitconfig`（或任何 included 文件）里。支持同一 event 多个 hooks。为向后兼容，旧 `.git/hooks/` 脚本仍然最后跑。

`x-cmd-action/gitconfig` 不需要单独的 hooks input —— 全部走 `config:` 文件。

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