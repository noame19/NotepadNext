function rgb(x)
    return ((x & 0xFF) << 16) | (x & 0xFF00) | ((x & 0xFF0000) >> 16)
end

local STYLE_DEFAULT = 32

-- Build the active theme table from the dark_mode global injected by C++.
-- Also called by NotepadNextApplication::refreshEditorTheme() on toggle.
function UpdateTheme()
    if dark_mode then
        theme = {
            -- text-styles：Breeze Dark 配色
            keyword      = rgb(0xcfcfc2),
            keyword_bold = true,
            controlflow  = rgb(0xfdbc4b),
            controlflow_bold = true,
            function_    = rgb(0x8e44ad),
            variable     = rgb(0x27aeae),
            operator_    = rgb(0x3f8058),
            builtin      = rgb(0x609ca0),
            builtin_bold = true,
            preprocessor = rgb(0x27ae60),
            datatype     = rgb(0x2980b9),
            char_        = rgb(0x3daee9),
            string_      = rgb(0xf44f4f),
            specialstring= rgb(0xda4453),
            number       = rgb(0xf67400),
            constant     = rgb(0x27aeae),
            constant_bold= true,
            comment      = rgb(0x7a7c7d),
            warning      = rgb(0xda4453),
            error_       = rgb(0xda4453),
            error_underline = true,

            default_fg   = rgb(0xcfcfc2),
            default_bg   = rgb(0x232629),
        }
    else
        theme = {
            -- text-styles：Breeze Light 配色
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

function DetectLanguageFromContents(contents)
    for name, L in pairs(languages) do
        if L.first_line then
            for _, pattern in ipairs(L.first_line) do
                if string.match(contents, pattern) then
                    return name
                end
            end
        end
    end
    return "Text"
end

function FilterForLanguage(name)
    local extensions = {}
    local language_definition = languages[name]

    if not language_definition.extensions then
        return nil
    end

    for _, ext in ipairs(language_definition.extensions) do
        if #ext > 0 then
            extensions[#extensions + 1] = "*." .. ext
        end
    end

    return  name .. " Files (" .. table.concat(extensions, " ") .. ")"
end

function DialogFilters()
    local filters = {}

    for name, L in pairs(languages) do
        local filter = FilterForLanguage(name)
        if filter then
            filters[#filters + 1] = filter
        end
    end

    table.sort(filters, function (a, b) return a:lower() < b:lower() end)
    table.insert(filters, 1, "All Files (*)")

    return table.concat(filters, ";;")
end

function SetStyle(L)
    -- Apply theme base: STYLE_DEFAULT sets the canvas for styleClearAll().
    -- This ensures every style slot starts with the correct background color
    -- even for styles not explicitly listed in the language definition.
    editor.StyleFore[STYLE_DEFAULT] = theme.default_fg
    editor.StyleBack[STYLE_DEFAULT] = theme.default_bg
    editor:StyleClearAll()

    if L.styles then
        for _, style in pairs(L.styles) do
            -- Translate canonical light-mode colors to theme equivalents.
            -- Language files that specify black text on white background get
            -- auto-converted; deliberate syntax colors (blue, green, etc.)
            -- pass through unchanged since they are readable on dark backgrounds.
            local fg = (style.fgColor == theme.light_fg) and theme.default_fg or style.fgColor
            local bg = (style.bgColor == theme.light_bg) and theme.default_bg or style.bgColor
            editor.StyleFore[style.id] = fg
            editor.StyleBack[style.id] = bg

            if style.fontStyle then
                editor.StyleBold[style.id] = (style.fontStyle & 1 == 1)
                editor.StyleItalic[style.id] = (style.fontStyle & 2 == 2)
                editor.StyleUnderline[style.id] = (style.fontStyle & 4 == 4)
                editor.StyleEOLFilled[style.id] = (style.fontStyle & 8 == 8)
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

function SetLanguage(languageName)
    local L = languages[languageName]

    if not skip_tabs then
        editor.UseTabs = (L.tabSettings or "tabs") == "tabs"
    end

    if not skip_tabwidth then
        editor.TabWidth = L.tabSize or 4
    end

    editor.MarginWidthN[2] = L.disableFoldMargin and 0 or 16

    SetStyle(L)

    if L.additionalLanguages then
        for _, language in pairs(L.additionalLanguages) do
            SetStyle(languages[language])
        end
    end


    editor.Property["fold"] = "1"
    editor.Property["fold.compact"] = "0"
end

function GetLanguageKeywords(languageName)
    local L = languages[languageName]

    if not L or not L.keywords then
        return {}
    end

    local seen = {}

    local function collectKeywords(lang)
        if not lang then return end
        if lang.keywords then
            for _, kwString in pairs(lang.keywords) do
                for token in kwString:gmatch("%S+") do
                    seen[token] = true
                end
            end
        end
    end

    collectKeywords(L)

    if L.additionalLanguages then
        for _, language in pairs(L.additionalLanguages) do
            collectKeywords(languages[language])
        end
    end

    local result = {}
    for token, _ in pairs(seen) do
        result[#result + 1] = token
    end

    table.sort(result)

    return result
end

languages = {}
languages["ActionScript"] = require("actionscript")
languages["ADA"] = require("ada")
languages["Assembly"] = require("asm")
languages["ASN.1"] = require("asn1")
languages["asp"] = require("asp")
languages["autoIt"] = require("autoit")
languages["AviSynth"] = require("avs")
languages["BaanC"] = require("baanc")
languages["bash"] = require("bash")
languages["Batch"] = require("batch")
languages["BlitzBasic"] = require("blitzbasic")
languages["C"] = require("c")
languages["Caml"] = require("caml")
languages["CMakeFile"] = require("cmake")
languages["COBOL"] = require("cobol")
languages["Csound"] = require("csound")
languages["CoffeeScript"] = require("coffeescript")
languages["C++"] = require("cpp")
languages["C#"] = require("cs")
languages["CSS"] = require("css")
languages["SCSS"] = require("scss")
languages["D"] = require("d")
languages["DIFF"] = require("diff")
languages["Erlang"] = require("erlang")
languages["ESCRIPT"] = require("escript")
languages["Forth"] = require("forth")
languages["Fortran (free form)"] = require("fortran")
languages["Fortran (fixed form)"] = require("fortran77")
languages["FreeBasic"] = require("freebasic")
languages["GUI4CLI"] = require("gui4cli")
languages["Go"] = require("go")
languages["Haskell"] = require("haskell")
languages["HTML"] = require("html")
languages["ini file"] = require("ini")
languages["InnoSetup"] = require("inno")
languages["Intel HEX"] = require("ihex")
languages["Java"] = require("java")
languages["JavaScript"] = require("javascript")
languages["JSON"] = require("json")
languages["KiXtart"] = require("kix")
languages["LISP"] = require("lisp")
languages["LaTeX"] = require("latex")
languages["Lua"] = require("lua")
languages["Less"] = require("less")
languages["Makefile"] = require("makefile")
languages["Markdown"] = require("markdown")
languages["Matlab"] = require("matlab")
languages["MMIXAL"] = require("mmixal")
languages["Nimrod"] = require("nimrod")
languages["Nix"] = require("nix")
languages["extended crontab"] = require("nncrontab")
languages["Dos Style"] = require("nfo")
languages["NSIS"] = require("nsis")
languages["OScript"] = require("oscript")
languages["Objective-C"] = require("objc")
languages["Pascal"] = require("pascal")
languages["Perl"] = require("perl")
languages["PHP"] = require("php")
languages["Postscript"] = require("postscript")
languages["PowerShell"] = require("powershell")
languages["Properties file"] = require("props")
languages["PureBasic"] = require("purebasic")
languages["Python"] = require("python")
languages["R"] = require("r")
languages["REBOL"] = require("rebol")
languages["registry"] = require("registry")
languages["RC"] = require("rc")
languages["Ruby"] = require("ruby")
languages["Rust"] = require("rust")
languages["Scheme"] = require("scheme")
languages["Smalltalk"] = require("smalltalk")
languages["spice"] = require("spice")
languages["SQL"] = require("sql")
languages["S-Record"] = require("srec")
languages["Swift"] = require("swift")
languages["TCL"] = require("tcl")
languages["Tektronix extended HEX"] = require("tehex")
languages["TeX"] = require("tex")
languages["Text"] = require("text")
languages["VB / VBS"] = require("vb")
languages["txt2tags"] = require("txt2tags")
languages["Verilog"] = require("verilog")
languages["VHDL"] = require("vhdl")
languages["Visual Prolog"] = require("visualprolog")
languages["XML"] = require("xml")
languages["YAML"] = require("yaml")
languages["Abaqus"] = require("abaqus")
