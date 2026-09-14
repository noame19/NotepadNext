# 设计文档：移植 KDE Kate 的 Breeze 配色方案到 NotepadNext

| 项目 | 值 |
|---|---|
| 日期 | 2026-09-14 |
| 作者 | noame19 + Codex |
| 状态 | 草稿（待用户审核） |
| 关联 PR | 上游 PR #1040 (aniro/dark-mode-rework) |
| 关联配色源 | KDE/syntax-highlighting `data/themes/breeze-{dark,light}.theme` |
| 关联 issue | 用户反馈："看着字体颜色不太舒服" |

## 1. 目标

把 KDE Kate 编辑器的 **Breeze Dark** 和 **Breeze Light** 配色方案移植到 NotepadNext，让所有 87 种语言的语法高亮都用上设计师调校过的配色：

- **暗色模式** 下语言不再有"彩色背景块"（亮青色/浅米黄/浅薄荷绿等），看着更舒服
- **浅色模式** 同步对齐设计师调校的视觉效果
- 关键字**不再涂蓝色**，改用默认色 + 加粗（与 VS Code 默认主题「Quiet Light」、Breeze 同一设计哲学）
- 编辑器本身的颜色（背景、行号、当前行、选中区）也同步换成 Breeze 的

## 2. 背景

当前 NotepadNext 的暗色模式（来自 PR #1040）有个根本问题：**用「自动翻译」机制处理 87 个语言文件**——只把"纯黑 0x000000"和"纯白 0xFFFFFF"换成暗色友好的色，其他颜色原封不动。结果就是：

- Shell 的 `PARAM` 样式背景是 `#00FFFF`（亮青色），暗色模式下还是亮青色——刺眼
- Shell 的 `SCALAR` 背景是 `#FFFFD9`（浅米黄），暗色模式下还是浅米黄——扎眼
- Shell 的 `BACKTICKS` 背景是 `#E1FFF3`（浅薄荷绿）——同样刺眼
- 这些都是「带彩色背景」的样式，自动翻译机制不处理它们

Kate 的 Breeze 配色由 KDE 设计师专门调校，没有这些视觉噪音，整体看着舒服得多。

## 3. 范围

### 3.1 要做的事

| 类别 | 内容 |
|---|---|
| 编辑器 UI 颜色 | 背景、行号、当前行、选中区、缩进线、代码折叠线 → 换成 Breeze Dark/Light 的值 |
| 语法高亮颜色 | 所有 87 种语言的「功能分类」颜色 → 用 Breeze 的 text-styles |
| 智能映射 | 在 init.lua 里写关键词匹配规则，把 NotepadNext 现有样式名自动归类到 Kate 的 text-style |
| 双模式支持 | 暗色 + 浅色都改，深浅模式都生效 |
| 背景色策略 | 几乎所有 `bgColor` 删掉（除少数功能性），只保留 `fgColor` |
| 编译验证 | 通过 GitHub Actions（`linux-appimage.yml`）重新打包 AppImage |

### 3.2 不做的事

| 类别 | 原因 |
|---|---|
| 不重写 87 个语言文件 | 工作量大、风险大；改 init.lua 里的映射规则更稳 |
| 不支持自定义主题切换 UI | 用户没要求；当前主题选择保持 "Follow system / Light / Dark" 三态 |
| 不改 Kate 不支持的样式 | 比如 `Whitespace`（空白字符点）的颜色按现有逻辑 |
| 不改 Kate 的 CSV/TSV 特殊列色 | NotepadNext 没有 CSV 概念 |
| 不动窗体/菜单/工具栏的 Qt 控件调色板 | 那是 `MainWindow::applyStyleSheet()` 的 QPalette 范畴，已经在 PR #1040 里处理好了，这次不动 |

## 4. 关键设计决策（已与用户确认）

| # | 决策点 | 选择 | 理由 |
|---|---|---|---|
| 1 | 浅色模式一起改吗？ | **一起改** | 用户决定，保证双模式一致 |
| 2 | 保留带背景色的样式吗？ | **全部清掉**（除少数功能性） | 这是 Breeze 看着舒服的根本原因 |
| 3 | 关键字怎么处理？ | **默认色 + 加粗**（跟 Kate 一致） | 避免一片蓝的视觉疲劳 |
| 4 | 怎么映射？ | **智能关键词匹配** | 改动量小，长期可维护 |
| 5 | 编辑器整体颜色？ | **一起换 Breeze 的** | 全套移植保持一致 |

## 5. 配色映射表（Breeze → NotepadNext）

### 5.1 text-styles（语法高亮核心 8 类）

| 类别 | 中文意思 | Breeze Dark | Breeze Light | 字体属性 |
|---|---|---|---|---|
| Keyword | 关键字 | `#cfcfc2` | `#1f1c1b` | **加粗** |
| ControlFlow | 控制流（if/for/while） | `#fdbc4b` | `#1f1c1b` | **加粗** |
| Function | 函数名 | `#8e44ad` | `#644a9b` | 普通 |
| Variable | 变量 | `#27aeae` | `#0057ae` | 普通 |
| String | 字符串 | `#f44f4f` | `#bf0303` | 普通 |
| Number | 数字 | `#f67400` | `#b08000` | 普通 |
| Comment | 注释 | `#7a7c7d` | `#898887` | 普通 |
| Error | 错误 | `#da4453` | `#bf0303` | **下划线** |

### 5.2 text-styles（次要类别，按需使用）

| 类别 | Breeze Dark | Breeze Light | 字体属性 |
|---|---|---|---|
| Preprocessor（#include） | `#27ae60` | `#006e28` | 普通 |
| BuiltIn（内建函数） | `#609ca0` | `#644a9b` | **加粗** |
| Operator（操作符） | `#3f8058` | `#ca60ca` | 普通 |
| Char（单字符） | `#3daee9` | `#924c9d` | 普通 |
| DataType（数据类型） | `#2980b9` | `#0057ae` | 普通 |
| DecVal/BaseN/Float（数字） | `#f67400` | `#b08000` | 普通 |
| Constant（常量） | `#27aeae` | `#aa5500` | **加粗** |
| SpecialString | `#da4453` | `#ff5500` | 普通 |
| Warning | `#da4453` | `#bf0303` | 普通 |

### 5.3 editor-colors（编辑器整体颜色）

| 类别 | Breeze Dark | Breeze Light |
|---|---|---|
| BackgroundColor（编辑器背景） | `#232629` | `#ffffff` |
| CurrentLine（当前光标行） | `#2A2E32` | `#f8f7f6` |
| LineNumbers（行号前景） | `#7a7c7d` | `#a0a0a0` |
| CurrentLineNumber（当前行号） | `#a5a6a8` | `#1e1e1e` |
| TextSelection（选中区背景） | `#2d5c76` | `#94caef` |
| IndentationLine（缩进线） | `#3a3f44` | `#d2d2d2` |
| CodeFolding（代码折叠线） | `#224e65` | `#94caef` |
| IconBorder | `#31363b` | `#f0f0f0` |
| SearchHighlight | `#414857` | `#ffff00` |
| ReplaceHighlight | `#808021` | `#00ff00` |
| ModifiedLines | `#c04900` | `#fdbc4b` |
| SavedLines | `#1c8042` | `#2ecc71` |

## 6. 智能映射规则（init.lua 的关键词匹配表）

按样式名里**包含的关键词**自动归类到 Kate 的 text-style。匹配不到时 fallback 到默认色。

| 关键词（任一匹配） | 归类到 | 备注 |
|---|---|---|
| `KEYWORD`、`INSTRUCTION`、`STATEMENT` | Keyword（加粗） | 大部分语言的关键字 |
| `CONTROL`、`FLOW`（如 `CONTROL_FLOW`） | ControlFlow（加粗，加暖黄色） | if/else/for 这种 |
| `FUNCTION`、`METHOD`、`CALL`、`PROC` | Function | 函数名 |
| `VARIABLE`、`IDENTIFIER`、`VARIABLE`、`VAR`、`PARAM`、`SCALAR`、`BACKTICKS` | Variable | 变量/标识符 |
| `OPERATOR`、`PUNCTUATION` | Operator | 操作符 |
| `BUILTIN`、`BUILT_IN`、`PREDEF` | BuiltIn | 内建函数 |
| `PREPROCESSOR`、`PREPROC`、`DIRECTIVE`、`IMPORT` | Preprocessor | `#include`、`import` 等 |
| `TYPE`、`DATATYPE`、`DATA_TYPE`、`CLASS` | DataType | 数据类型 |
| `STRING`、`LITERAL` | String | 字符串 |
| `CHARACTER`、`CHAR` | Char | 单字符 |
| `SPECIAL_STRING`、`SPECIAL_STRING` | SpecialString | 原样字符串 |
| `NUMBER`、`FLOAT`、`DECVAL`、`INT` | Number | 数字 |
| `CONSTANT`、`CONST` | Constant（加粗） | 常量 |
| `COMMENT`、`REM` | Comment | 注释 |
| `ERROR`、`ALERT`、`INVALID` | Error（下划线） | 错误 |
| `WARNING`、`TODO`、`FIXME`、`BUG` | Warning | 警告 |
| `ATTRIBUTE`、`ANNOTATION`、`TAG`、`MARKUP`、`HTML`、`XML` | Preprocessor（暗）/ `#2980b9`（浅） | HTML/XML 标签 |
| `DOCUMENT`、`HEADER`、`TITLE` | SpecialString | YAML 文档分隔符等 |
| `TEXT`、空字符串、其他 | Normal（默认色） | 不特殊处理 |

**注意**：以上每条规则在暗色和浅色模式下都用同一种归类，颜色按 5.1 / 5.2 的表取。

## 7. 改动文件清单

### 7.1 核心改动（必须）

| 文件 | 改动 |
|---|---|
| `src/scripts/init.lua` | 改造 `theme` 表，加上 Breeze 配色 + `MapStyle(name)` 函数返回 Kate 颜色 + 改 `SetStyle()` 用新映射 |
| `src/EditorManager.cpp` | 改 `applyEditorTheme()` 和 `applyEditorNamedStyles()` 里的硬编码颜色 → Breeze editor-colors |
| `src/dialogs/MainWindow.cpp` | 检查 `applyStyleSheet()` 里的 QPalette 是否需要微调（如果完全保留 PR #1040 的，可能不需要改） |

### 7.2 87 个语言 lua 文件

**不直接改文件内容**——改 init.lua 的映射规则后，所有语言自动继承新配色。

但是要做的检查：
- 确认没有自定义特殊样式被误判
- 极个别语言（如 YAML 的 `REFERENCE`、`DOCUMENT`）会被映射到 SpecialString/默认色——需要看视觉效果决定是否微调

### 7.3 不动的文件

- 87 个 `src/languages/*.lua` 本身（不动）
- `src/stylesheets/npp-dark.css` 和 `npp.css`（qt 控件的 CSS 不用改）
- `CMakeLists.txt`、`src/CMakeLists.txt`、`src/languages/CMakeLists.txt`（构建系统不动）
- `.github/workflows/linux-appimage.yml`（已有 workflow 复用，不动）

## 8. 实施步骤

| # | 步骤 | 验证方式 |
|---|---|---|
| 1 | 改 `init.lua`（theme 表 + 映射函数 + SetStyle） | 代码 review |
| 2 | 改 `EditorManager.cpp`（editor-colors） | 代码 review |
| 3 | 本地**不**编译（按 AGENTS.md 严禁本地编译） | — |
| 4 | `git commit` 一个主题，中文 message | git log |
| 5 | push 到 noame19/NotepadNext | push 成功 |
| 6 | 触发 GitHub Actions（`gh workflow run linux-appimage.yml`） | workflow run 状态 |
| 7 | 等待编译成功，下载新 AppImage | artifact 出现 |
| 8 | 验证 dark mode 视觉效果 | 视觉 review（用户确认） |

## 9. 风险与已知问题

| 风险 | 概率 | 缓解措施 |
|---|---|---|
| 编译失败（C++ 改坏了） | 低 | 改完用 `cmake -S . -B build` 干跑（不编译）做语法检查 |
| 关键词匹配误判 | 中 | 触发 workflow 后用户视觉 review，发现问题就调整规则 |
| 浅色模式颜色对比度不够 | 低 | Kate Light 已经经过设计师调校，问题概率低 |
| 个别语言的语义被错误归类 | 中 | 比如 YAML 的 `REFERENCE` 可能归类不准——用户 review 后调整关键词规则 |
| GitHub Actions 资源紧张导致构建超时 | 中 | 重试；或换 ubuntu-22.04 |

## 10. 验收标准

实施完后，用户应该看到：

1. 启动 AppImage，默认跟随系统颜色
2. 在暗色模式下打开 Shell 脚本：变量名（`$VAR`）不再是亮青色背景块；颜色统一协调
3. 在暗色模式下打开 YAML：关键字（`true/false`）是默认色 + 加粗，不再是蓝色
4. 在暗色模式下打开 C++：函数名紫色、字符串红色、数字橙色、注释中灰
5. 在浅色模式下打开任何文件：颜色协调，关键字默认色 + 加粗
6. 切换「浅色 / 暗色 / 跟随系统」都能即时响应

## 11. 后续可选项（不在本次范围内）

- 加一个「自定义主题」入口，允许用户切换 Kate 的其它配色（如 Solarized、Dracula）
- 把 csv、json、yaml 的不同结构（数组/对象/键/值）做更精细的区分
- 让用户在 Preferences 里微调颜色（需要 Preferences UI 改动）
