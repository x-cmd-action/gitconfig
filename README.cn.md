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

这个 action 写的是 **runner 的 `~/.gitconfig`** —— 对 job 里所有 git 命令、所有 repo 生效。如果只想给**某一个 checkout** 设 config，用 `x-cmd-action/checkout` 或 `x-cmd-action/this-repo` 的 `local-config` input（往**那个 repo 的** `.git/config` 写 `[include]`）。

| 需求 | 用 |
| --- | --- |
| 只给一个特定 repo 设 config | `x-cmd-action/checkout` / `x-cmd-action/this-repo` 的 `local-config` input |
| 给整个 job 设 config（所有 repo、所有命令）| `x-cmd-action/gitconfig`（本 action） |

## 许可证

Apache 2.0 —— 见 [`LICENSE`](LICENSE)。

## FAQ

### 为什么这个 action 没有 `local-config` input？

`local-config` 写到**某个 repo 的** `.git/config` —— 这意味着它隐式依赖 cwd（具体哪个 repo）。这种耦合应该归到**知道自己在 checkout 哪个 repo 的** action（`x-cmd-action/checkout`、`x-cmd-action/this-repo`），而不是归到写 `~/.gitconfig` 的全局 config action（后者应该是位置无关的）。

具体说：本 action 只写 `~/.gitconfig`。它应该不管 `$GITHUB_WORKSPACE` 下有没有 repo、是什么 repo 都表现一致。如果在这里加 `local-config`，调用方就得：

- 在 `$GITHUB_WORKSPACE` 下有个 git repo（否则 action fail）
- 知道 include 要指向哪个 repo

这两件事 checkout action 本来就躲不掉 —— 所以 `local-config` 放那。

如果要给某个 checkout 加 repo-scoped config：

```yaml
- uses: x-cmd-action/checkout@v1   # 或 x-cmd-action/this-repo@v1
  with:
    local-config: .github/repo.gitconfig
```

include 的文件值叠在 `~/.gitconfig` 之上（git `--local > --global` 优先级），所以可以在文件里写 `[user] name = ...` 给该 repo 单独换 identity。

## 相关链接

- [`x-cmd-action/checkout`](https://github.com/x-cmd-action/checkout) —— 有个 `local-config` input 是 **repo-scoped**（用 `[include]`）。给单个 checkout 设 config 时用它。
- [`x-cmd-action/this-repo`](https://github.com/x-cmd-action/this-repo) —— 最简"只 checkout 当前 repo"版本，同样有 `local-config`。
- [x-cmd/action](https://github.com/x-cmd/action) —— 这个逻辑原本内联在它里面。
- [x-cmd-action/.github](https://github.com/x-cmd-action/.github) —— org 主页 + 路线图
- [Git 2.54 release notes](https://www.dsebastien.net/git-2-54-config-based-hooks-replace-husky-and-pre-commit) —— config-based hooks stanzas
