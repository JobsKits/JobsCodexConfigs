# `Codex配置注入替换工具.command`

![Jobs倾情奉献](https://picsum.photos/1500/400 "Jobs出品，必属精品")

[toc]

---

## 🔥 <font id=前言>前言</font> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

> 这个脚本用于把工具包内指定账户的 `.codex` 配置注入到当前 Mac 用户的 `~/.codex`，并在替换完成后强制重启 [**Codex**](https://openai.com/codex)。

## 一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 你有多个 [**Codex**](https://openai.com/codex) 账户配置，需要一键切换当前机器的 `~/.codex`。
- 你希望每次切换后，都用工具包根目录的全局唯一 `AGENTS.md` 覆盖目标配置里的 `AGENTS.md`。
- 你希望已有 `~/.codex` 不被静默覆盖，而是先手动处理或压缩备份。
- 你希望来源 `.codex` 必须是真实配置，不能把空目录误注入到当前账户。

## 二、目录放置规则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 工具包根目录固定结构如下：

  ```text
  【MacOS】Codex配置注入替换工具包/
  ├── 替换脚本.command
  ├── AGENTS.md
  ├── codex配置文件夹/
  │   ├── A/
  │   │   └── .codex/
  │   ├── B/
  │   │   └── .codex/
  │   └── C/
  │       └── .codex/
  └── README.md
  ```

- `codex配置文件夹` 下每个账户一层目录，目录名就是 [**fzf**](https://formulae.brew.sh/formula/fzf) 菜单里显示的名字。
- 每个账户目录下面必须存在 `.codex` 文件夹，例如 `codex配置文件夹/A/.codex`。
- 这个压缩包里的 `A/.codex`、`B/.codex`、`C/.codex` 默认是空目录，你需要在本地按真实配置自行填充。
- 来源 `.codex` 不能为空；脚本会忽略 `.DS_Store`、`.localized` 这类 Finder 垃圾文件，不会把它们当成有效配置内容。

## 三、执行前检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 脚本会检查 [**Homebrew**](https://brew.sh/)。

  | 状态 | 处理方式 |
  | ---- | -------- |
  | 已安装 | 询问是否执行 `brew update && brew upgrade && brew cleanup && brew doctor && brew -v`。 |
  | 未安装 | 询问是否安装 [**Homebrew**](https://brew.sh/)；跳过则终止。 |

- 脚本会检查 [**fzf**](https://formulae.brew.sh/formula/fzf)。

  | 状态 | 处理方式 |
  | ---- | -------- |
  | 已安装 | 直接进入配置选择。 |
  | 未安装 | 询问是否执行 `brew install fzf`；跳过则终止。 |

- 脚本会检查 [**Codex**](https://openai.com/codex) 的两个 cask。

  ```shell
  brew install --cask codex-app
  brew install --cask codex
  ```

  | 状态 | 处理方式 |
  | ---- | -------- |
  | 已安装 | 询问是否执行 [**Codex**](https://openai.com/codex) 自检与升级。 |
  | 缺失任一 cask | 询问是否安装缺失项；跳过则终止。 |

- 脚本会检查来源 `.codex` 是否有效。

  | 状态 | 处理方式 |
  | ---- | -------- |
  | `.codex` 存在且非空 | 自检通过，继续处理目标 `~/.codex`。 |
  | `.codex` 不存在 | 打开账户目录或 `codex配置文件夹`，等待你修正后按回车复检。 |
  | `.codex` 是空目录 | 打开该 `.codex`，等待你放入真实配置后按回车复检。 |

## 四、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 双击运行：

  ```text
  替换脚本.command
  ```

- 终端运行：

  ```shell
  cd "【MacOS】Codex配置注入替换工具包"
  chmod +x "替换脚本.command"
  ./替换脚本.command
  ```

- 默认目标目录是当前用户的 `~/.codex`。如需临时指定目标目录，可用环境变量：

  ```shell
  TARGET_CODEX_DIR="/Users/jobs/.codex" ./替换脚本.command
  ```

## 五、执行流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 脚本会先显示本 `README.md`，按回车后继续。
- 通过 [**fzf**](https://formulae.brew.sh/formula/fzf) 选择要注入的 `.codex`，显示名取 `.codex` 上一层目录名，例如 `A`、`B`、`C`。
- 选中来源 `.codex` 后，脚本会先做来源自检：

  | 检查点 | 结果 |
  | ------ | ---- |
  | 目录存在 | 继续检查是否非空。 |
  | 目录不存在 | 不主动结束脚本，打开目录让你修正，按回车后重新自检。 |
  | 目录为空 | 不主动结束脚本，打开 `.codex` 让你补齐内容，按回车后重新自检。 |
  | 目录非空 | 进入目标 `~/.codex` 处理流程。 |

- 只要来源 `.codex` 没通过自检，脚本就会一直等待你修正并按回车复检；不会继续往下执行。
- 如果目标 `~/.codex` 已存在，会出现 [**fzf**](https://formulae.brew.sh/formula/fzf) 菜单：

  | 选项 | 行为 |
  | ---- | ---- |
  | `手动处理` | 暂停脚本，打开原 `~/.codex`，你手动删除或备份后回车继续检测。 |
  | `压缩备份处理` | 把原 `~/.codex` 压缩为 `~/.codex@YYYY.MM.DD HH：MM：SS.zip`，然后要求输入 `YES` 删除原目录，以创建干净注入环境。 |
  | `取消执行` | 退出脚本，不改动配置。 |

- 只有当目标目录下不存在 `.codex` 时，脚本才会继续注入。
- 注入后会用工具包根目录的 `AGENTS.md` 覆盖目标 `~/.codex/AGENTS.md`。
- 替换完成后会强制停止 [**Codex**](https://openai.com/codex) 进程，并尝试执行 `open -a Codex` 重启。

## 六、流程图 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 核心流程如下：

  ```mermaid
  flowchart TD
    A[显示 README.md] --> B[检查 Homebrew]
    B --> C[检查 fzf]
    C --> D[检查 Codex]
    D --> E[fzf 选择账户 .codex]
    E --> F{来源 .codex 是否存在且非空}
    F -- 否 --> G[打开来源目录并等待回车]
    G --> F
    F -- 是 --> H{目标 ~/.codex 是否存在}
    H -- 不存在 --> I[停止 Codex]
    H -- 存在 --> J[fzf 选择处理方式]
    J -- 手动处理 --> K[打开目标目录并等待]
    K --> H
    J -- 压缩备份处理 --> L[压缩备份]
    L --> M[输入 YES 删除原目录]
    M --> H
    I --> N[ditto 注入 .codex]
    N --> O[覆盖 AGENTS.md]
    O --> P[强制重启 Codex]
    P --> Q[输出日志路径]
  ```

## 七、风险说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 来源 `.codex` 为空时，脚本不会继续注入；你必须放入真实配置并回车复检。
- `压缩备份处理` 会在备份成功后删除原 `~/.codex`，但删除前必须输入 `YES`。
- 脚本不会静默覆盖已有 `~/.codex`。
- 脚本会强制停止进程名为 `Codex` 或 `codex` 的运行态，用于确保替换后配置重新加载。
- 工具包自带的 `A/.codex`、`B/.codex`、`C/.codex` 是占位空目录，直接运行会被来源自检拦住，这是正常行为。

## 八、日志文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 日志写入：

  ```text
  /tmp/替换脚本.log
  ```

## 九、常见问题 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 一直提示来源 `.codex` 为空怎么办？

  ```text
  把真实配置文件放进：codex配置文件夹/账户名/.codex
  只放 .DS_Store、.localized 不算有效配置。
  放好以后回到终端按回车，脚本会重新自检。
  ```

- 找不到配置怎么办？

  ```text
  确认目录是：codex配置文件夹/账户名/.codex
  注意 .codex 是隐藏目录，Finder 里可以按 Command + Shift + . 显示隐藏文件。
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
