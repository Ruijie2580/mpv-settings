-- Neo Glass volume helper
-- Compact volume button opens a traditional thin horizontal draggable slider.
-- Mouse bindings are active only while the slider is visible.
-- No external process calls.

local mp = require('mp')

local overlay = mp.create_osd_overlay('ass-events')
local visible = false
local dragging = false
local bindings_active = false
local hide_timer = nil
local mouse = {x = -1, y = -1}

local rect = {x = 0, y = 0, w = 0, h = 0, track_x = 0, track_y = 0, track_w = 0, track_h = 0}

local hide
local arm_hide_timer
local toggle

local function clamp(min, val, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

local function get_osd_size()
    local w, h = mp.get_osd_size()
    if not w or w <= 0 then w = 1280 end
    if not h or h <= 0 then h = 720 end
    return w, h
end

local function update_rect()
    local w, h = get_osd_size()
    local scale = math.max(1, math.min(w / 1920, h / 1080))
    rect.w = math.floor(270 * scale)
    rect.h = math.floor(38 * scale)
    rect.x = math.floor(w - rect.w - 34 * scale)
    rect.y = math.floor(h - 112 * scale)
    rect.track_x = math.floor(rect.x + 52 * scale)
    rect.track_y = math.floor(rect.y + 19 * scale)
    rect.track_w = math.floor(rect.w - 86 * scale)
    rect.track_h = math.max(2, math.floor(3 * scale))
end

local function contains(x, y)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function set_volume_from_x(x)
    local volume_max = mp.get_property_number('volume-max', 150) or 150
    local frac = clamp(0, (x - rect.track_x) / rect.track_w, 1)
    local vol = math.floor(frac * volume_max + 0.5)
    mp.set_property_number('volume', vol)
    if vol > 0 then mp.set_property_bool('mute', false) end
end

local function render()
    if not visible then return end
    update_rect()

    local volume = mp.get_property_number('volume', 100) or 100
    local volume_max = mp.get_property_number('volume-max', 150) or 150
    local muted = mp.get_property_bool('mute')
    local frac = clamp(0, volume / volume_max, 1)
    local knob_x = rect.track_x + rect.track_w * frac

    local label = muted and 'MUTE' or (tostring(math.floor(volume + 0.5)) .. '%')

    -- ASS colors are BGR hex.
    local bg = '&H20130D&'
    local fg = '&HFFB48A&'
    local dim = '&H6B5140&'
    local text = '&HFFF2EA&'

    local ass = {}
    local function add(s) ass[#ass + 1] = s end

    add('{\\an7\\pos(0,0)\\bord0\\shad0\\blur0}')

    -- Subtle glass rectangle.
    add(string.format('{\\1c%s\\alpha&H78&\\p1}m %d %d l %d %d l %d %d l %d %d{\\p0}',
        bg, rect.x, rect.y, rect.x + rect.w, rect.y, rect.x + rect.w, rect.y + rect.h, rect.x, rect.y + rect.h))

    -- Text labels.
    add(string.format('{\\an7\\pos(%d,%d)\\fs16\\b1\\bord0\\1c%s}VOL', rect.x + 13, rect.y + 10, text))
    add(string.format('{\\an9\\pos(%d,%d)\\fs15\\bord0\\1c%s}%s', rect.x + rect.w - 10, rect.y + 10, text, label))

    -- Track background.
    add(string.format('{\\1c%s\\alpha&H35&\\p1}m %d %d l %d %d l %d %d l %d %d{\\p0}',
        dim,
        rect.track_x, rect.track_y - rect.track_h / 2,
        rect.track_x + rect.track_w, rect.track_y - rect.track_h / 2,
        rect.track_x + rect.track_w, rect.track_y + rect.track_h / 2,
        rect.track_x, rect.track_y + rect.track_h / 2))

    -- Filled track.
    add(string.format('{\\1c%s\\alpha&H00&\\p1}m %d %d l %d %d l %d %d l %d %d{\\p0}',
        fg,
        rect.track_x, rect.track_y - rect.track_h / 2,
        knob_x, rect.track_y - rect.track_h / 2,
        knob_x, rect.track_y + rect.track_h / 2,
        rect.track_x, rect.track_y + rect.track_h / 2))

    -- Small draggable knob.
    local r = 6
    add(string.format('{\\1c%s\\alpha&H00&\\p1}m %d %d b %d %d %d %d %d %d b %d %d %d %d %d %d b %d %d %d %d %d %d b %d %d %d %d %d %d{\\p0}',
        fg,
        knob_x, rect.track_y - r,
        knob_x + r * 0.55, rect.track_y - r, knob_x + r, rect.track_y - r * 0.55, knob_x + r, rect.track_y,
        knob_x + r, rect.track_y + r * 0.55, knob_x + r * 0.55, rect.track_y + r, knob_x, rect.track_y + r,
        knob_x - r * 0.55, rect.track_y + r, knob_x - r, rect.track_y + r * 0.55, knob_x - r, rect.track_y,
        knob_x - r, rect.track_y - r * 0.55, knob_x - r * 0.55, rect.track_y - r, knob_x, rect.track_y - r))

    overlay.data = table.concat(ass, '')
    overlay:update()
end

local function deactivate_bindings()
    if not bindings_active then return end
    mp.remove_key_binding('neoglass-volume-left')
    mp.remove_key_binding('neoglass-volume-wheel-up')
    mp.remove_key_binding('neoglass-volume-wheel-down')
    mp.remove_key_binding('neoglass-volume-esc')
    bindings_active = false
end

local function activate_bindings()
    if bindings_active then return end
    bindings_active = true

    mp.add_forced_key_binding('MBTN_LEFT', 'neoglass-volume-left', function(event)
        if not visible then return end
        update_rect()
        if event and event.event == 'down' and contains(mouse.x, mouse.y) then
            dragging = true
            set_volume_from_x(mouse.x)
            render()
            if hide_timer then hide_timer:kill() end
        elseif event and event.event == 'up' then
            if dragging then
                dragging = false
                arm_hide_timer()
            end
        end
    end, {complex = true})

    mp.add_forced_key_binding('WHEEL_UP', 'neoglass-volume-wheel-up', function()
        if visible and contains(mouse.x, mouse.y) then
            mp.commandv('add', 'volume', '2')
            mp.set_property_bool('mute', false)
            render()
            arm_hide_timer()
        end
    end)

    mp.add_forced_key_binding('WHEEL_DOWN', 'neoglass-volume-wheel-down', function()
        if visible and contains(mouse.x, mouse.y) then
            mp.commandv('add', 'volume', '-2')
            render()
            arm_hide_timer()
        end
    end)

    mp.add_forced_key_binding('ESC', 'neoglass-volume-esc', function()
        if visible then hide() end
    end)
end

hide = function()
    visible = false
    dragging = false
    overlay:remove()
    deactivate_bindings()
end

arm_hide_timer = function()
    if hide_timer then hide_timer:kill() end
    hide_timer = mp.add_timeout(3.0, function()
        if not dragging then hide() end
    end)
end

local function show()
    visible = true
    activate_bindings()
    render()
    arm_hide_timer()
end

toggle = function()
    if visible then hide() else show() end
end

mp.observe_property('mouse-pos', 'native', function(_, pos)
    if not pos then return end
    mouse.x, mouse.y = pos.x or -1, pos.y or -1
    if visible and dragging then
        set_volume_from_x(mouse.x)
        render()
    end
end)

mp.observe_property('volume', 'number', function() if visible then render() end end)
mp.observe_property('mute', 'bool', function() if visible then render() end end)

-- Keep old message name for compatibility with uosc.conf.
mp.register_script_message('neoglass-volume-menu', toggle)
mp.register_script_message('neoglass-volume-toggle', toggle)
