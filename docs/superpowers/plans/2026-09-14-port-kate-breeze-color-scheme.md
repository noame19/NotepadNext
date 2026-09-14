# 移植 Breeze 配色方案实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 KDE Kate 的 Breeze Dark/Light 配色移植到 NotepadNext，让所有 87 种语言的语法高亮都使用设计师调校过的配色，看着更舒服。

**Architecture:** 通过修改 `src/scripts/init.lua` 里的 Lua 脚本（添加 Kate text-style 颜色表 + 关键词匹配函数 + 改写 `SetStyle()`）和 `src/EditorManager.cpp` 里的硬编码颜色，让所有语言文件自动继承新配色，不直接修改 87 个语言文件。

**Tech Stack:** C++ (Qt 6, Scintilla), Lua (init.lua + 87 个语言文件), CMake, GitHub Actions

**Spec:** `docs/superpowers/specs/2026-09-14-port-kate-breeze-color-scheme-design.md`

## 全局约束

- **严禁本地编译**：所有编译必须通过 GitHub Actions (`gh workflow run linux-appimage.yml --repo noame19/NotepadNext --ref master`)。本地环境只做代码修改和提交
- **commit message**：中文，`feat:` / `fix:` / `docs:` / `ci:` 前缀沿用项目惯例
- **一个 commit 一个主题**：方便 `git revert`
- **颜色值**：所有 hex 颜色必须**精确复制**自 Breeze 配色文件（不可四舍五入）
- **双向兼容**：所有改动必须保持浅色 + 暗色双模式正常工作，不能破坏 PR #1040 已有的 ThemeMode 三态切换
- **不修改**：87 个 `src/languages/*.lua` 文件不动；Qt 控件的 QPalette 调色板（PR #1040 已处理）不动；CSS 文件不动；构建系统不动

---

## Task 1：在 init.lua 里加入 Breeze Dark/Light 完整配色表

**Files:**
- Modify: `src/scripts/init.lua:1-30` （顶部 rgb 函数 + UpdateTheme 函数）

**Interfaces:**
- Consumes: 无（独立任务）
- Produces: 全局 `theme` 表，包含暗色和浅色两套配色，下游 Task 2 和 Task 3 会用

- [ ] **Step 1: 重写 UpdateTheme 函数，把 theme 表换成 Breeze 配色**

把 `src/scripts/init.lua` 第 1-30 行（`function rgb(x)` 和 `function UpdateTheme()`）替换成：

```lua
function rgb(x)
    return ((x & 0xFF) << 16) | (x & 0xFF00) | ((x & 0xFF0000) >> 16)
end

local STYLE_DEFAULT = 32

-- 把 Kate 的 Breeze Dark/Light 配色表注入到 Lua。
-- Kate 用 "功能分类"（Keyword/String/Number...），所有语言共用。
-- dark_mode 是 C++ 注入的全局布尔（dark_mode=true 表示当前是暗色模式）。
-- 不直接改 fgColor/bgColor，让下游 SetStyle() 通过 MapStyle() 决定。
function UpdateTheme()
    if dark_mode then
        theme = {
            -- text-styles：Kate 暗色配色（Breeze Dark）
            keyword      = rgb(0xcfcfc2),  -- Keyword 默认色
            keyword_bold = true,
            controlflow  = rgb(0xfdbc4b),  -- ControlFlow 暖黄
            controlflow_bold = true,
            function_    = rgb(0x8e44ad),  -- Function 紫
            variable     = rgb(0x27aeae),  -- Variable 青
            operator_    = rgb(0x3f8058),  -- Operator 暗绿
            builtin      = rgb(0x609ca0),  -- BuiltIn 浅青
            builtin_bold = true,
            preprocessor = rgb(0x27ae60),  -- Preprocessor 绿
            datatype     = rgb(0x2980b9),  -- DataType 蓝
            char_        = rgb(0x3daee9),  -- Char 浅蓝
            string_      = rgb(0xf44f4f),  -- String 红
            specialstring= rgb(0xda4453),  -- SpecialString 深红
            number       = rgb(0xf67400),  -- Number 橙
            constant     = rgb(0x27aeae),  -- Constant 青
            constant_bold= true,
            comment      = rgb(0x7a7c7d),  -- Comment 中灰
            warning      = rgb(0xda4453),  -- Warning 深红
            error_       = rgb(0xda4453),  -- Error 深红
            error_underline = true,

            -- 默认值（编辑器背景色 #232629）
            default_fg   = rgb(0xcfcfc2),  -- Normal 暖灰
            default_bg   = rgb(0x232629),  -- BackgroundColor Breeze Dark
        }
    else
        theme = {
            -- text-styles：Kate 浅色配色（Breeze Light）
            keyword      = rgb(0x1f1c1b),
            keyword_bold = true,
            controlflow  = rgb(0x1f1c1b),
            controlflow_bold = true,
            function_    = rgb(0x644a9b),
            variable     = rgb(0x0057ae),
            operator_    = rgb(0xca60ca),
            builtin      = rgb(0x644a9b),
            builtin_bold = true,
            preprocessor = rgb(0x006e28),
            datatype     = rgb(0x0057ae),
            char_        = rgb(0x924c9d),
            string_      = rgb(0xbf0303),
            specialstring= rgb(0xff5500),
            number       = rgb(0xb08000),
            constant     = rgb(0xaa5500),
            constant_bold= true,
            comment      = rgb(0x898887),
            warning      = rgb(0xbf0303),
            error_       = rgb(0xbf0303),
            error_underline = true,

            default_fg   = rgb(0x1f1c1b),
            default_bg   = rgb(0xffffff),
        }
    end
end

UpdateTheme()
```

- [ ] **Step 2: 验证 Lua 语法**

运行：
```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
which luac && luac -p src/scripts/init.lua 2>&1
```

期望：`luac` 没有输出（Lua 语法 OK）。如果 `luac` 没装，肉眼检查括号配对、引号配对。

- [ ] **Step 3: commit**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
git add src/scripts/init.lua
git commit -m "feat(theme): 把 theme 表换成 Kate Breeze Dark/Light 配色

按设计文档第 5.1/5.2 节，加入 Kate text-styles 的 19 类颜色映射，
每个类别同时支持暗色和浅色两套。

- keyword_bold / controlflow_bold / builtin_bold / constant_bold：默认色 + 加粗
- error_underline：错误用下划线不靠背景色
- default_bg 改用 Breeze Dark 的 #232629（之前 PR #1040 用的 #1E1E1E）

注意：还没改 SetStyle()，主题色表已就位但当前 SetStyle 不会用这些字段。
接下来 Task 2 加 MapStyle()，Task 3 让 SetStyle() 调用它。"
```

---

## Task 2：在 init.lua 里加 MapStyle() 关键词匹配函数

**Files:**
- Modify: `src/scripts/init.lua` （在 UpdateTheme() 之后插入新函数）

**Interfaces:**
- Consumes: 全局 `theme` 表（Task 1 建立的）
- Produces: `MapStyle(styleName)` 函数，输入样式名字符串，返回 `fg` 前景色（数字） + 可选的 `bold`、`italic`、`underline`（布尔）

- [ ] **Step 1: 在 UpdateTheme() 之后插入 MapStyle 函数**

紧接 `UpdateTheme()` 函数之后（约第 60 行后），在 `function DetectLanguageFromContents(contents)` 之前，插入：

```lua
-- 把 NotepadNext 各语言文件里的样式名按关键词自动归类到 Kate 的 text-style。
-- 比如样式名 "INSTRUCTION WORD" / "KEYWORD" / "STATEMENT" 都归类到 Keyword。
-- 匹配不到 fallback 到默认色（normal text）。
--
-- 返回值：fg（前景色数字），可选 bold/italic/underline 标志
function MapStyle(styleName)
    local name = string.upper(styleName or "")
    local t = theme

    -- 错误样式优先匹配（最高优先级）
    if name:find("ERROR") or name:find("ALERT") or name:find("INVALID") then
        return t.error_, nil, nil, t.error_underline
    end

    -- 关键字/控制流/语句（加粗）
    if name:find("KEYWORD") or name:find("INSTRUCTION") or name:find("STATEMENT") or name:find("RESERVED") then
        return t.keyword, t.keyword_bold, nil, nil
    end
    if name:find("CONTROL") or name == "FLOW" or name:find("CONTROLFLOW") then
        return t.controlflow, t.controlflow_bold, nil, nil
    end

    -- 注释
    if name:find("COMMENT") or name:find("REM ") then
        return t.comment, nil, nil, nil
    end

    -- 字符串和字符
    if name:find("SPECIAL_STRING") or name:find("SPECIALSTRING") then
        return t.specialstring, nil, nil, nil
    end
    if name:find("CHARACTER") then
        return t.char_, nil, nil, nil
    end
    if name:find("CHAR") and not name:find("CHARACTER") then
        return t.char_, nil, nil, nil
    end
    if name:find("STRING") or name:find("LITERAL") or name:find("VERBATIM") then
        return t.string_, nil, nil, nil
    end

    -- 数字
    if name:find("NUMBER") or name:find("FLOAT") or name:find("DECVAL") or name:find("BASEN") or name:find("INT") or name:find("NUM") then
        return t.number, nil, nil, nil
    end

    -- 函数
    if name:find("FUNCTION") or name:find("METHOD") or name:find("CALL") or name:find("PROC") or name:find("SUBROUTINE") then
        return t.function_, nil, nil, nil
    end

    -- 类型/类
    if name:find("TYPE") or name:find("DATATYPE") or name:find("DATA_TYPE") or name:find("CLASS") then
        return t.datatype, nil, nil, nil
    end

    -- 变量/标识符/标量
    if name:find("VARIABLE") or name:find("IDENTIFIER") or name:find("VAR") or name:find("SCALAR") or name:find("PARAM") or name:find("BACKTICKS") or name:find("REFERENCE") then
        return t.variable, nil, nil, nil
    end

    -- 预处理/指令/import
    if name:find("PREPROCESSOR") or name:find("PREPROC") or name:find("DIRECTIVE") or name:find("IMPORT") or name:find("INCLUDE") then
        return t.preprocessor, nil, nil, nil
    end

    -- 内建函数
    if name:find("BUILTIN") or name:find("BUILT_IN") or name:find("PREDEF") then
        return t.builtin, t.builtin_bold, nil, nil
    end

    -- 操作符/标点
    if name:find("OPERATOR") or name:find("PUNCTUATION") then
        return t.operator_, nil, nil, nil
    end

    -- 常量
    if name:find("CONSTANT") or name:find("CONST") then
        return t.constant, t.constant_bold, nil, nil
    end

    -- HTML/XML/标签/属性
    if name:find("ATTRIBUTE") or name:find("ANNOTATION") or name:find("TAG") or name:find("MARKUP") then
        return t.preprocessor, nil, nil, nil
    end

    -- 警告/特殊标记
    if name:find("WARNING") or name:find("TODO") or name:find("FIXME") or name:find("BUG") then
        return t.warning, nil, nil, nil
    end

    -- 文档/头部分隔
    if name:find("DOCUMENT") or name:find("HEADER") or name:find("TITLE") then
        return t.specialstring, nil, nil, nil
    end

    -- 默认（普通文字）
    return t.default_fg, nil, nil, nil
end
```

- [ ] **Step 2: 验证 Lua 语法**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
which luac && luac -p src/scripts/init.lua 2>&1
```

期望：无输出

- [ ] **Step 3: commit**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
git add src/scripts/init.lua
git commit -m "feat(theme): 加 MapStyle() 关键词匹配函数

把 NotepadNext 各语言文件里的样式名（INSTRUCTION WORD / COMMENT /
STRING / NUMBER / ERROR 等）按关键词自动归类到 Kate text-style。

匹配优先级：ERROR > KEYWORD/INSTRUCTION > COMMENT > STRING > NUMBER >
FUNCTION > TYPE > VARIABLE > PREPROCESSOR > BUILTIN > OPERATOR > CONSTANT >
ATTRIBUTE > WARNING > DOCUMENT > fallback 默认色。

返回 fg 数字 + 可选 bold/underline 标志。下一个 commit 让 SetStyle 调用它。"
```

---

## Task 3：改 init.lua 的 SetStyle() 调用 MapStyle() 并清掉 bgColor

**Files:**
- Modify: `src/scripts/init.lua` （原 SetStyle 函数，约 64-100 行）

**Interfaces:**
- Consumes: `MapStyle(styleName)` 函数（Task 2 建立的）+ `theme` 表（Task 1）
- Produces: 修改后的 `SetStyle(L)`，让 Scintilla 编辑器用 Breeze 配色而不是原语言文件的硬编码色

- [ ] **Step 1: 确认 L.styles 的 key 是样式名（用于 MapStyle 输入）**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
sed -n '40,50p' src/languages/bash.lua
```

期望：看到 `["INSTRUCTION WORD"] = {` 这种 key-value 形式。说明 `pairs(L.styles)` 迭代时第一个变量是样式名

- [ ] **Step 2: 替换 SetStyle 函数**

找到现有 `function SetStyle(L)`（约第 64 行起），**整体替换**为：

```lua
function SetStyle(L)
    -- 应用主题基色：STYLE_DEFAULT 设画布，styleClearAll() 之后所有没明确
    -- 设颜色的样式都用这个底色。
    editor.StyleFore[STYLE_DEFAULT] = theme.default_fg
    editor.StyleBack[STYLE_DEFAULT] = theme.default_bg
    editor:StyleClearAll()

    if L.styles then
        for name, style in pairs(L.styles) do
            -- 用 MapStyle 按样式名归类到 Kate text-style，决定前景色和字体属性。
            -- 不再读原 fgColor/bgColor（背景色全部清掉，让主题统一）。
            local fg, bold, italic, underline = MapStyle(name)

            editor.StyleFore[style.id] = fg
            -- 背景色：不设置，由 STYLE_DEFAULT 兜底，保持编辑区背景统一

            -- 字体属性（MapStyle 优先，原文件 fontStyle 作 fallback）
            if bold then
                editor.StyleBold[style.id] = true
            elseif style.fontStyle then
                editor.StyleBold[style.id] = (style.fontStyle & 1 == 1)
            end

            if italic then
                editor.StyleItalic[style.id] = true
            elseif style.fontStyle then
                editor.StyleItalic[style.id] = (style.fontStyle & 2 == 2)
            end

            if underline then
                editor.StyleUnderline[style.id] = true
            elseif style.fontStyle then
                editor.StyleUnderline[style.id] = (style.fontStyle & 4 == 4)
            end
        end
    end

    if L.keywords then
        for id, kw in pairs(L.keywords) do
            editor.KeyWords[id] = kw
        end
    end

    if L.properties then
        for p, v in pairs(L.properties) do
            editor.Property[p] = v
        end
    end
end
```

- [ ] **Step 3: 验证 Lua 语法**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
which luac && luac -p src/scripts/init.lua 2>&1
```

期望：无输出

- [ ] **Step 4: commit**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
git add src/scripts/init.lua
git commit -m "feat(theme): 重写 SetStyle() 使用 MapStyle + 清掉所有 bgColor

重大变化：
- 不再读原语言 lua 文件里的 fgColor/bgColor
- 改用 MapStyle(name) 按样式名归类到 Kate text-style 决定前景色
- 不再设置 StyleBack，所有样式背景统一用 STYLE_DEFAULT 的默认色
- 这是 Breeze 配色看着舒服的核心：没有乱七八糟的彩色背景块

字体属性处理：MapStyle 返回的 bold/italic/underline 优先级高于原 style.fontStyle
（这样能让 KEYWORD 强制加粗，不管原文件怎么写）。

下一步：改 EditorManager.cpp 把编辑器整体色（背景/行号/当前行/选中区）换成 Breeze 的。"
```

---

## Task 4：改 EditorManager.cpp 的 applyEditorTheme() 换成 Breeze editor-colors

**Files:**
- Modify: `src/EditorManager.cpp:319-348` （applyEditorTheme 函数）

**Interfaces:**
- Consumes: `settings->effectiveDarkMode()` 返回 bool
- Produces: Scintilla 编辑器元素颜色，符合 Breeze Dark/Light 的 editor-colors

- [ ] **Step 1: 定位 applyEditorTheme 函数**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
grep -n "applyEditorTheme\|applyEditorNamedStyles" src/EditorManager.cpp
```

期望：能看到两个函数定义

- [ ] **Step 2: 替换 applyEditorTheme 函数体里的颜色**

定位到 applyEditorTheme 函数（约 319-348 行），把 setElementColour / setFoldMarginColour / styleSetFore/STYLE_DEFAULT / styleSetBack/STYLE_DEFAULT 这一段的硬编码颜色替换为：

```cpp
void EditorManager::applyEditorTheme(ScintillaNext *editor)
{
    const bool dark = settings->effectiveDarkMode();

    // Fold markers (not affected by styleClearAll)
    for (int i = SC_MARKNUM_FOLDEREND; i <= SC_MARKNUM_FOLDEROPEN; ++i) {
        editor->markerSetFore(i, dark ? 0x3C3C3C : 0x3a3f44);
        editor->markerSetBack(i, 0x808080);
        editor->markerSetBackSelected(i, dark ? 0xCC7A00 : 0x0000FF);
    }

    // Element colors (ARGB 0xAARRGGBB; not affected by styleClearAll)
    editor->setElementColour(SC_ELEMENT_SELECTION_INACTIVE_BACK, dark ? 0xFF414857 : 0xFFFFFE99);
    editor->setElementColour(SC_ELEMENT_CARET_LINE_BACK,         dark ? 0xFF2A2E32 : 0xFFF8F7F6);
    editor->setElementColour(SC_ELEMENT_WHITE_SPACE,             dark ? 0xFF505050 : 0xFFD2D2D2);
    editor->setElementColour(SC_ELEMENT_FOLD_LINE,               dark ? 0xFF224E65 : 0xFF94CAEF);

    // Fold margin (not affected by styleClearAll)
    editor->setFoldMarginColour(true,   dark ? 0x232629 : 0xFFFFFF);
    editor->setFoldMarginHiColour(true, dark ? 0x31363b : 0xF0F0F0);

    // STYLE_DEFAULT sets the base for styleClearAll()
    editor->styleSetFore(STYLE_DEFAULT, dark ? 0xCFCFC2 : 0x1F1C1B);
    editor->styleSetBack(STYLE_DEFAULT, dark ? 0x232629 : 0xFFFFFF);
    editor->styleClearAll();

    // Named styles must be re-applied after any subsequent styleClearAll
    // (Lua SetStyle does one when a language is loaded)
    applyEditorNamedStyles(editor);
}
```

- [ ] **Step 3: 静态检查 C++ 语法**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
which clang-format && clang-format --dry-run --Werror src/EditorManager.cpp 2>&1 | head -10
```

期望：无 error（warning 可忽略）。如果 clang-format 没装，肉眼 review 括号配对。

- [ ] **Step 4: commit**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
git add src/EditorManager.cpp
git commit -m "fix(theme): 编辑器元素颜色换成 Breeze editor-colors

替换 PR #1040 的 VS Code 风格配色：
- 背景：#1E1E1E -> #232629（暗色）/ 保持 #FFFFFF（浅色）
- 当前行：#2A2D2E -> #2A2E32（暗色）/ #FFFFE8E8 -> #F8F7F6（浅色）
- 选中区未激活：#3A3D41 -> #414857（暗色）/ 加 #FFFFFE99（浅色，更亮）
- 折叠线：#505050 -> #224E65（暗色，深蓝）/ #94CAEF（浅色，浅蓝）
- 缩进空白：#D0D0D0 -> #D2D2D2（浅色）/ 保持 #505050（暗色）
- 默认前景：#D4D4D4 -> #CFCFC2（暗色，暖灰）/ #000000 -> #1F1C1B（浅色，深棕黑）
- 折叠边距：白色 -> #FFFFFF（浅色） / #232629（暗色）"
```

---

## Task 5：改 EditorManager.cpp 的 applyEditorNamedStyles() 换成 Breeze LineNumbers / BraceLight / BraceBad / IndentGuide

**Files:**
- Modify: `src/EditorManager.cpp:350-366` （applyEditorNamedStyles 函数）

**Interfaces:**
- Consumes: `settings->effectiveDarkMode()`
- Produces: 行号、括号匹配、括号错误、缩进引导的颜色（按 Breeze Dark/Light 的 editor-colors）

- [ ] **Step 1: 替换 applyEditorNamedStyles 函数体**

定位到 applyEditorNamedStyles 函数（约 350-366 行），整体替换为：

```cpp
void EditorManager::applyEditorNamedStyles(ScintillaNext *editor)
{
    const bool dark = settings->effectiveDarkMode();

    editor->styleSetFore(STYLE_LINENUMBER, dark ? 0x7A7C7D : 0xA0A0A0);
    editor->styleSetBack(STYLE_LINENUMBER, dark ? 0x232629 : 0xFFFFFF);
    editor->styleSetBold(STYLE_LINENUMBER, false);

    editor->styleSetFore(STYLE_BRACELIGHT, dark ? 0xCFCFC2 : 0x1F1C1B);
    editor->styleSetBack(STYLE_BRACELIGHT, dark ? 0x232629 : 0xFFFFFE99);

    editor->styleSetFore(STYLE_BRACEBAD,   dark ? 0xDA4453 : 0xBF0303);
    editor->styleSetBack(STYLE_BRACEBAD,   dark ? 0x232629 : 0xFFFFFF);

    editor->styleSetFore(STYLE_INDENTGUIDE, dark ? 0x3A3F44 : 0xD2D2D2);
    editor->styleSetBack(STYLE_INDENTGUIDE, dark ? 0x232629 : 0xFFFFFF);
}
```

- [ ] **Step 2: 静态检查 C++ 语法**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
which clang-format && clang-format --dry-run --Werror src/EditorManager.cpp 2>&1 | head -10
```

- [ ] **Step 3: commit**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
git add src/EditorManager.cpp
git commit -m "fix(theme): 行号/括号匹配/缩进引导色换成 Breeze editor-colors

- STYLE_LINENUMBER: 前景 #7A7C7D (暗) / #A0A0A0 (浅) [Breeze]
- STYLE_BRACELIGHT: 匹配括号用普通前景色 + 浅黄背景 (#FFFFFE99) 浅色模式更明显
- STYLE_BRACEBAD: 不匹配括号用 #DA4453 (暗) / #BF0303 (浅) 深红
- STYLE_INDENTGUIDE: 缩进引导线 #3A3F44 (暗) / #D2D2D2 (浅)"
```

---

## Task 6：触发 GitHub Actions 编译并验证

**Files:** 无

**Interfaces:**
- Consumes: 已 push 到 master 的 5 个 commit
- Produces: GitHub Actions 编译产出的新 AppImage

- [ ] **Step 1: push 所有 commit**

```bash
cd /home/manaka-fedora/codex_rom/NotepadNext
git push origin master 2>&1 | tail -5
```

- [ ] **Step 2: 触发 workflow**

```bash
gh workflow run linux-appimage.yml --repo noame19/NotepadNext --ref master 2>&1 | tail -3
```

把返回的 run URL 保存下来

- [ ] **Step 3: 等待编译完成（约 10-15 分钟）**

```bash
sleep 600
gh run view <RUN_ID> --repo noame19/NotepadNext --json status,conclusion 2>&1 | head -3
```

把 `<RUN_ID>` 替换为实际 run id

期望：`status: completed, conclusion: success`

- [ ] **Step 4: 如果编译失败查看日志并修复**

```bash
gh run view <RUN_ID> --repo noame19/NotepadNext --log-failed 2>&1 | tail -40
```

按错误修复（最常见是 C++ 语法错或 Lua 函数名写错），修完重新 commit + push + 触发 workflow

- [ ] **Step 5: 编译成功后下载 AppImage**

```bash
ARTIFACT_ID=$(gh api repos/noame19/NotepadNext/actions/runs/<RUN_ID>/artifacts --jq '.artifacts[0].id' 2>&1)
gh api repos/noame19/NotepadNext/actions/artifacts/$ARTIFACT_ID/zip > /tmp/NotepadNext-breeze.zip 2>&1
unzip -o /tmp/NotepadNext-breeze.zip -d /tmp/ 2>&1
chmod +x /tmp/NotepadNext-*.AppImage
ls -la /tmp/NotepadNext-*.AppImage
```

- [ ] **Step 6: 验证 dark mode 资源**

```bash
cd /tmp
APPIMAGE_EXTRACT_AND_RUN=1 ./NotepadNext-*.AppImage --appimage-extract 2>&1 | tail -3
strings squashfs-root/usr/bin/NotepadNext 2>/dev/null | grep -iE 'controlflow|builtin_|specialstring' | head -10
```

期望：能看到新加的 Lua 字段名（说明编译进二进制）

- [ ] **Step 7: commit（无文件改动，仅留痕）**

如果一切正常，无需 commit。Task 结束。

---

## Task 7：把 AppImage 拷贝到本地下载目录并汇报

**Files:**
- Create: `/home/manaka-fedora/codex_rom/notepad-appimage-output/NotepadNext-breeze-<sha>.AppImage`

- [ ] **Step 1: 拷贝并重命名**

```bash
SHA=$(git -C /home/manaka-fedora/codex_rom/NotepadNext rev-parse --short HEAD)
cp /tmp/NotepadNext-*.AppImage /home/manaka-fedora/codex_rom/notepad-appimage-output/NotepadNext-breeze-${SHA}-x86_64.AppImage
ls -la /home/manaka-fedora/codex_rom/notepad-appimage-output/NotepadNext-breeze-*.AppImage
```

期望：~35MB 的 AppImage

- [ ] **Step 2: 汇报给用户**

用大白话告诉用户：
- 新 AppImage 在哪里
- 启动后会看到哪些变化（背景色、行号、关键字加粗等）
- 切换「浅色 / 暗色 / 跟随系统」应该都能即时响应
- 如果某个语言看着颜色不对，告诉具体语言名 + 样式名，我调 MapStyle 规则

Task 7 结束。

---

## 自检（Self-Review）

对照 spec 检查：

| Spec 章节 | 覆盖的 Task |
|---|---|
| §1 目标 | Task 1-7 |
| §3.1 要做的事 | Task 1-7 |
| §3.2 不做的事 | Task 6 没改语言文件 / Task 4-5 没改 QPalette |
| §4 5 个决策 | Task 1-5 全都体现了 |
| §5 配色映射表 | Task 1 是 theme 表，Task 4-5 是 editor-colors |
| §6 智能映射规则 | Task 2 是 MapStyle 函数 |
| §7 改动文件清单 | Task 1-3 改 init.lua，Task 4-5 改 EditorManager.cpp |
| §8 实施步骤 | Task 1-7 |
| §9 风险 | Task 6 Step 4 失败回滚 |
| §10 验收标准 | Task 7 Step 2 用户视觉 review |

**未覆盖的 spec 要求**：无

**placeholder 扫描**：除关键词规则里的正常 `TODO/FIXME/BUG` 字符串外，无 placeholder

**类型一致性**：Task 1 theme 字段 → Task 2 MapStyle 访问 → Task 3 SetStyle 调用，三处一致
