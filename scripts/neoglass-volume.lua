-- Neo Glass volume helper
-- Replaces uosc's side volume slider with a compact button + popup menu.

local mp = require('mp')
local utils = require('mp.utils')

local function volume_title()
    local volume = math.floor((mp.get_property_number('volume', 100) or 100) + 0.5)
    local muted = mp.get_property_native('mute')
    if muted then return 'Volume: muted (' .. volume .. '%)' end
    return 'Volume: ' .. volume .. '%'
end

local function open_volume_menu()
    local volume = math.floor((mp.get_property_number('volume', 100) or 100) + 0.5)
    local muted = mp.get_property_native('mute')

    local levels = {0, 25, 50, 75, 100, 125, 150}
    local items = {
        {
            title = muted and 'Unmute' or 'Mute',
            value = 'cycle mute',
            keep_open = true,
        },
        {
            title = 'Volume -5%',
            value = 'add volume -5; show-text "Volume: ${volume}%"',
            keep_open = true,
        },
        {
            title = 'Volume +5%',
            value = 'add volume 5; show-text "Volume: ${volume}%"',
            keep_open = true,
        },
        {title = '---', selectable = false, separator = true},
    }

    for _, level in ipairs(levels) do
        items[#items + 1] = {
            title = tostring(level) .. '%',
            value = 'set volume ' .. tostring(level) .. '; set mute no; show-text "Volume: ${volume}%"',
            active = math.abs(volume - level) <= 2 and not muted,
            keep_open = true,
        }
    end

    local data = {
        type = 'neoglass-volume',
        title = volume_title(),
        items = items,
    }

    mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json(data))
end

mp.register_script_message('neoglass-volume-menu', open_volume_menu)
