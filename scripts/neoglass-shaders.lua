-- Neo Glass shader manager
-- Provides toggleable shader building blocks for uosc menu entries.
-- No external process calls.

local mp = require('mp')

local shader_dir = '~~/shaders/'

local shaders = {
    -- Natural scalers
    fsrcnnx_8 = {file = 'FSRCNNX_x2_8-0-4-1.glsl', label = 'FSRCNNX_x2_8-0-4-1.glsl'},
    fsrcnnx_16 = {file = 'FSRCNNX_x2_16-0-4-1.glsl', label = 'FSRCNNX_x2_16-0-4-1.glsl'},

    -- Anime4K protection / preparation
    clamp = {file = 'Anime4K_Clamp_Highlights.glsl', label = 'Anime4K_Clamp_Highlights.glsl'},
    autodown_x2 = {file = 'Anime4K_AutoDownscalePre_x2.glsl', label = 'Anime4K_AutoDownscalePre_x2.glsl'},
    autodown_x4 = {file = 'Anime4K_AutoDownscalePre_x4.glsl', label = 'Anime4K_AutoDownscalePre_x4.glsl'},

    -- Restore line/detail
    restore_vl = {file = 'Anime4K_Restore_CNN_VL.glsl', label = 'Anime4K_Restore_CNN_VL.glsl'},
    restore_ul = {file = 'Anime4K_Restore_CNN_UL.glsl', label = 'Anime4K_Restore_CNN_UL.glsl'},
    restore_l = {file = 'Anime4K_Restore_CNN_L.glsl', label = 'Anime4K_Restore_CNN_L.glsl'},
    restore_m = {file = 'Anime4K_Restore_CNN_M.glsl', label = 'Anime4K_Restore_CNN_M.glsl'},
    restore_s = {file = 'Anime4K_Restore_CNN_S.glsl', label = 'Anime4K_Restore_CNN_S.glsl'},

    -- Softer restore
    restore_soft_vl = {file = 'Anime4K_Restore_CNN_Soft_VL.glsl', label = 'Anime4K_Restore_CNN_Soft_VL.glsl'},
    restore_soft_ul = {file = 'Anime4K_Restore_CNN_Soft_UL.glsl', label = 'Anime4K_Restore_CNN_Soft_UL.glsl'},
    restore_soft_l = {file = 'Anime4K_Restore_CNN_Soft_L.glsl', label = 'Anime4K_Restore_CNN_Soft_L.glsl'},
    restore_soft_m = {file = 'Anime4K_Restore_CNN_Soft_M.glsl', label = 'Anime4K_Restore_CNN_Soft_M.glsl'},
    restore_soft_s = {file = 'Anime4K_Restore_CNN_Soft_S.glsl', label = 'Anime4K_Restore_CNN_Soft_S.glsl'},

    -- Upscale
    upscale_vl = {file = 'Anime4K_Upscale_CNN_x2_VL.glsl', label = 'Anime4K_Upscale_CNN_x2_VL.glsl'},
    upscale_ul = {file = 'Anime4K_Upscale_CNN_x2_UL.glsl', label = 'Anime4K_Upscale_CNN_x2_UL.glsl'},
    upscale_l = {file = 'Anime4K_Upscale_CNN_x2_L.glsl', label = 'Anime4K_Upscale_CNN_x2_L.glsl'},
    upscale_m = {file = 'Anime4K_Upscale_CNN_x2_M.glsl', label = 'Anime4K_Upscale_CNN_x2_M.glsl'},
    upscale_s = {file = 'Anime4K_Upscale_CNN_x2_S.glsl', label = 'Anime4K_Upscale_CNN_x2_S.glsl'},
    upscale_original = {file = 'Anime4K_Upscale_Original_x2.glsl', label = 'Anime4K_Upscale_Original_x2.glsl'},
    upscale_dtd = {file = 'Anime4K_Upscale_DTD_x2.glsl', label = 'Anime4K_Upscale_DTD_x2.glsl'},

    -- Upscale + denoise
    upscale_denoise_vl = {file = 'Anime4K_Upscale_Denoise_CNN_x2_VL.glsl', label = 'Anime4K_Upscale_Denoise_CNN_x2_VL.glsl'},
    upscale_denoise_ul = {file = 'Anime4K_Upscale_Denoise_CNN_x2_UL.glsl', label = 'Anime4K_Upscale_Denoise_CNN_x2_UL.glsl'},
    upscale_denoise_l = {file = 'Anime4K_Upscale_Denoise_CNN_x2_L.glsl', label = 'Anime4K_Upscale_Denoise_CNN_x2_L.glsl'},
    upscale_denoise_m = {file = 'Anime4K_Upscale_Denoise_CNN_x2_M.glsl', label = 'Anime4K_Upscale_Denoise_CNN_x2_M.glsl'},
    upscale_denoise_s = {file = 'Anime4K_Upscale_Denoise_CNN_x2_S.glsl', label = 'Anime4K_Upscale_Denoise_CNN_x2_S.glsl'},

    -- Deblur / denoise / line styling
    deblur_dog = {file = 'Anime4K_Deblur_DoG.glsl', label = 'Anime4K_Deblur_DoG.glsl'},
    deblur_original = {file = 'Anime4K_Deblur_Original.glsl', label = 'Anime4K_Deblur_Original.glsl'},
    denoise_mean = {file = 'Anime4K_Denoise_Bilateral_Mean.glsl', label = 'Anime4K_Denoise_Bilateral_Mean.glsl'},
    denoise_median = {file = 'Anime4K_Denoise_Bilateral_Median.glsl', label = 'Anime4K_Denoise_Bilateral_Median.glsl'},
    denoise_mode = {file = 'Anime4K_Denoise_Bilateral_Mode.glsl', label = 'Anime4K_Denoise_Bilateral_Mode.glsl'},
    thin_hq = {file = 'Anime4K_Thin_HQ.glsl', label = 'Anime4K_Thin_HQ.glsl'},
    darken_hq = {file = 'Anime4K_Darken_HQ.glsl', label = 'Anime4K_Darken_HQ.glsl'},
}

local function path_for(id)
    local item = shaders[id]
    if not item then return nil end
    return shader_dir .. item.file
end

local function label_for(id)
    return shaders[id] and shaders[id].label or id
end

local function split_list(value)
    local list = {}
    value = value or ''
    for item in value:gmatch('[^;]+') do
        item = item:gsub('^%s+', ''):gsub('%s+$', '')
        if item ~= '' then list[#list + 1] = item end
    end
    return list
end

local function basename(path)
    return (path or ''):gsub('\\', '/'):match('([^/]+)$') or path
end

local function current_list()
    return split_list(mp.get_property('glsl-shaders') or '')
end

local function set_list(list)
    mp.set_property('glsl-shaders', table.concat(list, ';'))
end

local function contains_file(list, file)
    for i, path in ipairs(list) do
        if basename(path) == file then return i end
    end
    return nil
end

local function toggle(id)
    local item = shaders[id]
    if not item then
        mp.osd_message('Unknown shader: ' .. tostring(id), 2)
        return
    end

    local list = current_list()
    local index = contains_file(list, item.file)
    if index then
        table.remove(list, index)
        set_list(list)
        mp.osd_message('Shader OFF: ' .. item.label, 1.5)
    else
        list[#list + 1] = path_for(id)
        set_list(list)
        mp.osd_message('Shader ON: ' .. item.label, 1.5)
    end
end

local function clear()
    set_list({})
    mp.osd_message('Shaders cleared', 1.5)
end

local function default_natural()
    set_list({path_for('fsrcnnx_8')})
    mp.osd_message('Shaders: FSRCNNX_x2_8-0-4-1.glsl', 1.5)
end

local function set_preset(name)
    local preset = {
        natural = {'fsrcnnx_8'},
        quality = {'fsrcnnx_16'},
        anime4k_a = {'clamp', 'restore_vl', 'upscale_vl', 'autodown_x2', 'autodown_x4', 'upscale_m'},
        anime4k_b_soft = {'clamp', 'restore_soft_vl', 'upscale_vl', 'autodown_x2', 'autodown_x4', 'upscale_m'},
        anime4k_c_denoise = {'clamp', 'upscale_denoise_vl', 'autodown_x2', 'autodown_x4', 'upscale_m'},
        anime4k_aa = {'clamp', 'restore_vl', 'upscale_vl', 'restore_m', 'autodown_x2', 'autodown_x4', 'upscale_m'},
    }

    local ids = preset[name]
    if not ids then
        mp.osd_message('Unknown preset: ' .. tostring(name), 2)
        return
    end

    local list, labels = {}, {}
    for _, id in ipairs(ids) do
        list[#list + 1] = path_for(id)
        labels[#labels + 1] = label_for(id)
    end
    set_list(list)
    mp.osd_message('Shader preset: ' .. name, 1.5)
end

local function show_current()
    local list = current_list()
    if #list == 0 then
        mp.osd_message('Shaders: none', 3)
        return
    end

    local names = {}
    for _, path in ipairs(list) do names[#names + 1] = basename(path) end
    mp.osd_message('Shaders:\n' .. table.concat(names, '\n'), 5)
end

mp.register_script_message('shader-toggle', toggle)
mp.register_script_message('shader-clear', clear)
mp.register_script_message('shader-default-natural', default_natural)
mp.register_script_message('shader-preset', set_preset)
mp.register_script_message('shader-show-current', show_current)
