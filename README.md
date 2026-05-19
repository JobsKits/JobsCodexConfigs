# `Codex配置注入替换工具.command`

![Jobs倾情奉献](https://picsum.photos/1500/400 "Jobs出品，必属精品")

[toc]

---

## 🔥 <font id=前言>前言</font> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

> 这个脚本用于把工具包内指定账户的 `.codex` 配置注入到当前 Mac 用户的 `~/.codex`，并在替换完成后强制重启 [**Codex**](https://openai.com/codex)。

## 一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 有多个 [**Codex**](https://openai.com/codex) 账户配置，需要一键切换当前机器的 `~/.codex`
- 期望每次切换后，都用工具包根目录的全局唯一 `AGENTS.md` 覆盖目标配置里的 `AGENTS.md`
- 期望已有 `~/.codex` 不被静默覆盖，而是先手动处理或压缩备份
- 期望来源配置必须是真实内容，不能把空目录、空压缩包或合并失败的子卷误注入到当前账户
- 期望把体积较大的 `.codex` 压缩并拆成 对[**Github**](https://github.com) 友好的子卷后，注入脚本仍能自动临时合并、解压、注入

## 二、目录放置规则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 工具包根目录固定结构如下：

  ```text
  【MacOS】Codex配置注入替换工具包/
  ├── 【MacOS】Codex配置注入替换工具.command
  ├── AGENTS.md
  ├── codex配置文件夹/
  │   ├── lg295060456@gmail.com/
  │   │   └── .codex/
  │   ├── tokenlb.net/
  │   │   └── .codex/
  │   ├── A/
  │   │   └── .codex/
  │   ├── B/
  │   │   └── .codex/
  │   └── C/
  │       └── .codex/
  ├── 【MacOS】文件分拆（合并）command/
  │   ├── 【MacOS】✂️源文件压缩拆分➤子卷.command
  │   ├── 【MacOS】🧩子卷➤合而为一源文件.command
  │   └── README.md
  └── README.md
  ```

- `codex配置文件夹` 下每个账户一层目录，目录名就是 [**fzf**](https://formulae.brew.sh/formula/fzf) 菜单里显示的名字。
- 每个账户目录支持四种来源格式：

  | 来源格式 | 处理方式 |
  | -------- | -------- |
  | `codex配置文件夹/账户名/.codex/` | 原始配置目录，非空后直接注入。 |
  | `codex配置文件夹/账户名/.codex.zip` | 单个压缩包，脚本会解压到临时目录再注入。 |
  | `codex配置文件夹/账户名/.codex/.codex.zip@001of003 ...` | 拆分子卷目录，脚本会临时合并为 `.codex.zip`、解压后再注入。 |
  | `codex配置文件夹/账户名/.codex.zip@001of003 ...` | 子卷直接放在账户目录，脚本会临时合并为 `.codex.zip`、解压后再注入。 |

- 这个压缩包里的账户目录默认是空占位，你需要在本地按真实配置自行填充。
- 来源目录不能为空；脚本会忽略 `.DS_Store`、`.localized`、`.gitkeep` 这类占位或 Finder 垃圾文件，不会把它们当成有效配置内容。
- 子卷命名必须符合拆分脚本的输出规则，例如 `.codex.zip@001of003`、`.codex.zip@002of003`、`.codex.zip@003of003`。

## 三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 脚本会检查 [**Homebrew**](https://brew.sh/)

  | 状态 | 处理方式 |
  | ---- | -------- |
  | 已安装 | 询问是否执行 `brew update && brew upgrade && brew cleanup && brew doctor && brew -v`。 |
  | 未安装 | 询问是否安装 [**Homebrew**](https://brew.sh/)；跳过则终止。 |

- 脚本会检查 [**fzf**](https://formulae.brew.sh/formula/fzf)

  | 状态 | 处理方式 |
  | ---- | -------- |
  | 已安装 | 直接进入配置选择。 |
  | 未安装 | 询问是否执行 `brew install fzf`；跳过则终止。 |

- 脚本会检查 [**Codex**](https://openai.com/codex) 的两个 cask

  ```shell
  brew install --cask codex-app
  brew install --cask codex
  ```

  | 状态 | 处理方式 |
  | ---- | -------- |
  | 已安装 | 询问是否执行 [**Codex**](https://openai.com/codex) 自检与升级。 |
  | 缺失任一 cask | 询问是否安装缺失项；跳过则终止。 |

- 脚本会检查来源账户目录是否有效

  | 状态 | 处理方式 |
  | ---- | -------- |
  | 账户目录非空，且能识别为 `.codex`、`.codex.zip` 或拆分子卷 | 自检通过，继续准备注入来源。 |
  | 账户目录为空 | 打开账户目录，等待你修正后按回车复检。 |
  | 账户目录非空但格式不支持 | 打开账户目录，提示支持格式，等待你修正后按回车复检。 |

## 四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 双击运行：

  ```text
  【MacOS】Codex配置注入替换工具.command
  ```

- 终端运行：

  ```shell
  cd "【MacOS】Codex配置注入替换工具包"
  chmod +x "【MacOS】Codex配置注入替换工具.command"
  ./"【MacOS】Codex配置注入替换工具.command"
  ```

- 默认目标目录是当前用户的 `~/.codex`。如需临时指定目标目录，可用环境变量：

  ```shell
  TARGET_CODEX_DIR="/Users/jobs/.codex" ./"【MacOS】Codex配置注入替换工具.command"
  ```

## 五、执行流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 脚本会先显示本 `README.md`，按回车后继续。
- 通过 [**fzf**](https://formulae.brew.sh/formula/fzf) 选择要注入的账户目录，显示名取 `codex配置文件夹` 下面的一级目录名，例如 `lg295060456@gmail.com`、`tokenlb.net`、`A`。
- 选中账户目录后，脚本会先做来源自检：

  | 检查点 | 结果 |
  | ------ | ---- |
  | 账户目录存在且非空 | 继续识别来源格式。 |
  | 账户目录为空 | 不主动结束脚本，打开账户目录让你修正，按回车后重新自检。 |
  | 账户目录非空但格式不支持 | 不主动结束脚本，输出支持格式并等待回车复检。 |

- 如果来源是拆分子卷，脚本会创建 `/tmp/codex_inject_merge.XXXXXX` 临时目录，并调用：

  ```text
  【MacOS】文件分拆（合并）command/【MacOS】🧩子卷➤合而为一源文件.command
  ```

- 子卷合并成功后，脚本会校验合并结果必须是非空 `zip` 文件；合并失败、结果为空、结果不是 `zip`，都会立即报错并停止，不会进入注入流程
- 如果来源是 `.codex.zip`，脚本会解压到 `/tmp/codex_inject_unzip.XXXXXX` 临时目录；解压失败或解压后为空，会立即停止
- 临时目录只服务本次任务，脚本结束、失败或被中断时会自动删除
- 如果目标 `~/.codex` 已存在，会出现 [**fzf**](https://formulae.brew.sh/formula/fzf) 菜单：

  | 选项 | 行为 |
  | ---- | ---- |
  | `手动处理` | 暂停脚本，打开原 `~/.codex`，你手动删除或备份后回车继续检测。 |
  | `压缩备份处理` | 把原 `~/.codex` 压缩为 `~/.codex@YYYY.MM.DD HH：MM：SS.zip`，然后要求输入 `YES` 删除原目录，以创建干净注入环境。 |
  | `取消执行` | 退出脚本，不改动配置。 |

- 只有当目标目录下不存在 `.codex` 时，脚本才会继续注入
- 注入后会用工具包根目录的 `AGENTS.md` 覆盖目标 `~/.codex/AGENTS.md`
- 替换完成后会强制停止 [**Codex**](https://openai.com/codex) 进程，并尝试执行 `open -a Codex` 重启

## 六、流程图 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 核心流程如下：

  ```mermaid
  flowchart TD
    A[显示 README.md] --> B[检查 Homebrew]
    B --> C[检查 fzf]
    C --> D[检查 Codex]
    D --> E[fzf 选择账户目录]
    E --> F{来源账户是否非空且格式有效}
    F -- 否 --> G[打开账户目录并等待回车]
    G --> F
    F -- 是 --> H{来源类型}
    H -- 原始 .codex --> I[直接准备注入来源]
    H -- .codex.zip --> J[临时解压 zip]
    H -- 拆分子卷 --> K[临时合并子卷]
    K --> L{合并是否成功且为 zip}
    L -- 否 --> M[报错并停止]
    L -- 是 --> J
    J --> N{解压后 .codex 是否非空}
    N -- 否 --> M
    N -- 是 --> O{目标 ~/.codex 是否存在}
    I --> O
    O -- 不存在 --> P[停止 Codex]
    O -- 存在 --> Q[fzf 选择处理方式]
    Q -- 手动处理 --> R[打开目标目录并等待]
    R --> O
    Q -- 压缩备份处理 --> S[压缩备份]
    S --> T[输入 YES 删除原目录]
    T --> O
    P --> U[ditto 注入 .codex]
    U --> V[覆盖 AGENTS.md]
    V --> W[强制重启 Codex]
    W --> X[删除临时目录并输出日志路径]
  ```

## 七、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 来源账户目录为空时，脚本不会继续注入；你必须放入真实配置并回车复检。
- 拆分子卷合并失败时，脚本会立即停止，不会碰目标 `~/.codex`。
- `.codex.zip` 解压失败或解压后为空时，脚本会立即停止，不会碰目标 `~/.codex`。
- `压缩备份处理` 会在备份成功后删除原 `~/.codex`，但删除前必须输入 `YES`。
- 脚本不会静默覆盖已有 `~/.codex`。
- 脚本会强制停止进程名为 `Codex` 或 `codex` 的运行态，用于确保替换后配置重新加载。
- 工具包自带的账户目录是占位空目录，直接运行会被来源自检拦住，这是正常行为。

## 八、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 主脚本日志写入：

  ```text
  /tmp/【MacOS】Codex配置注入替换工具.log
  ```

- 子卷合并脚本日志写入：

  ```text
  /tmp/【MacOS】🧩子卷➤合而为一源文件.log
  ```

## 九、常见问题 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 一直提示来源账户目录为空怎么办？

  ```text
  把真实配置放进：codex配置文件夹/账户名/
  支持 .codex、.codex.zip、拆分子卷三种主要形态。
  只放 .DS_Store、.localized、.gitkeep 不算有效配置。
  放好以后回到终端按回车，脚本会重新自检。
  ```

- 子卷放哪里最稳？

  ```text
  推荐放在：codex配置文件夹/账户名/.codex/
  示例：
  codex配置文件夹/lg295060456@gmail.com/.codex/.codex.zip@001of003
  codex配置文件夹/lg295060456@gmail.com/.codex/.codex.zip@002of003
  codex配置文件夹/lg295060456@gmail.com/.codex/.codex.zip@003of003
  ```

- 单个 `.codex.zip` 可以直接放吗？

  ```text
  可以。放在：codex配置文件夹/账户名/.codex.zip
  脚本会自动解压到临时目录，再把解压后的 .codex 注入到目标位置。
  ```

- [**fzf**](https://formulae.brew.sh/formula/fzf) 菜单没出来怎么办？

  ```shell
  brew install fzf
  ```

- [**Codex**](https://openai.com/codex) 没有成功启动怎么办？

  ```shell
  open -a Codex
  ```

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
