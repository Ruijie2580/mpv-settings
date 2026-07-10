-- assfallback.lua
-- 纯 mpv Lua 版本：不调用 PowerShell / cmd，避免启动时终端窗口闪烁。
-- 作用：当当前字幕为 ASS/SSA 时，按字幕语言设置 Fontname 到 Noto Sans CJK 对应变体。
-- 快捷键：Ctrl+Shift+F 显示状态。

local mp = require('mp')

local fallback_font = {
    sc = 'Noto Sans CJK SC',
    tc = 'Noto Sans CJK TC',
    jp = 'Noto Sans CJK JP',
    kr = 'Noto Sans CJK KR',
    default = 'Noto Sans CJK SC',
}

local function detect_lang()
    local tracks = mp.get_property_native('track-list') or {}
    for _, t in ipairs(tracks) do
        if t.type == 'sub' and t.selected then
            local lang = (t.lang or ''):lower()
            local title = (t.title or ''):lower()

            if lang:find('hant') or lang:find('tw') or lang:find('hk') or lang:find('big5')
                or title:find('繁') or title:find('tc') or title:find('cht') then
                return 'tc'
            end
            if lang:find('zh') or lang:find('chi') or lang:find('cmn') or lang:find('hans')
                or lang:find('cn') or lang:find('gb') or title:find('简') or title:find('sc') then
                return 'sc'
            end
            if lang:find('ja') or lang:find('jpn') or title:find('jp') or title:find('日') then
                return 'jp'
            end
            if lang:find('ko') or lang:find('kor') or title:find('kr') or title:find('韩') then
                return 'kr'
            end
        end
    end
    return 'default'
end

local function apply()
    local codec = mp.get_property('current-tracks/sub/codec') or ''
    local sid = mp.get_property_number('sid') or 0
    if sid <= 0 then return end
    if not (codec:find('ass') or codec:find('ssa')) then return end

    local lang = detect_lang()
    local font = fallback_font[lang] or fallback_font.default

    -- 只覆盖 Fontname，不破坏原字幕颜色/大小/位置/特效。
    -- 如果你想完全尊重内封 ASS 字体，把下一行注释掉即可。
    mp.set_property('sub-ass-force-style', 'Fontname=' .. font)
end

local function trigger()
    mp.add_timeout(0.2, apply)
end

mp.observe_property('sid', 'number', trigger)
mp.observe_property('current-tracks/sub/codec', 'string', trigger)
mp.register_event('file-loaded', trigger)

mp.add_key_binding('ctrl+shift+f', 'assfallback-status', function()
    local lang = detect_lang()
    local font = fallback_font[lang] or fallback_font.default
    local codec = mp.get_property('current-tracks/sub/codec') or 'none'
    mp.osd_message('assfallback\ncodec: ' .. codec .. '\nlang: ' .. lang .. '\nfont: ' .. font, 5)
end)
