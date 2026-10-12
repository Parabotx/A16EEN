-- A16EEN MPV controls
-- Clean white, rounded, single-row control bar with subtle A16EEN gold.
-- Video-only: the audio-only player used by the Music widget is left untouched.

local mp = require "mp"

local overlay = mp.create_osd_overlay("ass-events")
local gold = "#D7B56D"
local black = "#15171A"
local white = "#FFFFFF"
local border = "#D9DDE2"
local muted = "#707782"

local visible = false
local locked = false
local open_menu = ""
local menu_scroll = 0
local timer = nil
local last_activity = 0
local mouse = { x = -10000, y = -10000, hover = false }
local areas = {}
local menu_choices = {}

local function has_video()
    local vid = mp.get_property_native("vid")
    if vid == nil or vid == "no" then return false end
    if type(vid) == "number" and vid <= 0 then return false end
    return true
end

local function inside(x, y, area)
    return area and x >= area.x1 and x <= area.x2 and y >= area.y1 and y <= area.y2
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
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
    w = math.max(1, math.floor(w))
    h = math.max(1, math.floor(h))
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
    add_round(lines, x, y, w, h, radius, border, 0)
    add_round(lines, x + 1, y + 1, w - 2, h - 2, math.max(2, radius - 1), white, 0)
end

local function add_text(lines, x, y, value, size, color, align, bold, clip)
    local clip_tag = ""
    if clip then
        clip_tag = string.format("\\clip(%d,%d,%d,%d)", clip.x1, clip.y1, clip.x2, clip.y2)
    end
    lines[#lines + 1] = string.format(
        "{\\an%d\\pos(%d,%d)\\fnInter\\fs%d\\b%d\\bord0\\shad0\\blur0\\1c&H%s&%s}%s",
        align or 5, math.floor(x), math.floor(y), size, bold and 1 or 0,
        ass_color(color), clip_tag, escape_ass(value)
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

local function shorten(value, limit)
    local text = tostring(value or ""):gsub("[\r\n]", " ")
    if #text <= limit then return text end
    return text:sub(1, math.max(1, limit - 1)) .. "…"
end

local function current_mouse()
    local pos = mp.get_property_native("mouse-pos")
    if type(pos) == "table" then
        return tonumber(pos.x) or mouse.x, tonumber(pos.y) or mouse.y, pos.hover ~= false
    end
    return mouse.x, mouse.y, mouse.hover
end

local function is_hovered(name, mx, my, hovering)
    return hovering and inside(mx, my, areas[name])
end

local function draw_button(lines, name, x, y, w, h, label, opts)
    opts = opts or {}
    areas[name] = { x1 = x, y1 = y, x2 = x + w, y2 = y + h }
    local cx, cy = x + w / 2, y + h / 2
    if opts.active then
        add_round(lines, x, y, w, h, math.floor(h / 2), opts.active_color or gold, 0)
        add_text(lines, cx, cy, label, opts.size or 12, opts.active_text or black, 5, opts.bold or false)
    elseif is_hovered(name, opts.mx or -10000, opts.my or -10000, opts.hovering or false) then
        add_round(lines, x, y, w, h, math.floor(h / 2), "#F0F2F4", 0)
        add_text(lines, cx, cy, label, opts.size or 12, black, 5, opts.bold or false)
    else
        add_text(lines, cx, cy, label, opts.size or 12, opts.color or black, 5, opts.bold or false)
    end
end

local function available_tracks(kind)
    local all = mp.get_property_native("track-list", {})
    local filtered = {}
    if type(all) ~= "table" then return filtered end

    for _, track in ipairs(all) do
        if type(track) == "table" and track.type == kind and track.id ~= nil then
            local name = tostring(track.title or track.lang or "")
            if name == "" then
                name = (kind == "sub" and "Subtitle " or "Audio ") .. tostring(#filtered + 1)
            elseif track.lang and track.title and track.lang ~= track.title then
                name = name .. " · " .. tostring(track.lang)
            end
            if track.external then name = name .. " · external" end
            filtered[#filtered + 1] = {
                id = track.id,
                name = name,
                selected = track.selected == true,
            }
        end
    end
    return filtered
end

local function get_title()
    local title = mp.get_property("media-title", "")
    if title == "" then title = mp.get_property("filename", "Now playing") end
    return tostring(title):gsub("[\r\n]", " ")
end

local function render_locked(lines, width, height, mx, my, hovering)
    local w, h = 84, 48
    local x = math.floor((width - w) / 2)
    local y = math.floor(height - h - 25)
    add_card(lines, x, y, w, h, 16)
    draw_button(lines, "lock", x + 5, y + 5, w - 10, h - 10, "UNLOCK", {
        size = 10, bold = true, color = black, mx = mx, my = my, hovering = hovering,
    })
    areas.ui = { x1 = x, y1 = y, x2 = x + w, y2 = y + h }
    areas.lock_container = areas.ui
end

local function render_track_menu(lines, width, height, row_y, tracks_x, tracks_w, mx, my, hovering)
    if open_menu ~= "sub" and open_menu ~= "audio" then return end

    local is_sub = open_menu == "sub"
    local kind = is_sub and "sub" or "audio"
    local tracks = available_tracks(kind)
    local active_id = mp.get_property(is_sub and "sid" or "aid", "no")
    local choices = {}

    if is_sub then
        choices[#choices + 1] = { id = "no", name = "Off", selected = active_id == "no" }
    end
    for _, track in ipairs(tracks) do
        choices[#choices + 1] = {
            id = track.id,
            name = track.name,
            selected = track.selected or tostring(active_id) == tostring(track.id),
        }
    end

    local empty_label = is_sub and "No subtitles available" or "No audio tracks available"
    local empty = #tracks == 0 and not is_sub
    local header_h, row_h = 34, 30
    local row_count = math.max(1, #choices)
    local max_h = math.max(120, height - 72)
    local max_rows = math.max(1, math.floor((max_h - header_h - 8) / row_h))
    local display_rows = math.min(row_count, max_rows)
    local menu_h = header_h + display_rows * row_h + 8
    local menu_w = math.min(math.max(220, tracks_w + 90), width - 24)
    local anchor = is_sub and areas.subtitle or areas.audio
    local center = anchor and (anchor.x1 + anchor.x2) / 2 or (tracks_x + tracks_w / 2)
    local menu_x = clamp(center - menu_w / 2, 12, width - menu_w - 12)
    local menu_y = math.max(12, row_y - menu_h - 8)

    add_card(lines, menu_x, menu_y, menu_w, menu_h, 15)
    add_text(lines, menu_x + 13, menu_y + 8, is_sub and "SUBTITLES" or "AUDIO TRACKS", 9, muted, 7, true)
    add_round(lines, menu_x + 10, menu_y + 27, menu_w - 20, 1, 1, border, 0)

    menu_choices = {}
    if empty then
        local message_y = menu_y + header_h + row_h / 2
        add_text(lines, menu_x + menu_w / 2, message_y, empty_label, 10, muted, 5, false)
        if is_sub then
            local item_y = menu_y + header_h
            local area = { x1 = menu_x + 8, y1 = item_y, x2 = menu_x + menu_w - 8, y2 = item_y + row_h - 2 }
            areas["menu-1"] = area
            add_text(lines, menu_x + menu_w / 2, item_y + 8, "Off", 10, black, 5, true)
            menu_choices[#menu_choices + 1] = { area = area, kind = "sub", id = "no" }
        end
        areas.menu = { x1 = menu_x, y1 = menu_y, x2 = menu_x + menu_w, y2 = menu_y + menu_h }
        return
    end

    local max_start = math.max(1, #choices - display_rows + 1)
    local start = clamp(menu_scroll, 1, max_start)
    if menu_scroll <= 0 then
        for i, choice in ipairs(choices) do
            if choice.selected then
                start = clamp(i, 1, max_start)
                break
            end
        end
    end
    menu_scroll = start

    for row = 1, display_rows do
        local choice = choices[start + row - 1]
        if choice then
            local item_y = menu_y + header_h + (row - 1) * row_h
            local item_x = menu_x + 8
            local item_w = menu_w - 16
            local area = { x1 = item_x, y1 = item_y, x2 = item_x + item_w, y2 = item_y + row_h - 2 }
            local name = "menu-" .. tostring(row)
            areas[name] = area

            if choice.selected then
                add_round(lines, item_x, item_y, item_w, row_h - 2, 8, "#F6E8C9", 0)
            elseif inside(mx, my, area) and hovering then
                add_round(lines, item_x, item_y, item_w, row_h - 2, 8, "#F0F2F4", 0)
            end

            add_text(lines, item_x + 10, item_y + 8, shorten(choice.name, math.max(12, math.floor((menu_w - 52) / 7))), 10, black, 7, choice.selected)
            if choice.selected then add_text(lines, item_x + item_w - 10, item_y + 8, "✓", 10, black, 9, true) end
            menu_choices[#menu_choices + 1] = { area = area, kind = kind, id = choice.id }
        end
    end

    areas.menu = { x1 = menu_x, y1 = menu_y, x2 = menu_x + menu_w, y2 = menu_y + menu_h }
end

local function render()
    if not visible and not locked then return end
    local width, height = mp.get_osd_size()
    if not width or not height or width < 220 or height < 120 then return end

    local mx, my, hovering = current_mouse()
    local lines = {}
    areas = {}
    menu_choices = {}
    overlay.res_x = width
    overlay.res_y = height

    if locked then
        render_locked(lines, width, height, mx, my, hovering)
        overlay.data = table.concat(lines, "\n")
        overlay:update()
        return
    end

    local bar_w = math.min(900, width - 24)
    local compact = bar_w < 650
    local gap = compact and 4 or 8
    local play_w = compact and 50 or 60
    local tracks_w = compact and 86 or 112
    local lock_w = compact and 42 or 54
    local progress_w = compact and math.max(112, math.floor(bar_w * 0.29)) or clamp(math.floor(bar_w * 0.36), 205, 320)
    local title_w = bar_w - play_w - tracks_w - lock_w - progress_w - gap * 4

    if title_w < 92 then
        local reduction = 92 - title_w
        progress_w = math.max(compact and 100 or 165, progress_w - reduction)
        title_w = bar_w - play_w - tracks_w - lock_w - progress_w - gap * 4
    end

    local card_h = 50
    local x = math.floor((width - bar_w) / 2)
    local y = math.floor(height - card_h - 27)
    local cursor = x
    areas.ui = { x1 = x, y1 = y, x2 = x + bar_w, y2 = y + card_h }

    -- Container 1: file or video name.
    add_card(lines, cursor, y, title_w, card_h, 16)
    add_text(lines, cursor + 13, y + card_h / 2 - 7,
        shorten(get_title(), math.max(12, math.floor((title_w - 24) / 7))),
        12, black, 7, true,
        { x1 = cursor + 9, y1 = y + 4, x2 = cursor + title_w - 9, y2 = y + card_h - 4 })
    areas.title = { x1 = cursor, y1 = y, x2 = cursor + title_w, y2 = y + card_h }
    cursor = cursor + title_w + gap

    -- Container 2: only the gold play/pause button.
    add_card(lines, cursor, y, play_w, card_h, 16)
    local paused = mp.get_property_bool("pause", false)
    local button_w = compact and 38 or 44
    local button_h = 40
    local button_x = cursor + (play_w - button_w) / 2
    local button_y = y + (card_h - button_h) / 2
    draw_button(lines, "play", button_x, button_y, button_w, button_h, paused and "▶" or "Ⅱ", {
        active = true, active_color = gold, active_text = black, size = compact and 18 or 20, bold = true,
    })
    areas.play_container = { x1 = cursor, y1 = y, x2 = cursor + play_w, y2 = y + card_h }
    cursor = cursor + play_w + gap

    -- Container 3: white timeline with a bold black played portion.
    add_card(lines, cursor, y, progress_w, card_h, 16)
    local duration = math.max(0, mp.get_property_number("duration", 0))
    local position = math.max(0, mp.get_property_number("time-pos", 0))
    local ratio = duration > 0 and clamp(position / duration, 0, 1) or 0
    add_text(lines, cursor + 12, y + 6, format_time(position), 8, muted, 7, false)
    add_text(lines, cursor + progress_w - 12, y + 6, duration > 0 and format_time(duration) or "--:--", 8, muted, 9, false)
    local track_x = cursor + 12
    local track_w = progress_w - 24
    local track_y = y + 29
    add_round(lines, track_x, track_y, track_w, 7, 4, "#E2E5E9", 0)
    local played_w = math.floor(track_w * ratio)
    if played_w > 0 then
        add_round(lines, track_x, track_y, played_w, 7, 4, black, 0)
        add_round(lines, track_x + played_w - 3, track_y - 2, 9, 11, 5, black, 0)
    end
    areas.timeline = { x1 = cursor, y1 = y, x2 = cursor + progress_w, y2 = y + card_h }
    areas.seek = { x1 = track_x, y1 = y + 17, x2 = track_x + track_w, y2 = y + card_h, track_x = track_x, track_w = track_w }
    cursor = cursor + progress_w + gap

    -- Container 4: subtitle and audio pickers only.
    add_card(lines, cursor, y, tracks_w, card_h, 16)
    local sub_w = compact and 32 or 42
    local audio_w = compact and 32 or 42
    local items_w = sub_w + audio_w + 6
    local sub_x = cursor + (tracks_w - items_w) / 2
    draw_button(lines, "subtitle", sub_x, y + 8, sub_w, card_h - 16, "CC", {
        size = 10, bold = true, color = black, mx = mx, my = my, hovering = hovering,
    })
    draw_button(lines, "audio", sub_x + sub_w + 6, y + 8, audio_w, card_h - 16, "♪", {
        size = 16, color = black, mx = mx, my = my, hovering = hovering,
    })
    areas.tracks = { x1 = cursor, y1 = y, x2 = cursor + tracks_w, y2 = y + card_h }
    cursor = cursor + tracks_w + gap

    -- Container 5: lock/unlock. When locked, this is the only visible control.
    add_card(lines, cursor, y, lock_w, card_h, 16)
    draw_button(lines, "lock", cursor + 4, y + 8, lock_w - 8, card_h - 16, "LOCK", {
        size = 9, bold = true, color = black, mx = mx, my = my, hovering = hovering,
    })
    areas.lock_container = { x1 = cursor, y1 = y, x2 = cursor + lock_w, y2 = y + card_h }

    render_track_menu(lines, width, height, y, areas.tracks.x1, tracks_w, mx, my, hovering)
    overlay.data = table.concat(lines, "\n")
    overlay:update()
end

local function remove_menu_wheel_bindings()
    mp.remove_key_binding("a16een-menu-wheel-up")
    mp.remove_key_binding("a16een-menu-wheel-down")
end

local function scroll_menu(delta)
    if locked or open_menu == "" then return end
    local mx, my, hovering = current_mouse()
    if not hovering or not inside(mx, my, areas.menu) then return end
    menu_scroll = math.max(1, menu_scroll + delta)
    render()
end

local function add_menu_wheel_bindings()
    mp.add_forced_key_binding("WHEEL_UP", "a16een-menu-wheel-up", function() scroll_menu(-1) end)
    mp.add_forced_key_binding("WHEEL_DOWN", "a16een-menu-wheel-down", function() scroll_menu(1) end)
end

local function remove_wheel_lock()
    for _, name in ipairs({
        "a16een-lock-wheel-up", "a16een-lock-wheel-down",
        "a16een-lock-wheel-left", "a16een-lock-wheel-right"
    }) do
        mp.remove_key_binding(name)
    end
end

local function add_wheel_lock()
    local function swallow() end
    mp.add_forced_key_binding("WHEEL_UP", "a16een-lock-wheel-up", swallow)
    mp.add_forced_key_binding("WHEEL_DOWN", "a16een-lock-wheel-down", swallow)
    mp.add_forced_key_binding("WHEEL_LEFT", "a16een-lock-wheel-left", swallow)
    mp.add_forced_key_binding("WHEEL_RIGHT", "a16een-lock-wheel-right", swallow)
end

local function hide_controls()
    visible = false
    open_menu = ""
    remove_menu_wheel_bindings()
    if timer then
        timer:kill()
        timer = nil
    end
    if not locked then overlay:remove() end
end

local function show_controls()
    if not has_video() then return end
    if locked then
        render()
        return
    end
    visible = true
    last_activity = mp.get_time()
    if not timer then
        timer = mp.add_periodic_timer(0.18, function()
            if locked then
                render()
                return
            end
            if not visible then return end
            local mx, my, hovering = current_mouse()
            if mp.get_time() - last_activity > 2.5 and not (hovering and inside(mx, my, areas.ui)) then
                hide_controls()
                return
            end
            render()
        end)
    end
    render()
end

local function lock_controls()
    locked = true
    visible = true
    open_menu = ""
    remove_menu_wheel_bindings()
    add_wheel_lock()
    render()
end

local function unlock_controls()
    locked = false
    visible = true
    last_activity = mp.get_time()
    remove_wheel_lock()
    show_controls()
end

local function choose_track(choice)
    if choice.kind == "sub" then
        if tostring(choice.id) == "no" then
            mp.set_property("sid", "no")
        else
            mp.set_property_number("sid", tonumber(choice.id) or 0)
        end
    else
        mp.set_property_number("aid", tonumber(choice.id) or 0)
    end
    open_menu = ""
    remove_menu_wheel_bindings()
    show_controls()
end

local function seek_from_mouse(mx)
    local area = areas.seek
    local duration = mp.get_property_number("duration", 0)
    if not area or duration <= 0 or area.track_w <= 0 then return end
    local ratio = clamp((mx - area.track_x) / area.track_w, 0, 1)
    mp.set_property_number("time-pos", duration * ratio)
    show_controls()
end

local function on_click()
    local mx, my, hovering = current_mouse()
    if not hovering then return end

    if locked then
        if inside(mx, my, areas.lock) then unlock_controls() end
        return
    end

    if not visible then show_controls() end
    last_activity = mp.get_time()

    for _, choice in ipairs(menu_choices) do
        if inside(mx, my, choice.area) then
            choose_track(choice)
            return
        end
    end

    if inside(mx, my, areas.lock_container) then
        lock_controls()
        return
    elseif inside(mx, my, areas.play_container) then
        mp.set_property_bool("pause", not mp.get_property_bool("pause", false))
        show_controls()
        return
    elseif inside(mx, my, areas.subtitle) then
        if open_menu == "sub" then
            open_menu = ""
            remove_menu_wheel_bindings()
        else
            open_menu = "sub"
            menu_scroll = 0
            add_menu_wheel_bindings()
        end
        show_controls()
        return
    elseif inside(mx, my, areas.audio) then
        if open_menu == "audio" then
            open_menu = ""
            remove_menu_wheel_bindings()
        else
            open_menu = "audio"
            menu_scroll = 0
            add_menu_wheel_bindings()
        end
        show_controls()
        return
    elseif inside(mx, my, areas.timeline) then
        seek_from_mouse(mx)
        return
    elseif open_menu ~= "" and inside(mx, my, areas.menu) then
        return
    elseif open_menu ~= "" then
        open_menu = ""
        remove_menu_wheel_bindings()
        render()
        if inside(mx, my, areas.ui) then return end
    end

    if inside(mx, my, areas.ui) then return end
    mp.commandv("cycle", "pause")
    show_controls()
end

mp.add_key_binding("MBTN_LEFT", "a16een-mpv-click", on_click)
mp.add_key_binding("MBTN_LEFT_DBL", "a16een-mpv-double-click", function()
    if locked then return end
    mp.set_property_bool("fullscreen", not mp.get_property_bool("fullscreen", false))
    show_controls()
end)
mp.add_key_binding("ESC", "a16een-mpv-close-menu", function()
    if open_menu ~= "" then
        open_menu = ""
        remove_menu_wheel_bindings()
        show_controls()
    end
end)

mp.observe_property("mouse-pos", "native", function(_, value)
    if type(value) ~= "table" then return end
    local new_x, new_y = tonumber(value.x), tonumber(value.y)
    if not new_x or not new_y then return end
    local moved = new_x ~= mouse.x or new_y ~= mouse.y or (value.hover ~= false and not mouse.hover)
    mouse = { x = new_x, y = new_y, hover = value.hover ~= false }

    if locked then
        render()
    elseif not mouse.hover then
        if open_menu ~= "" then open_menu = "" end
        hide_controls()
    elseif moved then
        show_controls()
    end
end)

mp.register_event("file-loaded", function()
    open_menu = ""
    remove_menu_wheel_bindings()
    if has_video() then show_controls() else hide_controls() end
end)
mp.register_event("end-file", function()
    open_menu = ""
    remove_menu_wheel_bindings()
    hide_controls()
end)
mp.register_event("shutdown", function()
    remove_wheel_lock()
    hide_controls()
end)
mp.register_event("video-reconfig", function()
    if visible or locked then render() end
end)

for _, property in ipairs({ "pause", "time-pos", "duration", "track-list", "sid", "aid", "media-title" }) do
    mp.observe_property(property, "native", function()
        if visible or locked then render() end
    end)
end
