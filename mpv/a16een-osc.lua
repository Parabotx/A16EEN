-- A16EEN MPV controls
-- Minimal rounded on-screen controls. Runs only for files with a video track.

local mp = require "mp"

local overlay = mp.create_osd_overlay("ass-events")
local accent = "#D7B56D"
local ink = "#15171A"
local paper = "#F1F3F6"
local muted = "#9CA3AF"

local visible = false
local tick_timer = nil
local last_activity = 0
local mouse = { x = -10000, y = -10000, hover = false }
local areas = {}

local function has_video()
    local vid = mp.get_property_native("vid")
    if vid == nil or vid == "no" then return false end
    if type(vid) == "number" and vid <= 0 then return false end
    return true
end

local function inside(x, y, area)
    return area and x >= area.x1 and x <= area.x2 and y >= area.y1 and y <= area.y2
end

local function point_on_bar(x, y)
    return inside(x, y, areas.bar)
end

local function ass_color(hex)
    local r = tonumber(hex:sub(2, 3), 16)
    local g = tonumber(hex:sub(4, 5), 16)
    local b = tonumber(hex:sub(6, 7), 16)
    return string.format("%02X%02X%02X", b, g, r)
end

local function escape_ass(value)
    local text = tostring(value or "")
    local ok, escaped = pcall(mp.command_native, { "escape-ass", text })
    if ok and type(escaped) == "string" then return escaped end
    return text:gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}")
end

local function rounded_path(w, h, radius)
    local r = math.max(0, math.min(radius, math.floor(math.min(w, h) / 2)))
    local k = math.floor(r * 0.552 + 0.5)
    return string.format(
        "m %d 0 l %d 0 b %d 0 %d %d %d %d l %d %d b %d %d %d %d %d %d l %d %d b %d %d %d %d %d %d l 0 %d b 0 %d %d 0 %d 0 l %d 0",
        r, w - r,
        w - r + k, w, r - k, w, r,
        w, h - r,
        w, h - r + k, w - k, h, w - r, h,
        r, h,
        r - k, h, 0, h - k, 0, h - r,
        r, r - k, r - k, r, r
    )
end

local function add_round(lines, x, y, w, h, radius, color, alpha)
    if w < 1 or h < 1 then return end
    local path = rounded_path(w, h, radius)
    lines[#lines + 1] = string.format(
        "{\\an7\\pos(%d,%d)\\p1\\bord0\\shad0\\1c&H%s&\\1a&H%02X&}%s{\\p0}",
        math.floor(x), math.floor(y), ass_color(color), alpha or 0, path
    )
end

local function add_text(lines, x, y, text, size, color, align, bold, clip)
    local clip_tag = ""
    if clip then
        clip_tag = string.format("\\clip(%d,%d,%d,%d)", clip.x1, clip.y1, clip.x2, clip.y2)
    end
    lines[#lines + 1] = string.format(
        "{\\an%d\\pos(%d,%d)\\fnInter\\fs%d\\b%d\\bord0\\shad0\\blur0\\1c&H%s&%s}%s",
        align or 7, math.floor(x), math.floor(y), size, bold and 1 or 0,
        ass_color(color), clip_tag, escape_ass(text)
    )
end

local function format_time(value)
    local seconds = math.max(0, math.floor(tonumber(value) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local rest = seconds % 60
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, rest)
    end
    return string.format("%d:%02d", minutes, rest)
end

local function current_mouse()
    local pos = mp.get_property_native("mouse-pos")
    if type(pos) == "table" then
        return tonumber(pos.x) or mouse.x, tonumber(pos.y) or mouse.y, pos.hover ~= false
    end
    return mouse.x, mouse.y, mouse.hover
end

local function draw_button(lines, name, cx, cy, w, h, label, size, text_color, fill, alpha, mx, my, hovering)
    local x, y = cx - w / 2, cy - h / 2
    areas[name] = { x1 = x - 3, y1 = y - 3, x2 = x + w + 3, y2 = y + h + 3 }
    local is_hovered = hovering and inside(mx, my, areas[name])
    if fill then
        add_round(lines, x, y, w, h, math.floor(h / 2), fill, alpha or 0)
    elseif is_hovered then
        add_round(lines, x, y, w, h, math.floor(h / 2), "#FFFFFF", 0xE2)
    end
    add_text(lines, cx, cy, label, size, text_color, 5, false)
end

local function render()
    if not visible or not has_video() then return end

    local width, height = mp.get_osd_size()
    if not width or not height or width < 160 or height < 120 then return end

    local w = math.min(1080, width - 32)
    local h = 108
    local x = math.floor((width - w) / 2)
    local y = math.floor(height - h - 24)
    local cx = x + w / 2
    local compact = width < 760
    local tiny = width < 520
    local mx, my, hovering = current_mouse()
    local lines = {}
    areas = {
        bar = { x1 = x, y1 = y, x2 = x + w, y2 = y + h },
    }

    overlay.res_x = width
    overlay.res_y = height

    -- Fine outline with a deep, slightly translucent interior.
    add_round(lines, x, y, w, h, 20, "#FFFFFF", 0xE9)
    add_round(lines, x + 1, y + 1, w - 2, h - 2, 19, "#15171A", 0x16)
    add_round(lines, x + 22, y + 73, w - 44, 3, 2, "#FFFFFF", 0xE8)

    local duration = math.max(0, mp.get_property_number("duration", 0))
    local position = math.max(0, mp.get_property_number("time-pos", 0))
    local ratio = duration > 0 and math.max(0, math.min(1, position / duration)) or 0
    local progress_x = x + 22
    local progress_w = w - 44
    local active_w = math.max(0, progress_w * ratio)
    if active_w > 1 then
        add_round(lines, progress_x, y + 73, active_w, 3, 2, accent, 0x00)
        add_round(lines, progress_x + active_w - 4, y + 70, 9, 9, 5, accent, 0x00)
    end
    areas.seek = { x1 = progress_x, y1 = y + 67, x2 = progress_x + progress_w, y2 = y + 81 }

    local title = mp.get_property("media-title", "")
    if title == "" then title = mp.get_property("filename", "A16EEN Player") end
    title = title:gsub("[\r\n]", " ")
    local artist = ""
    local metadata = mp.get_property_native("metadata", {})
    if type(metadata) == "table" then
        artist = tostring(metadata.artist or metadata.ARTIST or metadata.album_artist or metadata.ALBUM_ARTIST or "")
    end
    artist = artist:gsub("[\r\n]", " ")
    if artist == "" then artist = "A16EEN Player" end

    local title_clip_right = math.min(x + math.floor(w * 0.38), cx - (compact and 90 or 108))
    local title_clip = { x1 = x + 18, y1 = y + 8, x2 = math.max(x + 90, title_clip_right), y2 = y + 58 }
    add_text(lines, x + 22, y + 15, title, tiny and 14 or 17, paper, 7, true, title_clip)
    if not tiny then
        add_text(lines, x + 22, y + 39, artist, 11, muted, 7, false, title_clip)
    end

    local cy = y + 37
    local gap = compact and 58 or 70
    draw_button(lines, "rewind", cx - gap, cy, 34, 34, "−10", 10, paper, nil, 0xE2, mx, my, hovering)

    local paused = mp.get_property_bool("pause", false)
    draw_button(lines, "play", cx, cy, 40, 40, paused and "▶" or "Ⅱ", 16, ink, accent, 0x00, mx, my, hovering)
    draw_button(lines, "forward", cx + gap, cy, 34, 34, "+10", 10, paper, nil, 0xE2, mx, my, hovering)

    -- Keep secondary controls quiet; shrink the group on narrow windows.
    local right_items
    if tiny then
        right_items = { "volume", "fullscreen" }
    elseif compact then
        right_items = { "subtitle", "audio", "volume", "fullscreen" }
    else
        right_items = { "subtitle", "audio", "speed", "volume", "fullscreen" }
    end
    local labels = {
        subtitle = "CC",
        audio = "♫",
        speed = string.format("%.2g×", mp.get_property_number("speed", 1)),
        volume = mp.get_property_bool("mute", false) and "×" or "◖",
        fullscreen = "⛶",
    }
    local button_w, button_h, spacing = 30, 30, 8
    local group_w = #right_items * button_w + (#right_items - 1) * spacing
    local start_cx = x + w - 20 - group_w + button_w / 2
    for i, name in ipairs(right_items) do
        local bx = start_cx + (i - 1) * (button_w + spacing)
        local size = (name == "speed" or name == "subtitle") and 9 or 14
        draw_button(
            lines, name, bx, cy, button_w, button_h, labels[name],
            size,
            mp.get_property_bool("mute", false) and name == "volume" and accent or paper,
            nil, 0xE2, mx, my, hovering
        )
    end

    add_text(lines, x + 22, y + 84, format_time(position), 10, muted, 7, false)
    add_text(lines, x + w - 22, y + 84, format_time(duration), 10, muted, 1, false)

    overlay.data = table.concat(lines, "\n")
    overlay:update()
end

local function hide_controls()
    visible = false
    if tick_timer then
        tick_timer:kill()
        tick_timer = nil
    end
    overlay:remove()
end

local function show_controls()
    if not has_video() then return end
    visible = true
    last_activity = mp.get_time()
    if not tick_timer then
        tick_timer = mp.add_periodic_timer(0.16, function()
            if not visible then return end
            local mx, my, hovering = current_mouse()
            if mp.get_time() - last_activity > 2.8 and not (hovering and point_on_bar(mx, my)) then
                hide_controls()
                return
            end
            render()
        end)
    end
    render()
end

local function seek_by(amount)
    local duration = mp.get_property_number("duration", 0)
    local position = mp.get_property_number("time-pos", 0)
    if duration > 0 then
        mp.set_property_number("time-pos", math.max(0, math.min(duration, position + amount)))
    else
        mp.commandv("seek", amount, "relative")
    end
end

local function activate(name)
    if name == "rewind" then
        seek_by(-10)
    elseif name == "play" then
        mp.set_property_bool("pause", not mp.get_property_bool("pause", false))
    elseif name == "forward" then
        seek_by(10)
    elseif name == "subtitle" then
        mp.commandv("cycle", "sid")
    elseif name == "audio" then
        mp.commandv("cycle", "aid")
    elseif name == "volume" then
        mp.set_property_bool("mute", not mp.get_property_bool("mute", false))
    elseif name == "fullscreen" then
        mp.set_property_bool("fullscreen", not mp.get_property_bool("fullscreen", false))
    elseif name == "speed" then
        local speeds = { 0.75, 1.0, 1.25, 1.5, 2.0 }
        local current = mp.get_property_number("speed", 1)
        local next_index = 1
        for i, speed in ipairs(speeds) do
            if math.abs(speed - current) < 0.02 then
                next_index = (i % #speeds) + 1
                break
            end
        end
        mp.set_property_number("speed", speeds[next_index])
    end
    show_controls()
end

local function on_click()
    local mx, my, hovering = current_mouse()
    if not hovering then return end
    if not visible then
        show_controls()
        mp.commandv("cycle", "pause")
        return
    end

    last_activity = mp.get_time()
    for _, name in ipairs({ "rewind", "play", "forward", "subtitle", "audio", "speed", "volume", "fullscreen" }) do
        if inside(mx, my, areas[name]) then
            activate(name)
            return
        end
    end

    if inside(mx, my, areas.seek) then
        local duration = mp.get_property_number("duration", 0)
        if duration > 0 then
            local ratio = math.max(0, math.min(1, (mx - areas.seek.x1) / (areas.seek.x2 - areas.seek.x1)))
            mp.set_property_number("time-pos", duration * ratio)
        end
        show_controls()
        return
    end

    -- Preserve the expected click-to-pause behavior outside the controls.
    mp.commandv("cycle", "pause")
    show_controls()
end

mp.add_key_binding("MBTN_LEFT", "a16een-mpv-click", on_click)
mp.add_key_binding("MBTN_LEFT_DBL", "a16een-mpv-double-click", function()
    mp.set_property_bool("fullscreen", not mp.get_property_bool("fullscreen", false))
    show_controls()
end)

mp.observe_property("mouse-pos", "native", function(_, value)
    if type(value) ~= "table" then return end
    local new_x, new_y = tonumber(value.x), tonumber(value.y)
    if not new_x or not new_y then return end

    local moved = new_x ~= mouse.x or new_y ~= mouse.y or (value.hover ~= false and not mouse.hover)
    mouse = { x = new_x, y = new_y, hover = value.hover ~= false }

    if not mouse.hover then
        hide_controls()
    elseif moved and has_video() then
        show_controls()
    end
end)

mp.register_event("file-loaded", function()
    if has_video() then show_controls() else hide_controls() end
end)
mp.register_event("end-file", hide_controls)
mp.register_event("shutdown", hide_controls)
mp.register_event("video-reconfig", function()
    if visible then render() end
end)
mp.observe_property("pause", "bool", function()
    if visible then render() end
end)
mp.observe_property("fullscreen", "bool", function()
    if visible then render() end
end)
