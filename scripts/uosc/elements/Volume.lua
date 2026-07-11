local Element = require('elements/Element')

--[[ VolumeSlider ]]

---@class VolumeSlider : Element
local VolumeSlider = class(Element)
---@param props? ElementProps
function VolumeSlider:new(props) return Class.new(self, props) --[[@as VolumeSlider]] end
function VolumeSlider:init(props)
	Element.init(self, 'volume_slider', props)
	self.pressed = false
	self.nudge_y = 0 -- vertical position where volume overflows 100
	self.nudge_size = 0
	self.draw_nudge = false
	self.spacing = 0
	self.border_size = 0
	self:update_dimensions()
end

function VolumeSlider:update_dimensions()
	self.border_size = math.max(0, round(options.volume_border * state.scale))
end

function VolumeSlider:get_visibility() return Elements.volume:get_visibility(self) end

function VolumeSlider:set_volume(volume)
	volume = round(volume / options.volume_step) * options.volume_step
	if state.volume == volume then return end
	mp.commandv('set', 'volume', clamp(0, volume, state.volume_max))
end

function VolumeSlider:set_from_cursor()
	local volume_fraction = (self.by - cursor.y - self.border_size) / (self.by - self.ay - self.border_size)
	self:set_volume(volume_fraction * state.volume_max)
end

function VolumeSlider:on_display() self:update_dimensions() end
function VolumeSlider:on_options() self:update_dimensions() end
function VolumeSlider:on_coordinates()
	if type(state.volume_max) ~= 'number' or state.volume_max <= 0 then return end
	local width = self.bx - self.ax
	self.nudge_y = self.by - round((self.by - self.ay) * (100 / state.volume_max))
	self.nudge_size = 0 -- Disabled: Neo Glass style uses smooth rounded ends, no nudge.
	self.draw_nudge = false
	self.spacing = round(width * 0.2)
end
function VolumeSlider:on_global_mouse_move()
	if self.pressed then self:set_from_cursor() end
end
function VolumeSlider:handle_wheel_up() self:set_volume(state.volume + options.volume_step) end
function VolumeSlider:handle_wheel_down() self:set_volume(state.volume - options.volume_step) end

function VolumeSlider:render()
	local visibility = self:get_visibility()
	local ax, ay, bx, by = self.ax, self.ay, self.bx, self.by
	local width, height = bx - ax, by - ay

	if width <= 0 or height <= 0 or visibility <= 0 then return end

	cursor:zone('primary_down', self, function()
		self.pressed = true
		self:set_from_cursor()
		cursor:once('primary_up', function() self.pressed = false end)
	end)
	cursor:zone('wheel_down', self, function() self:handle_wheel_down() end)
	cursor:zone('wheel_up', self, function() self:handle_wheel_up() end)

	local ass = assdraw.ass_new()
	local nudge_y, nudge_size = self.draw_nudge and self.nudge_y or -math.huge, self.nudge_size
	local volume_y = self.ay + self.border_size +
		((height - (self.border_size * 2)) * (1 - math.min(state.volume / state.volume_max, 1)))

	-- Neo Glass smooth capsule path.
	-- uosc's original path can develop pointed ends when `state.radius` is
	-- larger than a slim volume bar's half-width. Clamp radius to half-width
	-- and draw a true rounded-rectangle/capsule instead.
	---@param p number Padding from slider edges.
	---@param cy? number Top y coordinate. Defaults to slider top.
	function create_capsule_path(p, cy)
		local x1, y1 = ax + p, cy or ay + p
		local x2, y2 = bx - p, by - p
		local w, h = x2 - x1, y2 - y1
		local path = assdraw.ass_new()
		if w <= 0 or h <= 0 then return path end
		local r = math.max(0, math.min(state.radius, w / 2, h / 2))
		path:round_rect_cw(x1, y1, x2, y2, r)
		return path
	end

	-- BG & FG paths
	local bg_path = create_capsule_path(0)
	local fg_path = create_capsule_path(self.border_size, volume_y)

	-- Background
	ass:new_event()
	ass:append('{\\rDefault\\an7\\blur0\\bord0\\1c&H' .. bg ..
		'\\iclip(' .. fg_path.scale .. ', ' .. fg_path.text .. ')}')
	ass:opacity(config.opacity.slider, visibility)
	ass:pos(0, 0)
	ass:draw_start()
	ass:append(bg_path.text)
	ass:draw_stop()

	-- Foreground
	ass:new_event()
	ass:append('{\\rDefault\\an7\\blur0\\bord0\\1c&H' .. fg .. '}')
	ass:opacity(config.opacity.slider_gauge, visibility)
	ass:pos(0, 0)
	ass:draw_start()
	ass:append(fg_path.text)
	ass:draw_stop()

	-- Current volume value
	local volume_string = tostring(round(state.volume * 10) / 10)
	local font_size = round(((width * 0.6) - (#volume_string * (width / 20))) * options.font_scale)
	if volume_y < self.by - self.spacing then
		ass:txt(self.ax + (width / 2), self.by - self.spacing, 2, volume_string, {
			size = font_size,
			color = fgt,
			opacity = visibility,
			clip = '\\clip(' .. fg_path.scale .. ', ' .. fg_path.text .. ')',
		})
	end
	if volume_y > self.by - self.spacing - font_size then
		ass:txt(self.ax + (width / 2), self.by - self.spacing, 2, volume_string, {
			size = font_size,
			color = bgt,
			opacity = visibility,
			clip = '\\iclip(' .. fg_path.scale .. ', ' .. fg_path.text .. ')',
		})
	end

	-- Disabled stripes for no audio
	if not state.has_audio then
		local fg_100_path = create_nudged_path(self.border_size, state.radius)
		local texture_opts = {
			size = 200,
			color = 'ffffff',
			opacity = visibility * 0.1,
			anchor_x = ax,
			clip = '\\clip(' .. fg_100_path.scale .. ',' .. fg_100_path.text .. ')',
		}
		ass:texture(ax, ay, bx, by, 'a', texture_opts)
		texture_opts.color = '000000'
		texture_opts.anchor_x = ax + texture_opts.size / 28
		ass:texture(ax, ay, bx, by, 'a', texture_opts)
	end

	return ass
end

--[[ Volume ]]

---@class Volume : Element
local Volume = class(Element)

function Volume:new() return Class.new(self) --[[@as Volume]] end
function Volume:init()
	Element.init(self, 'volume', {render_order = 7})
	self.size = 0
	self.mute_ay = 0
	self.slider = VolumeSlider:new({anchor_id = 'volume', render_order = self.render_order})
	self:update_dimensions()
end

function Volume:destroy()
	self.slider:destroy()
	Element.destroy(self)
end

function Volume:get_visibility()
	if not state.is_idle and not state.has_audio then return 0 end
	return self.slider.pressed and 1 or Elements:maybe('timeline', 'get_is_hovered') and -1
		or Element.get_visibility(self)
end

function Volume:update_dimensions()
	self.size = round(options.volume_size * state.scale)
	local min_y = Elements:v('top_bar', 'by') or Elements:v('window_border', 'size', 0)
	local max_y = Elements:v('controls', 'ay') or Elements:v('timeline', 'ay')
		or display.height - Elements:v('window_border', 'size', 0)
	local available_height = max_y - min_y
	local max_height = available_height * 0.8
	local height = round(math.min(self.size * 8, max_height))
	self.enabled = height > self.size * 2 -- don't render if too small
	local margin = (self.size / 2) + Elements:v('window_border', 'size', 0)
	self.ax = round(options.volume == 'left' and margin or display.width - margin - self.size)
	self.ay = min_y + round((available_height - height) / 2)
	self.bx = round(self.ax + self.size)
	self.by = round(self.ay + height)
	self.mute_ay = self.by - self.size
	self.slider.enabled = self.enabled
	self.slider:set_coordinates(self.ax, self.ay, self.bx, self.mute_ay)
end

function Volume:on_display() self:update_dimensions() end
function Volume:on_prop_border() self:update_dimensions() end
function Volume:on_prop_title_bar() self:update_dimensions() end
function Volume:on_prop_volume_max() self:update_dimensions() end
function Volume:on_controls_reflow() self:update_dimensions() end
function Volume:on_options() self:update_dimensions() end

function Volume:render()
	local visibility = self:get_visibility()
	if visibility <= 0 then return end

	-- Reset volume on secondary click
	cursor:zone('secondary_click', self, function()
		mp.set_property_native('mute', false)
		mp.set_property_native('volume', 100)
	end)

	-- Mute button
	local mute_rect = {ax = self.ax, ay = self.mute_ay, bx = self.bx, by = self.by}
	cursor:zone('primary_down', mute_rect, function() mp.commandv('cycle', 'mute') end)
	local ass = assdraw.ass_new()
	local width_half = (mute_rect.bx - mute_rect.ax) / 2
	local height_half = (mute_rect.by - mute_rect.ay) / 2
	local icon_size = math.min(width_half, height_half) * 1.5
	local icon_name, horizontal_shift = 'volume_up', 0
	if state.mute then
		icon_name = 'volume_off'
	elseif state.volume <= 0 then
		icon_name, horizontal_shift = 'volume_mute', height_half * 0.25
	elseif state.volume <= 60 then
		icon_name, horizontal_shift = 'volume_down', height_half * 0.125
	end
	local underlay_opacity = {main = visibility * 0.3, border = visibility}
	ass:icon(mute_rect.ax + width_half, mute_rect.ay + height_half, icon_size, 'volume_up',
		{border = options.text_border * state.scale, opacity = underlay_opacity, align = 5}
	)
	ass:icon(mute_rect.ax + width_half - horizontal_shift, mute_rect.ay + height_half, icon_size, icon_name,
		{opacity = visibility, align = 5}
	)
	return ass
end

return Volume
