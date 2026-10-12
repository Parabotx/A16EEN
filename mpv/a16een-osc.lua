-- A16EEN MPV controls
-- Separate rounded containers inspired by the A16EEN navbar.
-- Video-only UI: the hidden audio player used by the Music widget is untouched.

local mp = require "mp"

local overlay = mp.create_osd_overlay("ass-events")
local accent = "#D7B56D"
local ink = "#15171A"
local paper = "#F1F3F6"
local muted = "#9CA3AF"
local soft = "#5D6674"

local visible = false
local tick_timer = nil
local last_activity = 0
local mouse = { x = -10000, y = -10000, hover = false }
local areas = {}
local control_names = {
    "chapter_prev", "rewind", "play", "forward", "chapter_next",
    "subtitle", "audio", "speed", "mute", "loop", "screenshot", "fullscreen"
}

local function has_video()
    local vid = mp.get_property_native("vid")
    if vid == nil or vid == "no" then return false end
    if type(vid) == "number" and vid <= 0 then return false end
    return true
end

local function inside(x, y, area)
    return area and x >= area.x1 and x <= area.x2 and y >= area.y1 and y <= area.y2
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
    return text:gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}"):gsub("[\r\n]", " ")
end

local function rounded_path(w, h, radius)
    -- ASS vector drawing uses integer coordinates; progress fills may be fractional.
    w = math.floor(w)
    h = math.floor(h)
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
    lines[#lines + 1] = string.format(
        "{\\an7\\pos(%d,%d)\\p1\\bord0\\shad0\\1c&H%s&\\1a&H%02X&}%s{\\p0}",
        math.floor(x), math.floor(y), ass_color(color), alpha or 0, rounded_path(w, h, radius)
    )
end

local function add_card(lines, x, y, w, h, radius)
    -- A quiet 1px outline around a near-opaque dark surface.
    add_round(lines, x, y, w, h, radius, "#FFFFFF", 0xE7)
    add_round(lines, x + 1, y + 1, w - 2, h - 2, math.max(2, radius - 1), "#111318", 0x12)
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
    if hours > 0 then return string.format("%d:%02d:%02d", hours, minutes, rest) end
    return string.format("%d:%02d", minutes, rest)
end

local function current_mouse()
    local pos = mp.get_property_native("mouse-pos")
    if type(pos) == "table" then
        return tonumber(pos.x) or mouse.x, tonumber(pos.y) or mouse.y, pos.hover ~= false
    end
    return mouse.x, mouse.y, mouse.hover
end

local function hovered(name, mx, my, hovering)
    return hovering and inside(mx, my, areas[name])
end

local function draw_button(lines, name, cx, cy, w, h, label, size, opts)
    opts = opts or {}
    local x, y = cx - w / 2, cy - h / 2
    areas[name] = { x1 = x - 4, y1 = y - 4, x2 = x + w + 4, y2 = y + h + 4 }

    local is_hovered = hovered(name, opts.mx or -10000, opts.my or -10000, opts.hovering or false)
    if opts.active then
        add_round(lines, x, y, w, h, math.floor(h / 2), opts.active_color or accent, 0x00)
        add_text(lines, cx, cy, label, size, opts.active_text or ink, 5, opts.bold or false)
    elseif is_hovered then
        add_round(lines, x, y, w, h, math.floor(h / 2), "#FFFFFF", 0xE2)
        add_text(lines, cx, cy, label, size, paper, 5, opts.bold or false)
    else
        add_text(lines, cx, cy, label, size, opts.color or paper, 5, opts.bold or false)
    end
end

local function draw_volume_slider(lines, x, y, w, volume, mx, my, hovering)
    local track_x = x + 65
    local track_w = math.max(24, w - 82)
    local track_y = y + 55
    areas.volume = { x1 = track_x - 5, y1 = track_y - 8, x2 = track_x + track_w + 5, y2 = track_y + 8, track_x = track_x, track_w = track_w }

    add_text(lines, x + 13, track_y - 5, "VOL", 8, muted, 7, true)
    add_round(lines, track_x, track_y, track_w, 3, 2, "#FFFFFF", 0xD7)
    local ratio = math.max(0, math.min(1, (tonumber(volume) or 0) / 130))
    if ratio > 0 then
        add_round(lines, track_x, track_y, math.max(2, track_w * ratio), 3, 2, accent, 0)
    end
    local knob_x = track_x + track_w * ratio
    add_round(lines, knob_x - 4, track_y - 3, 8, 9, 4, accent, 0)
    if hovering and inside(mx, my, areas.volume) then
        add_text(lines, x + w - 12, track_y - 5, tostring(math.floor(volume + 0.5)) .. "%", 8, paper, 9, false)
    end
end

local function render()
    if not visible or not has_video() then return end

    local width, height = mp.get_osd_size()
    if not width or not height or width < 300 or height < 160 then return end

    local total_w = math.min(1020, width - 28)
    local card_h = 74
    local gap = 10
    local tiny = width < 760
    local compact = width < 1020
    local row_x = math.floor((width - total_w) / 2)
    local row_y = math.floor(height - card_h - 25)
    local mx, my, hovering = current_mouse()
    local lines = {}

    local info_w = tiny and 0 or math.min(270, math.max(205, math.floor(total_w * 0.28)))
    local transport_w = tiny and math.min(224, total_w - 150) or math.min(270, math.max(230, math.floor(total_w * 0.27)))
    local tool_x
    local tool_w
    local info_x = row_x
    local transport_x

    if tiny then
        transport_x = row_x
        tool_x = transport_x + transport_w + gap
        tool_w = total_w - transport_w - gap
    else
        transport_x = info_x + info_w + gap
        tool_x = transport_x + transport_w + gap
        tool_w = total_w - info_w - transport_w - gap * 2
    end
    tool_w = math.max(0, tool_w)

    local progress_w = math.min(620, total_w - 20)
    local progress_h = 29
    local progress_x = math.floor((width - progress_w) / 2)
    local progress_y = row_y - progress_h - 9

    areas = {
        ui = { x1 = row_x, y1 = progress_y, x2 = row_x + total_w, y2 = row_y + card_h },
        row = { x1 = row_x, y1 = row_y, x2 = row_x + total_w, y2 = row_y + card_h }
    }
    overlay.res_x = width
    overlay.res_y = height

    -- Timeline is its own floating capsule, separated from the control cards.
    add_card(lines, progress_x, progress_y, progress_w, progress_h, 14)
    local duration = math.max(0, mp.get_property_number("duration", 0))
    local position = math.max(0, mp.get_property_number("time-pos", 0))
    local ratio = duration > 0 and math.max(0, math.min(1, position / duration)) or 0
    local time_left = duration > 0 and ("-" .. format_time(math.max(0, duration - position))) or "--:--"
    add_text(lines, progress_x + 12, progress_y + 8, format_time(position), 9, muted, 7, false)
    add_text(lines, progress_x + progress_w - 12, progress_y + 8, time_left, 9, muted, 9, false)
    local seek_x = progress_x + 78
    local seek_w = math.max(24, progress_w - 156)
    local seek_y = progress_y + 13
    add_round(lines, seek_x, seek_y, seek_w, 3, 2, "#FFFFFF", 0xD7)
    local played_w = seek_w * ratio
    if played_w > 1 then
        add_round(lines, seek_x, seek_y, played_w, 3, 2, accent, 0)
        add_round(lines, seek_x + played_w - 3, seek_y - 3, 8, 9, 4, accent, 0)
    end
    areas.seek = { x1 = seek_x - 6, y1 = progress_y + 2, x2 = seek_x + seek_w + 6, y2 = progress_y + progress_h - 2 }

    -- Container 1: title and file context, omitted on narrow windows.
    local title = mp.get_property("media-title", "")
    if title == "" then title = mp.get_property("filename", "A16EEN Player") end
    title = title:gsub("[\r\n]", " ")
    local metadata = mp.get_property_native("metadata", {})
    local artist = ""
    if type(metadata) == "table" then
        artist = tostring(metadata.artist or metadata.ARTIST or metadata.album_artist or metadata.ALBUM_ARTIST or "")
    end
    artist = artist:gsub("[\r\n]", " ")
    if artist == "" then artist = mp.get_property("filename", "VIDEO") end
    if not tiny then
        add_card(lines, info_x, row_y, info_w, card_h, 18)
        add_text(lines, info_x + 16, row_y + 10, "NOW PLAYING", 8, accent, 7, true)
        local clip = { x1 = info_x + 12, y1 = row_y + 18, x2 = info_x + info_w - 12, y2 = row_y + 47 }
        add_text(lines, info_x + 16, row_y + 25, title, 14, paper, 7, true, clip)
        add_text(lines, info_x + 16, row_y + 50, artist, 9, muted, 7, false, clip)
    end

    -- Container 2: dedicated playback cluster, with chapters and precise seeking.
    add_card(lines, transport_x, row_y, transport_w, card_h, 18)
    local transport_cy = row_y + 32
    local transport_items
    if transport_w < 195 then
        transport_items = { "rewind", "play", "forward" }
    else
        transport_items = { "chapter_prev", "rewind", "play", "forward", "chapter_next" }
    end
    local transport_button_w = transport_w < 195 and 31 or 29
    local transport_gap = transport_w < 195 and 9 or 5
    local transport_group_w = #transport_items * transport_button_w + (#transport_items - 1) * transport_gap
    local transport_start = transport_x + (transport_w - transport_group_w) / 2 + transport_button_w / 2
    local paused = mp.get_property_bool("pause", false)
    local transport_labels = {
        chapter_prev = "‹|", rewind = "−10", play = paused and "▶" or "Ⅱ",
        forward = "+10", chapter_next = "|›"
    }
    for i, name in ipairs(transport_items) do
        local bx = transport_start + (i - 1) * (transport_button_w + transport_gap)
        local active = name == "play"
        draw_button(lines, name, bx, transport_cy, transport_button_w, 34,
            transport_labels[name], name == "play" and 14 or (name == "rewind" or name == "forward") and 9 or 12,
            { active = active, color = muted, bold = false, mx = mx, my = my, hovering = hovering })
    end
    add_text(lines, transport_x + transport_w / 2, row_y + 56, "PLAYBACK", 8, soft, 5, true)

    -- Container 3: compact tools. Advanced controls are hidden at small widths.
    add_card(lines, tool_x, row_y, tool_w, card_h, 18)
    local items
    if tool_w < 205 then
        items = { "subtitle", "mute", "fullscreen" }
    elseif tiny or compact then
        items = { "subtitle", "audio", "speed", "mute", "fullscreen" }
    else
        items = { "subtitle", "audio", "speed", "mute", "loop", "screenshot", "fullscreen" }
    end
    local labels = {
        subtitle = "CC",
        audio = "♪",
        speed = string.format("%.2g×", mp.get_property_number("speed", 1)),
        mute = mp.get_property_bool("mute", false) and "×" or "◖",
        loop = "↻",
        screenshot = "▣",
        fullscreen = mp.get_property_bool("fullscreen", false) and "↙" or "⛶"
    }
    local button_w = tool_w < 205 and 30 or 28
    local button_gap = tool_w < 205 and 8 or 4
    local group_w = #items * button_w + (#items - 1) * button_gap
    local start_cx = tool_x + (tool_w - group_w) / 2 + button_w / 2
    local loop_enabled = mp.get_property("loop-file", "no") == "inf"
    for i, name in ipairs(items) do
        local bx = start_cx + (i - 1) * (button_w + button_gap)
        local active = (name == "loop" and loop_enabled)
            or (name == "subtitle" and mp.get_property_number("sid", -1) >= 0)
            or (name == "mute" and mp.get_property_bool("mute", false))
        draw_button(lines, name, bx, row_y + 25, button_w, 29, labels[name],
            (name == "speed" or name == "subtitle") and 9 or 13,
            { active = active, active_color = active and name == "mute" and "#E7A2A2" or accent,
              active_text = ink, color = name == "speed" and accent or paper,
              mx = mx, my = my, hovering = hovering })
    end

    local volume = math.max(0, math.min(130, mp.get_property_number("volume", 100)))
    draw_volume_slider(lines, tool_x, row_y, tool_w, volume, mx, my, hovering)

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

local function point_on_ui(x, y)
    return inside(x, y, areas.ui)
end

local function show_controls()
    if not has_video() then return end
    visible = true
    last_activity = mp.get_time()
    if not tick_timer then
        tick_timer = mp.add_periodic_timer(0.20, function()
            if not visible then return end
            local mx, my, hovering = current_mouse()
            if mp.get_time() - last_activity > 2.6 and not (hovering and point_on_ui(mx, my)) then
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
    if name == "chapter_prev" then
        mp.commandv("add", "chapter", "-1")
    elseif name == "rewind" then
        seek_by(-10)
    elseif name == "play" then
        mp.set_property_bool("pause", not mp.get_property_bool("pause", false))
    elseif name == "forward" then
        seek_by(10)
    elseif name == "chapter_next" then
        mp.commandv("add", "chapter", "1")
    elseif name == "subtitle" then
        mp.commandv("cycle", "sid")
    elseif name == "audio" then
        mp.commandv("cycle", "aid")
    elseif name == "speed" then
        local speeds = { 0.5, 0.75, 1.0, 1.25, 1.5, 2.0 }
        local current = mp.get_property_number("speed", 1)
        local next_index = 1
        for i, speed in ipairs(speeds) do
            if math.abs(speed - current) < 0.02 then
                next_index = (i % #speeds) + 1
                break
            end
        end
        mp.set_property_number("speed", speeds[next_index])
    elseif name == "mute" then
        mp.set_property_bool("mute", not mp.get_property_bool("mute", false))
    elseif name == "loop" then
        mp.set_property("loop-file", mp.get_property("loop-file", "no") == "inf" and "no" or "inf")
    elseif name == "screenshot" then
        mp.commandv("screenshot")
    elseif name == "fullscreen" then
        mp.set_property_bool("fullscreen", not mp.get_property_bool("fullscreen", false))
    end
    show_controls()
end

local function handle_click(mx, my)
    for _, name in ipairs(control_names) do
        if inside(mx, my, areas[name]) then
            activate(name)
            return true
        end
    end

    if inside(mx, my, areas.seek) then
        local duration = mp.get_property_number("duration", 0)
        if duration > 0 then
            local ratio = math.max(0, math.min(1, (mx - areas.seek.x1) / (areas.seek.x2 - areas.seek.x1)))
            mp.set_property_number("time-pos", duration * ratio)
        end
        show_controls()
        return true
    end

    if inside(mx, my, areas.volume) then
        local volume = math.max(0, math.min(130, 130 * (mx - areas.volume.track_x) / areas.volume.track_w))
        mp.set_property_number("volume", volume)
        mp.set_property_bool("mute", false)
        show_controls()
        return true
    end

    return false
end

local function on_click()
    local mx, my, hovering = current_mouse()
    if not hovering then return end

    if not visible then
        show_controls()
        if handle_click(mx, my) then return end
        if inside(mx, my, areas.ui) then return end
        -- Preserve click-to-pause outside the control containers.
        mp.commandv("cycle", "pause")
        show_controls()
        return
    end

    last_activity = mp.get_time()
    if handle_click(mx, my) then return end

    -- Empty areas inside a control card are inert; clicking the video toggles pause.
    if not inside(mx, my, areas.ui) then
        mp.commandv("cycle", "pause")
    end
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

for _, prop in ipairs({
    "pause", "fullscreen", "time-pos", "duration", "volume", "mute",
    "speed", "sid", "aid", "loop-file", "media-title"
}) do
    mp.observe_property(prop, "native", function()
        if visible then render() end
    end)
end
