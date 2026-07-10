-- Neo Glass speed helper
-- Shows playback speed in the top-left corner when speed changes.
-- Clicking the speed button opens a uosc menu with preset speeds.

local mp = require('mp')
local utils = require('mp.utils')

local presets = {0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0}

local overlay = mp.create_osd_overlay('ass-events')
local hide_timer = nil
local observed_once = false

local function format_speed(speed)
    if not speed then speed = 1 end
    local text = string.format('%.2f', speed)
    text = text:gsub('0+$', ''):gsub('%.$', '')
    return text .. 'x'
end

local function show_speed(speed)
    overlay.data = string.format(
        '{\\an7\\pos(36,34)\\fs30\\b1\\bord1.4\\shad0\\blur0.5\\1c&HFFF2EA&\\3c&H20130D&}Speed: %s',
        format_speed(speed)
    )
    overlay:update()

    if hide_timer then hide_timer:kill() end
    hide_timer = mp.add_timeout(1.2, function()
        overlay:remove()
        hide_timer = nil
    end)
end

local function open_menu()
    local current = mp.get_property_native('speed') or 1

    local items = {
        {
            title = 'Reset to 1x',
            value = 'set speed 1.0; show-text "Speed: 1x"',
            active = math.abs(current - 1.0) < 0.001,
            keep_open = true,
        },
        {title = '---', selectable = false, separator = true},
    }

    for _, speed in ipairs(presets) do
        local label = string.format('%.2f', speed):gsub('0+$', ''):gsub('%.$', '') .. 'x'
        items[#items + 1] = {
            title = label,
            value = 'set speed ' .. tostring(speed) .. '; show-text "Speed: ' .. label .. '"',
            active = math.abs(current - speed) < 0.001,
            keep_open = true,
        }
    end

    local data = {
        type = 'neoglass-speed',
        title = 'Playback speed',
        items = items,
    }

    mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json(data))
end

mp.register_script_message('neoglass-speed-menu', open_menu)

-- Keep backward-compatible message name; now also opens the menu.
mp.register_script_message('neoglass-speed-cycle', open_menu)

mp.register_script_message('neoglass-speed-reset', function()
    mp.set_property_native('speed', 1)
end)

mp.observe_property('speed', 'number', function(_, value)
    if not observed_once then
        observed_once = true
        return
    end
    show_speed(value or 1)
end)