-- Neo Glass speed helper
-- Shows playback speed in the top-left corner when speed changes.

local mp = require('mp')

local speeds = {0.75, 1.0, 1.25, 1.5, 2.0}
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

local function nearest_next_speed(current)
    current = tonumber(current) or 1
    for _, speed in ipairs(speeds) do
        if speed > current + 0.001 then return speed end
    end
    return speeds[1]
end

mp.register_script_message('neoglass-speed-cycle', function()
    local current = mp.get_property_native('speed') or 1
    mp.set_property_native('speed', nearest_next_speed(current))
end)

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
