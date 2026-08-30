# x-cmd-action/gitconfig

> 纯 shell 的**全局** git config 设置。不依赖 Node.js，不依赖 x-cmd。

[English](./README.md)

## 做什么

两种模式（互斥）：

1. **默认** —— 全局设置 `user.name` 和 `user.email`（默认是 `github-actions[bot]`，CI 常用身份）
2. **`config=<file>`** —— 把 `<file>` 的内容**整体复制**到 `~/.gitconfig`（覆盖式）

这个 step 跑完后，job 里所有 git 命令都看到这份 config（全局生效）。

## 用法

```yaml
steps:
  - uses: x-cmd-action/gitconfig@v1
    with:
      name: ci-bot
      email: ci@example.com
```

或者从 workflow 里的某份 `.gitconfig` 文件整体导入。约定：文件名用 `global.gitconfig`，放在 `.github/` 下，每个 workflow 仓库自带全局 git 配置：

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
```

任何 git config 格式都支持 —— `[include]`、条件 include（`[includeIf "gitdir:..."]`）、alias、签名配置等。文件内容通过 git 原生的 `[include]` 机制合并进 `~/.gitconfig`，保留你原有的全局设置。

| 给了哪些 input | 行为 |
| --- | --- |
| 三个都给 | 全局设置 name + email |
| 只给 `name` + `email` | 全局设置 name + email |
| 只给 `config` | 给 `~/.gitconfig` 加 `include.path = <file>`（**保留**现有设置）|
| 都不给 | no-op |

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
# lib/gitconfig.sh
if [ -n "$INPUT_CONFIG" ]; then
    cp "$INPUT_CONFIG" "$HOME/.gitconfig"
    chmod 600 "$HOME/.gitconfig"
    exit 0
fi
git config --global user.name "$INPUT_NAME"
git config --global user.email "$INPUT_EMAIL"
```

## 许可证

Apache 2.0 —— 见 [`LICENSE`](LICENSE)。

## 相关链接

- [`x-cmd-action/checkout`](../checkout) —— 有个 `gitconfig` input 是 **repo-scoped**（用 `[include]`）。给单个 checkout 设 config 时用它。
- [x-cmd/action](https://github.com/x-cmd/action) —— 这个逻辑原本内联在它里面。
- [x-cmd-action/.github](https://github.com/x-cmd-action/.github) —— org 主页 + 路线图