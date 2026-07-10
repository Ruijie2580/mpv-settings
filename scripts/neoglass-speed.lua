-- Neo Glass speed helper
-- Shows playback speed in the top-left corner when speed changes.
-- Clicking the speed button opens a uosc menu with preset speeds.
-- The menu updates the highlighted (active) item in real time as the
-- speed changes, including immediately after clicking a preset.

local mp = require('mp')
local utils = require('mp.utils')

local presets = {0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0}

local overlay = mp.create_osd_overlay('ass-events')
local hide_timer = nil
local observed_once = false
local menu_open = false

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

local function build_items(current)
    local items = {
        {
            title = 'Reset to 1x',
            value = 'set speed 1.0',
            active = math.abs(current - 1.0) < 0.001,
            keep_open = true,
        },
        {title = '---', selectable = false, separator = true},
    }

    for _, speed in ipairs(presets) do
        local label = string.format('%.2f', speed):gsub('0+$', ''):gsub('%.$', '') .. 'x'
        items[#items + 1] = {
            title = label,
            value = 'set speed ' .. tostring(speed),
            active = math.abs(current - speed) < 0.001,
            keep_open = true,
        }
    end

    return items
end

local function push_menu_update(current)
    if not menu_open then return end
    local data = {
        type = 'neoglass-speed',
        items = build_items(current),
    }
    mp.commandv('script-message-to', 'uosc', 'update-menu', utils.format_json(data))
end

local function open_menu()
    local current = mp.get_property_native('speed') or 1

    local data = {
        type = 'neoglass-speed',
        title = 'Playback speed',
        items = build_items(current),
        -- uosc forwards menu events (activate / close / ...) back to us.
        callback = {'neoglass-speed', 'neoglass-speed-event'},
    }

    menu_open = true
    mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json(data))
end

-- Handler for events forwarded by uosc while the speed menu is open.
mp.register_script_message('neoglass-speed-event', function(json)
    local event = utils.parse_json(json)
    if not event then return end

    if event.type == 'activate' and event.value then
        -- Run the command bound to the clicked item (e.g. "set speed 1.5").
        mp.command(tostring(event.value))
        -- The speed observer will push a menu update to refresh the highlight.
    elseif event.type == 'close' then
        menu_open = false
    elseif event.type == 'back' then
        menu_open = false
    end
end)

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
    push_menu_update(value or 1)
end)