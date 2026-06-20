local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Event = require("ui/event")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local IconWidget = require("ui/widget/iconwidget")
local Math = require("optmath")
local NetworkMgr = require("ui/network/manager")
local Button = require("ui/widget/button")
local ConfirmBox = require("ui/widget/confirmbox")
local TextWidget = require("ui/widget/textwidget")
local LeftContainer = require("ui/widget/container/leftcontainer")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local _ = require("gettext")
local util = require("util")
local Screen = Device.screen
local Dispatcher = require("dispatcher")

local QuickSettingsPlugin = WidgetContainer:extend{
    name = "quicksettings",
}

-- ============================================================
-- ZenSlider Engine (Nativamente injetado)
-- ============================================================
local ZenSlider = {}
ZenSlider.__index = ZenSlider

function ZenSlider:new(o)
    local obj = setmetatable(o or {}, self)
    obj.track_height  = obj.track_height  or Screen:scaleBySize(1)
    obj.fill_height   = obj.fill_height   or Screen:scaleBySize(6)
    obj.knob_radius   = obj.knob_radius   or Screen:scaleBySize(16.5)
    obj.fill_color    = obj.fill_color    or Blitbuffer.COLOR_BLACK
    obj.track_color   = obj.track_color   or obj.fill_color
    obj.knob_color    = obj.knob_color    or Blitbuffer.COLOR_BLACK
    obj.knob_bg_color = obj.knob_bg_color or Blitbuffer.COLOR_WHITE
    local knob_d  = obj.knob_radius * 2
    obj.height    = knob_d + Screen:scaleBySize(6)
    obj.dimen     = Geom:new{ w = obj.width or 0, h = obj.height }
    obj._value    = math.max(obj.value_min, math.min(obj.value_max, Math.round(obj.value or obj.value_min)))
    return obj
end

function ZenSlider:_trackBounds()
    local r = self.knob_radius
    return r, (self.width or 0) - r
end

function ZenSlider:_valueToX(v)
    local x0, x1 = self:_trackBounds()
    local range   = self.value_max - self.value_min
    if range == 0 then return x0 end
    return x0 + (v - self.value_min) / range * (x1 - x0)
end

function ZenSlider:_xToValue(local_x)
    local x0, x1 = self:_trackBounds()
    local frac    = (local_x - x0) / math.max(1, x1 - x0)
    frac          = math.max(0, math.min(1, frac))
    return math.max(self.value_min, math.min(self.value_max, Math.round(self.value_min + frac * (self.value_max - self.value_min))))
end

function ZenSlider:getValue() return self._value end
function ZenSlider:setValue(v) self._value = math.max(self.value_min, math.min(self.value_max, Math.round(v))) end

function ZenSlider:applyPosition(abs_x)
    self._prev_knob_abs_x = self:_knobAbsX()
    local local_x = abs_x - (self.dimen and self.dimen.x or 0)
    local new_val = self:_xToValue(local_x)
    if new_val ~= self._value then
        self._value = new_val
        if self.on_change then self.on_change(new_val) end
    elseif self._dragging and self.on_change then
        self.on_change(new_val)
    end
end

function ZenSlider:hitTest(pos) return self.dimen ~= nil and pos:intersectWith(self.dimen) end
function ZenSlider:getSize() return self.dimen end

local function paintPill(bb, px, py, pw, ph, color)
    if pw <= 0 or ph <= 0 then return end
    local r = math.min(pw, ph) / 2.0
    for row = 0, ph - 1 do
        local dy    = (row + 0.5) - ph * 0.5
        local inset = 0
        if math.abs(dy) < r then inset = math.ceil(r - math.sqrt(r * r - dy * dy)) end
        local rw = pw - 2 * inset
        if rw > 0 then bb:paintRect(px + inset, py + row, rw, 1, color) end
    end
end

local function paintCircle(bb, cx, cy, r, color)
    for row = -r, r do
        local half = math.floor(math.sqrt(r * r - row * row) + 0.5)
        if half > 0 then bb:paintRect(cx - half, cy + row, half * 2, 1, color) end
    end
end

function ZenSlider:paintTo(bb, x, y)
    self.dimen.x = x; self.dimen.y = y
    local w  = self.width or 0; local h  = self.height
    local th = self.track_height; local r  = self.knob_radius

    bb:paintRect(x, y, w, h, self.knob_bg_color)

    local track_cy = math.floor(y + h / 2)
    local track_y  = track_cy - math.floor(th / 2)
    paintPill(bb, x, track_y, w, th, self.track_color)

    local fh = self.fill_height
    local fill_y = track_cy - math.floor(fh / 2)
    local knob_x = math.floor(x + self:_valueToX(self._value))
    local range = self.value_max - self.value_min
    local frac = range > 0 and (self._value - self.value_min) / range or 0
    local fill_w = Math.round(frac * w)
    if fill_w > 0 then paintPill(bb, x, fill_y, fill_w, fh, self.fill_color) end

    if not self.hide_knob then
        paintCircle(bb, knob_x, track_cy, r, self.knob_bg_color)
        paintCircle(bb, knob_x, track_cy, r - Screen:scaleBySize(2), self.knob_color)
    end
end

function ZenSlider:_knobAbsX() return math.floor((self.dimen and self.dimen.x or 0) + self:_valueToX(self._value)) end
function ZenSlider:_isNearKnob(abs_x) return math.abs(abs_x - self:_knobAbsX()) <= self.knob_radius * 4 end

function ZenSlider:handleTap(ges)
    if not self.dimen or not ges.pos:intersectWith(self.dimen) then return false end
    if self:_isNearKnob(ges.pos.x) then return false end
    self:applyPosition(ges.pos.x)
    return true
end

function ZenSlider:handlePan(ges)
    if self._dragging then self:applyPosition(ges.pos.x); return true end
    if not (self.dimen and ges.pos:intersectWith(self.dimen)) then return false end
    local dir = ges.direction
    if dir == "north" or dir == "south" then return false end
    if not self:_isNearKnob(ges.pos.x) then return false end
    self._dragging = true; self.hide_knob = true; self:applyPosition(ges.pos.x)
    return true
end

function ZenSlider:handlePanRelease(ges, show_parent, dirty_dimen)
    if not self._dragging then return false end
    self._dragging = false; self.hide_knob = false; self:applyPosition(ges.pos.x)
    UIManager:setDirty(show_parent, "ui", self.dimen)
    return true
end

local function isHorizontalish(dir)
    return dir == "east" or dir == "west" or dir == "northeast" or dir == "northwest" or dir == "southeast" or dir == "southwest"
end

local function hSign(dir)
    if dir == "east" or dir == "northeast" or dir == "southeast" then return 1 end
    return -1
end

function ZenSlider:handleSwipe(ges, show_parent, dirty_dimen)
    if not isHorizontalish(ges.direction) then return false end
    if not self._dragging then
        if not (self.dimen and ges.pos:intersectWith(self.dimen)) then return false end
        if not self:_isNearKnob(ges.pos.x) then return false end
    end
    local was_dragging = self._dragging
    self._dragging = false; self.hide_knob = false
    if not was_dragging then
        local dist  = ges.distance or 0
        local end_x = ges.pos.x + hSign(ges.direction) * dist
        self:applyPosition(end_x)
    else
        UIManager:setDirty(show_parent, "ui", self.dimen)
    end
    return true
end

function ZenSlider:handleMultiSwipe(ges, show_parent, dirty_dimen)
    if not self._dragging then return false end
    self._dragging = false; self.hide_knob = false; UIManager:setDirty(show_parent, "ui", self.dimen)
    return true
end

function ZenSlider:handleEvent(_event)
    return false
end

function ZenSlider:free()
end

function ZenSlider.installTouchMenuHooks(TouchMenu, opts)
    local in_panel  = opts.in_panel_mode
    local get_sl    = opts.get_sliders
    local is_locked = opts.is_locked
    local swipe_fb  = opts.swipe_fallback
    local mswipe_fb = opts.multiswipe_fallback

    function TouchMenu:onPanCloseAllMenus(arg, ges_ev)
        if not in_panel(self) then return end
        if is_locked(self) then self._qs_opening_pan = true; return end
        self._qs_opening_pan = false
        for _, sl in ipairs(get_sl(self)) do if sl:handlePan(ges_ev) then return true end end
    end

    function TouchMenu:onPanReleaseCloseAllMenus(arg, ges_ev)
        if not in_panel(self) then return end
        if is_locked(self) or self._qs_opening_pan then self._qs_opening_pan = false; return end
        for _, sl in ipairs(get_sl(self)) do if sl:handlePanRelease(ges_ev, self.show_parent, self.dimen) then return true end end
    end

    local orig_onSwipe = TouchMenu.onSwipe
    function TouchMenu:onSwipe(arg, ges_ev)
        if in_panel(self) then
            if not is_locked(self) then
                for _, sl in ipairs(get_sl(self)) do if sl:handleSwipe(ges_ev, self.show_parent, self.dimen) then return true end end
                if swipe_fb then swipe_fb(self, ges_ev) end
            end
            return true
        end
        if orig_onSwipe then return orig_onSwipe(self, arg, ges_ev) end
    end

    local orig_onMultiSwipe = TouchMenu.onMultiSwipe
    function TouchMenu:onMultiSwipe(arg, ges_ev)
        if in_panel(self) then
            for _, sl in ipairs(get_sl(self)) do if sl:handleMultiSwipe(ges_ev, self.show_parent, self.dimen) then return true end end
            if mswipe_fb then mswipe_fb(self, ges_ev) end
            return true
        end
        if orig_onMultiSwipe then return orig_onMultiSwipe(self, arg, ges_ev) end
    end
end

-- ============================================================
-- Inicialização Principal do Plugin
-- ============================================================

function QuickSettingsPlugin:init()
    local config_default = {
        button_order = { "wifi", "night", "frontlight", "rotate", "rotation", "usb", "search", "cloud", "zlibrary", "calibre", "calibre_search", "streak", "localsend", "filebrowser", "stats_progress", "stats_calendar", "battery_stats", "restart", "exit", "sleep" },
        show_buttons = {
            wifi = true, night = true, front light = true, rotate = true, rotation = false, search = false, usb = false, cloud = false,
            zlibrary = false, calibre = false, calibre_search = false, restart = true, exit = true, sleep = true,
            streak = false, filebrowser = false, stats_progress = false, stats_calendar = false, battery_stats = false,
            localsend = false,
        },
        show_frontlight = true,
        show_warmth = true,
        show_available_networks = true,
        custom_buttons = {},
        next_custom_id = 0,
    }

    local config = G_reader_settings:readSetting("quick_settings_plugin", {})
    for k, v in pairs(config_default) do
        if config[k] == nil then config[k] = util.tableDeepCopy(v) end
    end
    if type(config.show_buttons) ~= "table" then config.show_buttons = util.tableDeepCopy(config_default.show_buttons) end
    if type(config.button_order) ~= "table" then config.button_order = util.tableDeepCopy(config_default.button_order) end

    local function saveConfig()
        G_reader_settings:saveSetting("quick_settings_plugin", config)
    end

    -- Detecção de plugins otimizada baseada no sistema de arquivos do KOReader
    local function hasPlugin(name)
        if G_reader_settings:isTrue("plugin_" .. name .. "_enabled") then return true end
        local path = "plugins/" .. name .. ".koplugin/main.lua"
        local f = io.open(path, "r")
        if f then f:close() return true end
        return false
    end

    -- Estado local para feedback transicional
    local _toggling_wifi = false

    local button_defs = {
        wifi = {
            icon = "quick_wifi", label = _("Wi-Fi"),
            label_func = function()
                if _toggling_wifi then
                    return NetworkMgr:isWifiOn() and _("Disconnecting...") or _("Connecting...")
                end
                if NetworkMgr:isWifiOn() then
                    local net = NetworkMgr:getCurrentNetwork()
                    if net and net.ssid then return net.ssid end
                end
                return _("Wi-Fi")
            end,
            active_func = function() return NetworkMgr:isWifiOn() and not _toggling_wifi end,
            disabled_func = function() return _toggling_wifi end,
            callback = function(touch_menu)
                _toggling_wifi = true
                touch_menu:updateItems(1)
                
                local function onFinish()
                    _toggling_wifi = false
                    if touch_menu.item_table and touch_menu.item_table.panel then 
                        touch_menu:updateItems(1) 
                    end
                end
                
                if NetworkMgr:isWifiOn() then 
                    NetworkMgr:toggleWifiOff(onFinish, true) 
                else 
                    -- CORREÇÃO APLICADA AQUI
                    NetworkMgr:toggleWifiOn(onFinish, config.show_available_networks, true) 
                end
            end,
            hold_callback = function(touch_menu)
                _toggling_wifi = true
                touch_menu:updateItems(1)
                local function do_connect() 
                    -- CORREÇÃO APLICADA AQUI TAMBÉM
                    NetworkMgr:toggleWifiOn(function() 
                        _toggling_wifi = false
                        if touch_menu.item_table and touch_menu.item_table.panel then touch_menu:updateItems(1) end 
                    end, config.show_available_networks, true) 
                end
                if NetworkMgr:isWifiOn() then NetworkMgr:toggleWifiOff(function() do_connect() end, true) else do_connect() end
            end,
        },
        night = {
            icon = "quick_nightmode", label = _("Night"),
            active_func = function() return G_reader_settings:isTrue("night_mode") end,
            callback = function(touch_menu)
                local night_mode = G_reader_settings:isTrue("night_mode")
                Screen:toggleNightMode()
                UIManager:ToggleNightMode(not night_mode)
                G_reader_settings:saveSetting("night_mode", not night_mode)
                touch_menu:updateItems(1)
                UIManager:setDirty("all", "full")
            end,
        },
        frontlight = {
            icon = "lightbulb",
            label = _("Frontlight"),
            active_func = function() return Device:getPowerDevice():isFrontlightOn() end,
            callback = function(touch_menu)
                Device:getPowerDevice():toggleFrontlight()
                touch_menu:updateItems(1)
            end,
        },
        rotation = {
            icon = "quick_rotate",
            label = _("Rotation"),
            active_func = function() return not G_reader_settings:isTrue("input_ignore_gsensor") end,
            callback = function(touch_menu)
                UIManager:broadcastEvent(Event:new("ToggleGSensor"))
                touch_menu:updateItems(1)
            end,
        },
        rotate = { icon = "quick_rotate", label = _("Rotate"), callback = function() UIManager:broadcastEvent(Event:new("IterateRotation")) end },
        usb = { icon = "quick_usb", label = _("USB"), callback = function() if Device:canToggleMassStorage() then UIManager:broadcastEvent(Event:new("RequestUSBMS")) end end },
        restart = { icon = "quick_restart", label = _("Restart"), callback = function() UIManager:show(ConfirmBox:new{ text = _("Are you sure you want to restart KOReader?"), ok_text = _("Restart"), ok_callback = function() UIManager:broadcastEvent(Event:new("Restart")) end }) end },
        exit = { icon = "quick_exit", label = _("Exit"), callback = function() UIManager:show(ConfirmBox:new{ text = _("Are you sure you want to exit KOReader?"), ok_text = _("Exit"), ok_callback = function() UIManager:broadcastEvent(Event:new("Exit")) end }) end },
        sleep = { icon = "quick_sleep", label = _("Sleep"), callback = function() if Device:canSuspend() then UIManager:broadcastEvent(Event:new("RequestSuspend")) elseif Device:canPowerOff() then UIManager:broadcastEvent(Event:new("RequestPowerOff")) end end },
        search = { icon = "quick_search", label = _("Search"), callback = function() UIManager:broadcastEvent(Event:new("ShowFileSearch")) end },
        cloud = { icon = "quick_cloud", label = _("Cloud"), callback = function() UIManager:broadcastEvent(Event:new("ShowCloudStorage")) end },
        zlibrary = { icon = "quick_zlib", label = _("Z-Lib"), visible_func = function() return hasPlugin("zlibrary") end, callback = function() UIManager:broadcastEvent(Event:new("ZlibrarySearch")) end },
        calibre_search = { icon = "quick_search", label = _("Search"), visible_func = function() return hasPlugin("calibre") end, callback = function(touch_menu) touch_menu:closeMenu(); UIManager:broadcastEvent(Event:new("CalibreSearch")) end },
        calibre = { icon = "quick_calibre", label = _("Calibre"), visible_func = function() return hasPlugin("calibre") end, active_func = function() local CW = package.loaded["wireless"]; return type(CW)=="table" and CW.calibre_socket ~= nil end, callback = function(touch_menu) local CW = package.loaded["wireless"]; if type(CW)=="table" and CW.calibre_socket ~= nil then UIManager:broadcastEvent(Event:new("CloseWirelessConnection")) else UIManager:broadcastEvent(Event:new("StartWirelessConnection")) end; UIManager:scheduleIn(1, function() touch_menu:updateItems(1) end) end },
        streak = { icon = "quick_streak", label = _("Streak"), visible_func = function() return hasPlugin("readingstreak") end, callback = function() UIManager:broadcastEvent(Event:new("ShowReadingStreakCalendar")) end },
        localsend = {
            icon = "quick_localsend", label = _("LocalSend"),
            visible_func = function() return hasPlugin("localsend") end,
            active_func = function() local f = io.open("/tmp/localsend_koreader.pid", "r"); if f then f:close(); return true end return false end,
            callback = function(touch_menu)
                UIManager:broadcastEvent(Event:new("ToggleLocalSend"))
                UIManager:scheduleIn(1.5, function() if touch_menu._qs_refs then touch_menu:updateItems(1) end end)
            end,
        },
        filebrowser = {
            icon = "quick_filebrowser", label = _("Filebrowser"),
            visible_func = function() return hasPlugin("filebrowser") end,
            active_func = function()
                local pid_path = "/tmp/filebrowser_koreader.pid"
                local f = io.open(pid_path, "r")
                if f then f:close() return true end
                return false
            end,
            callback = function(touch_menu)
                local ok_f, FileManager = pcall(require, "apps/filemanager/filemanager")
                local ok_r, ReaderUI = pcall(require, "apps/reader/readerui")
                local ui = (ok_f and FileManager.instance) or (ok_r and ReaderUI.instance)
                if ui and ui.filebrowser then
                    ui.filebrowser:onToggleFilebrowser()
                    UIManager:scheduleIn(1.5, function() if touch_menu.item_table and touch_menu.item_table.panel then touch_menu:updateItems(1) end end)
                else
                    local InfoMessage = require("ui/widget/infomessage")
                    UIManager:show(InfoMessage:new{ text = _("Filebrowser plugin is not installed.") })
                end
            end,
        },
        stats_progress = {
            icon = "quick_stats_progress", label = _("Progress"),
            visible_func = function() return hasPlugin("statistics") end,
            callback = function(touch_menu) touch_menu:closeMenu(); UIManager:broadcastEvent(Event:new("ShowReaderProgress")) end,
        },
        stats_calendar = {
            icon = "quick_stats_calendar", label = _("Calendar"),
            visible_func = function() return hasPlugin("statistics") end,
            callback = function(touch_menu) touch_menu:closeMenu(); UIManager:broadcastEvent(Event:new("ShowCalendarView")) end,
        },
        battery_stats = {
            icon = "quick_battery", label = _("Battery"),
            visible_func = function() return hasPlugin("batterystat") end,
            callback = function(touch_menu) touch_menu:closeMenu(); UIManager:broadcastEvent(Event:new("ShowBatteryStatistics")) end,
        },
    }

    local button_display_names = {
        wifi = _("Wi-Fi"), night = _("Night mode"), front light = -("Frontlight"), rotate = _("Rotate"), rotation = _("Rotation"), usb = _("USB"), restart = _("Restart"), exit = _("Exit"), sleep = _("Sleep"), search = _("File search"), cloud = _("Cloud storage"), zlibrary = _("Z-Library"), calibre = _("Calibre"), calibre_search = _("Calibre Search"), streak = _("Streak"), localsend = _("LocalSend"), filebrowser = _("File Browser"), stats_progress = _("Reading Progress"), stats_calendar = _("Reading Calendar"), battery_stats = _("Battery Stats"),
    }

    -- ============================================================
    -- Construtores de Sliders (Brilho e Temperatura)
    -- ============================================================
    local function build_brightness_slider(touch_menu, opts)
        local fl = { min = opts.powerd.fl_min, max = opts.powerd.fl_max, cur = opts.powerd:frontlightIntensity() }
        local fl_prefix_text = _("Brightness") .. ": "
        local fl_drag_prefix = TextWidget:new{ text = fl_prefix_text, face = opts.medium_font }
        local fl_drag_prefix_w = fl_drag_prefix:getSize().w
        local fl_drag_num = TextWidget:new{ text = tostring(fl.cur), face = opts.medium_font }
        local fl_max_num_sample = TextWidget:new{ text = tostring(fl.max), face = opts.medium_font }
        local fl_drag_max_num_w = fl_max_num_sample:getSize().w
        fl_max_num_sample:free()
        
        local fl_drag_ref_w = fl_drag_prefix_w + fl_drag_max_num_w
        local fl_label_h = fl_drag_prefix:getSize().h
        local fl_num_box = LeftContainer:new{ dimen = Geom:new{ w = fl_drag_max_num_w, h = fl_label_h }, fl_drag_num }
        local fl_label_group = HorizontalGroup:new{ fl_drag_prefix, fl_num_box }

        local fl_progress = ZenSlider:new{ width = opts.slider_width, value = fl.cur, value_min = fl.min, value_max = fl.max, show_parent = opts.show_parent }
        local fl_minus = Button:new{ text = "−", text_font_face = "infofont", text_font_size = opts.small_btn_size, width = opts.small_btn_width, bordersize = 0, show_parent = opts.show_parent, callback = function() end }
        
        local fl_row
        local function setBrightness(intensity)
            if intensity ~= fl.min and intensity == fl.cur then return end
            intensity = math.max(fl.min, math.min(fl.max, intensity))
            opts.powerd:setIntensity(intensity)
            fl.cur = intensity
            fl_progress:setValue(fl.cur)
            fl_drag_num:setText(tostring(fl.cur))
            if fl_num_box.dimen then UIManager:setDirty(opts.show_parent, "ui", fl_num_box.dimen) end
            if fl_progress.dimen then UIManager:setDirty(opts.show_parent, "ui", fl_progress.dimen) end
        end

        fl_progress.on_change = function(v)
            opts.powerd:setIntensity(v)
            fl.cur = v
            if fl_progress._dragging then
                fl_progress:paintTo(Screen.bb, fl_progress.dimen.x, fl_progress.dimen.y)
                local row_gap_h = Screen:scaleBySize(10)
                local lh = fl_drag_prefix:getSize().h
                local row_h = fl_row and fl_row:getSize().h or fl_progress.dimen.h
                local label_y = (fl_progress.dimen.y - math.floor((row_h - fl_progress.dimen.h) / 2)) - row_gap_h - lh
                local num_x = fl_progress.dimen.x + math.floor((fl_progress.dimen.w - fl_drag_ref_w) / 2) + fl_drag_prefix_w
                Screen.bb:paintRect(num_x, label_y, fl_drag_max_num_w, lh, Blitbuffer.COLOR_WHITE)
                fl_drag_num:setText(tostring(fl.cur))
                fl_drag_num:paintTo(Screen.bb, num_x, label_y)
                UIManager:setDirty(nil, "fast", Geom:new{ x = fl_progress.dimen.x, y = label_y, w = fl_progress.dimen.w, h = fl_progress.dimen.y + fl_progress.dimen.h - label_y })
            else
                fl_drag_num:setText(tostring(fl.cur))
                if fl_num_box.dimen then UIManager:setDirty(opts.show_parent, "ui", fl_num_box.dimen) end
                if fl_progress.dimen then UIManager:setDirty(opts.show_parent, "ui", fl_progress.dimen) end
            end
        end

        fl_minus.callback = function() setBrightness(fl.cur - 1) end
        local fl_plus = Button:new{ text = "＋", text_font_face = "infofont", text_font_size = opts.small_btn_size, width = opts.small_btn_width, bordersize = 0, show_parent = opts.show_parent, callback = function() setBrightness(fl.cur + 1) end }
        
        fl_row = HorizontalGroup:new{ align = "center", fl_minus, HorizontalSpan:new{ width = opts.slider_gap }, fl_progress, HorizontalSpan:new{ width = opts.slider_gap }, fl_plus }
        opts.refs.fl_progress = fl_progress; opts.refs.fl_state = fl; opts.refs.setBrightness = setBrightness
        table.insert(opts.refs.sliders, { slider = fl_progress })

        local group = VerticalGroup:new{ align = "center" }
        table.insert(group, VerticalSpan:new{ width = Screen:scaleBySize(10) })
        table.insert(group, CenterContainer:new{ dimen = Geom:new{ w = opts.inner_width, h = fl_label_h }, fl_label_group })
        table.insert(group, VerticalSpan:new{ width = Screen:scaleBySize(10) })
        table.insert(group, fl_row)
        table.insert(group, VerticalSpan:new{ width = Screen:scaleBySize(10) })
        return group
    end

    local function build_warmth_slider(touch_menu, opts)
        local nl = { min = opts.powerd.fl_warmth_min, max = opts.powerd.fl_warmth_max, cur = opts.powerd:toNativeWarmth(opts.powerd:frontlightWarmth()) }
        local nl_prefix_text = _("Warmth") .. ": "
        local nl_drag_prefix = TextWidget:new{ text = nl_prefix_text, face = opts.medium_font }
        local nl_drag_prefix_w = nl_drag_prefix:getSize().w
        local nl_drag_num = TextWidget:new{ text = tostring(nl.cur), face = opts.medium_font }
        local nl_max_num_sample = TextWidget:new{ text = tostring(nl.max), face = opts.medium_font }
        local nl_drag_max_num_w = nl_max_num_sample:getSize().w
        nl_max_num_sample:free()
        
        local nl_drag_ref_w = nl_drag_prefix_w + nl_drag_max_num_w
        local nl_label_h = nl_drag_prefix:getSize().h
        local nl_num_box = LeftContainer:new{ dimen = Geom:new{ w = nl_drag_max_num_w, h = nl_label_h }, nl_drag_num }
        local nl_label_group = HorizontalGroup:new{ nl_drag_prefix, nl_num_box }

        local nl_progress = ZenSlider:new{ width = opts.slider_width, value = nl.cur, value_min = nl.min, value_max = nl.max, show_parent = opts.show_parent }
        local nl_minus = Button:new{ text = "−", text_font_face = "infofont", text_font_size = opts.small_btn_size, width = opts.small_btn_width, bordersize = 0, show_parent = opts.show_parent, callback = function() end }
        
        local nl_row
        local function setWarmth(warmth)
            if warmth == nl.cur then return end
            warmth = math.max(nl.min, math.min(nl.max, warmth))
            opts.powerd:setWarmth(opts.powerd:fromNativeWarmth(warmth))
            nl.cur = warmth
            nl_progress:setValue(nl.cur)
            nl_drag_num:setText(tostring(nl.cur))
            if nl_num_box.dimen then UIManager:setDirty(opts.show_parent, "ui", nl_num_box.dimen) end
            if nl_progress.dimen then UIManager:setDirty(opts.show_parent, "ui", nl_progress.dimen) end
        end

        nl_progress.on_change = function(v)
            opts.powerd:setWarmth(opts.powerd:fromNativeWarmth(v))
            nl.cur = v
            if nl_progress._dragging then
                nl_progress:paintTo(Screen.bb, nl_progress.dimen.x, nl_progress.dimen.y)
                local row_gap_h = Screen:scaleBySize(10)
                local lh = nl_drag_prefix:getSize().h
                local row_h = nl_row and nl_row:getSize().h or nl_progress.dimen.h
                local label_y = (nl_progress.dimen.y - math.floor((row_h - nl_progress.dimen.h) / 2)) - row_gap_h - lh
                local num_x = nl_progress.dimen.x + math.floor((nl_progress.dimen.w - nl_drag_ref_w) / 2) + nl_drag_prefix_w
                Screen.bb:paintRect(num_x, label_y, nl_drag_max_num_w, lh, Blitbuffer.COLOR_WHITE)
                nl_drag_num:setText(tostring(nl.cur))
                nl_drag_num:paintTo(Screen.bb, num_x, label_y)
                UIManager:setDirty(nil, "fast", Geom:new{ x = nl_progress.dimen.x, y = label_y, w = opts.inner_width, h = nl_progress.dimen.y + nl_progress.dimen.h - label_y })
            else
                nl_drag_num:setText(tostring(nl.cur))
                if nl_num_box.dimen then UIManager:setDirty(opts.show_parent, "ui", nl_num_box.dimen) end
                if nl_progress.dimen then UIManager:setDirty(opts.show_parent, "ui", nl_progress.dimen) end
            end
        end

        nl_minus.callback = function() setWarmth(nl.cur - 1) end
        local nl_plus = Button:new{ text = "＋", text_font_face = "infofont", text_font_size = opts.small_btn_size, width = opts.small_btn_width, bordersize = 0, show_parent = opts.show_parent, callback = function() setWarmth(nl.cur + 1) end }
        
        nl_row = HorizontalGroup:new{ align = "center", nl_minus, HorizontalSpan:new{ width = opts.slider_gap }, nl_progress, HorizontalSpan:new{ width = opts.slider_gap }, nl_plus }
        opts.refs.nl_progress = nl_progress; opts.refs.nl_state = nl; opts.refs.setWarmth = setWarmth
        table.insert(opts.refs.sliders, { slider = nl_progress })

        local group = VerticalGroup:new{ align = "center" }
        table.insert(group, VerticalSpan:new{ width = Screen:scaleBySize(14) })
        table.insert(group, CenterContainer:new{ dimen = Geom:new{ w = opts.inner_width, h = nl_label_h }, nl_label_group })
        table.insert(group, VerticalSpan:new{ width = Screen:scaleBySize(10) })
        table.insert(group, nl_row)
        return group
    end

    -- ============================================================
    -- Criação do Painel Dinâmico Multifileiras
    -- ============================================================
    local function createQuickSettingsPanel(touch_menu)
        local panel_width = touch_menu.item_width
        local padding = Screen:scaleBySize(10)
        local inner_width = panel_width - padding * 2
        local powerd = Device:getPowerDevice()

        local refs = { buttons = {}, sliders = {} }
        local visible_buttons = {}
        
        for _, id in ipairs(config.button_order) do
            if config.show_buttons[id] and button_defs[id] then
                local def = button_defs[id]
                if not def.visible_func or def.visible_func() then 
                    table.insert(visible_buttons, { id = id, def = def })
                end
            end
        end

        local action_btn_size = Screen:scaleBySize(64)
        local icon_size = math.floor(action_btn_size * 0.5)
        local label_font = Font:getFace("xx_smallinfofont", 15)
        local normal_border = Screen:scaleBySize(2)
        local fixed_col_width = action_btn_size + Screen:scaleBySize(16) 

        local function makeActionButton(icon_name, label_text, active, dim)
            local icon = IconWidget:new{ icon = icon_name, width = icon_size, height = icon_size, alpha = not active }
            if active then
                icon:_render()
                if icon._bb then
                    local bb_copy = icon._bb:copy()
                    bb_copy:invertRect(0, 0, bb_copy:getWidth(), bb_copy:getHeight())
                    icon._bb = bb_copy
                end
            end
            local border = active and 0 or normal_border
            local bg = active and Blitbuffer.COLOR_BLACK or dim and Blitbuffer.COLOR_LIGHT_GRAY or Blitbuffer.COLOR_WHITE
            local circle = FrameContainer:new{ width = action_btn_size, height = action_btn_size, radius = math.floor(action_btn_size / 2), bordersize = border, background = bg, padding = 0, CenterContainer:new{ dimen = Geom:new{ w = action_btn_size - border * 2, h = action_btn_size - border * 2 }, icon } }
            
            local label = TextWidget:new{ text = label_text, face = label_font, max_width = fixed_col_width }
            local label_box = CenterContainer:new{ dimen = Geom:new{ w = fixed_col_width, h = label:getSize().h }, label }

            return VerticalGroup:new{ align = "center", circle, VerticalSpan:new{ width = Screen:scaleBySize(2) }, label_box }, circle
        end

        local panel = VerticalGroup:new{ align = "center", VerticalSpan:new{ width = Screen:scaleBySize(8) } }
        refs.button_layout_row = {}

        -- Distribuição dinâmica dos botões em múltiplas fileiras baseada no espaço livre
        if #visible_buttons > 0 then
            local current_row = HorizontalGroup:new{ align = "center" }
            local current_w = 0

            for _, entry in ipairs(visible_buttons) do
                if current_w + fixed_col_width > inner_width and current_w > 0 then
                    table.insert(panel, CenterContainer:new{ dimen = Geom:new{ w = panel_width, h = current_row:getSize().h }, current_row })
                    table.insert(panel, VerticalSpan:new{ width = Screen:scaleBySize(10) })
                    current_row = HorizontalGroup:new{ align = "center" }
                    current_w = 0
                end

                local def = entry.def
                local label_text = def.label_func and def.label_func() or def.label
                local active   = def.active_func   and def.active_func()   or false
                local disabled = def.disabled_func and def.disabled_func() or false
                local btn_widget, btn_circle = makeActionButton(def.icon, label_text, active and not disabled, disabled)

                table.insert(refs.buttons, { widget = btn_circle, callback = not disabled and function() def.callback(touch_menu) end or nil, hold_callback = def.hold_callback and function() def.hold_callback(touch_menu) end or nil })
                table.insert(refs.button_layout_row, btn_circle)
                
                table.insert(current_row, btn_widget)
                current_w = current_w + fixed_col_width
            end

            if current_w > 0 then
                table.insert(panel, CenterContainer:new{ dimen = Geom:new{ w = panel_width, h = current_row:getSize().h }, current_row })
                table.insert(panel, VerticalSpan:new{ width = Screen:scaleBySize(8) })
            end
        end

        local medium_font = Font:getFace("ffont", 20)
        local small_btn_size = Screen:scaleBySize(14)
        local small_btn_width = Screen:scaleBySize(56)
        local slider_gap = Screen:scaleBySize(4)
        local slider_opts = { inner_width = inner_width, slider_width = inner_width - 2 * small_btn_width - 2 * slider_gap, small_btn_width = small_btn_width, slider_gap = slider_gap, medium_font = medium_font, small_btn_size = small_btn_size, powerd = powerd, refs = refs, show_parent = touch_menu.show_parent }

        if config.show_frontlight and Device:hasFrontlight() then 
            table.insert(panel, build_brightness_slider(touch_menu, slider_opts)) 
        end

        if config.show_warmth and Device:hasNaturalLight() then 
            table.insert(panel, build_warmth_slider(touch_menu, slider_opts)) 
        end

        table.insert(panel, VerticalSpan:new{ width = Screen:scaleBySize(8) })

        touch_menu._qs_refs = refs
        return panel
    end

    local function handlePanelGesture(touch_menu, ges, is_hold)
        local refs = touch_menu._qs_refs
        if not refs then return false end
        if not is_hold then for _, sr in ipairs(refs.sliders or {}) do if sr.slider:handleTap(ges) then return true end end end
        for _, btn_ref in ipairs(refs.buttons) do
            if btn_ref.widget.dimen and ges.pos:intersectWith(btn_ref.widget.dimen) then
                if is_hold and btn_ref.hold_callback then btn_ref.hold_callback(); return true
                elseif not is_hold and btn_ref.callback then btn_ref.callback(touch_menu); return true
                elseif not is_hold then return true end
                return false
            end
        end
        return false
    end

    -- ============================================================
    -- Hooks de Sistema do KOReader
    -- ============================================================
    local TouchMenu = require("ui/widget/touchmenu")
    local FocusManager = require("ui/widget/focusmanager")
    local GestureRange = require("ui/gesturerange")

    local orig_init = TouchMenu.init
    function TouchMenu:init()
        self.last_index = 1
        orig_init(self)
        if self.bar and type(self.bar.icon_widgets) == "table" then
            for _, btn in ipairs(self.bar.icon_widgets) do
                if btn and btn.image and not btn.image.dimen then
                    local ok_sz, sz = pcall(function() return btn.image:getSize() end)
                    if ok_sz and sz then btn.image.dimen = Geom:new{ w = sz.w, h = sz.h } end
                end
            end
        end
        local sw = (self.screen_size and self.screen_size.w) or Screen:getWidth()
        local sh = (self.screen_size and self.screen_size.h) or Screen:getHeight()
        self.ges_events.HoldCloseAllMenus = { GestureRange:new{ ges = "hold", range = Geom:new{ x = 0, y = 0, w = sw, h = sh } } }
        self.ges_events.PanCloseAllMenus = { GestureRange:new{ ges = "pan", range = Geom:new{ x = 0, y = 0, w = sw, h = sh } } }
        self.ges_events.PanReleaseCloseAllMenus = { GestureRange:new{ ges = "pan_release", range = Geom:new{ x = 0, y = 0, w = sw, h = sh } } }
        self.ges_events.MultiSwipe = { GestureRange:new{ ges = "multiswipe", range = Geom:new{ x = 0, y = 0, w = sw, h = sh } } }
    end

    local orig_updateItems = TouchMenu.updateItems
    function TouchMenu:updateItems(target_page, target_item_id)
        if not self.item_table or not self.item_table.panel then
            self._qs_refs = nil
            return orig_updateItems(self, target_page, target_item_id)
        end
        if not self._qs_refs then
            self._qs_slider_locked = true
            UIManager:scheduleIn(0.35, function() self._qs_slider_locked = false end)
        end
        self.item_group:clear()
        self.layout = {}
        table.insert(self.item_group, self.bar)
        table.insert(self.layout, self.bar.icon_widgets)
        
        local panel = createQuickSettingsPanel(self)
        table.insert(self.item_group, panel)
        
        local qs_refs = self._qs_refs
        if qs_refs and qs_refs.button_layout_row and #qs_refs.button_layout_row > 0 then
            table.insert(self.layout, qs_refs.button_layout_row)
        end
        
        table.insert(self.item_group, self.footer_top_margin)
        table.insert(self.item_group, self.footer)
        self.page = self.page or 1
        self.page_info_text:setText("")
        self.page_info_left_chev:showHide(false)
        self.page_info_right_chev:showHide(false)
        self.page_info_left_chev:enableDisable(false)
        self.page_info_right_chev:enableDisable(false)
        local old_dimen = self.dimen:copy()
        self.dimen.w = self.width
        self.dimen.h = self.item_group:getSize().h + self.bordersize * 2 + self.padding
        self:moveFocusTo(self.cur_tab, 1, FocusManager.NOT_FOCUS)
        local keep_bg = old_dimen and self.dimen.h >= old_dimen.h
        UIManager:setDirty((self.is_fresh or keep_bg) and self.show_parent or "all", function()
            local refresh_dimen = old_dimen and old_dimen:combine(self.dimen) or self.dimen
            local refresh_type = "ui"
            if self.is_fresh then refresh_type = "flashui"; self.is_fresh = false end
            return refresh_type, refresh_dimen
        end)
    end

    local orig_onTapCloseAllMenus = TouchMenu.onTapCloseAllMenus
    function TouchMenu:onTapCloseAllMenus(arg, ges_ev)
        if self._qs_refs and self.item_table and self.item_table.panel then
            if self._qs_slider_locked then return true end
            if handlePanelGesture(self, ges_ev, false) then return true end
        end
        return orig_onTapCloseAllMenus(self, arg, ges_ev)
    end

    function TouchMenu:onHoldCloseAllMenus(arg, ges_ev)
        if self._qs_refs and self.item_table and self.item_table.panel then
            if not self._qs_slider_locked then handlePanelGesture(self, ges_ev, true) end
        end
        return true
    end

    ZenSlider.installTouchMenuHooks(TouchMenu, {
        in_panel_mode = function(tm) return tm._qs_refs ~= nil and tm.item_table ~= nil and tm.item_table.panel ~= nil end,
        get_sliders = function(tm)
            local refs = tm._qs_refs; if not refs then return {} end
            local sliders = {}
            for _, sr in ipairs(refs.sliders or {}) do table.insert(sliders, sr.slider) end
            return sliders
        end,
        is_locked = function(tm) return tm._qs_slider_locked end,
        swipe_fallback = function(tm, ges) handlePanelGesture(tm, ges, false) end,
        multiswipe_fallback = function(tm, ges) handlePanelGesture(tm, ges, false) end,
    })

    local orig_switchMenuTab = TouchMenu.switchMenuTab
    function TouchMenu:switchMenuTab(tab_num)
        orig_switchMenuTab(self, tab_num)
        if config.open_on_start then self.last_index = 1 end
    end

    local orig_onCloseWidget = TouchMenu.onCloseWidget
    function TouchMenu:onCloseWidget()
        self._qs_refs = nil; self._qs_opening_pan = false
        if orig_onCloseWidget then orig_onCloseWidget(self) end
    end

    local orig_onPrevPage = TouchMenu.onPrevPage
    if orig_onPrevPage then function TouchMenu:onPrevPage() if self.item_table and self.item_table.panel then return true end; return orig_onPrevPage(self) end end
    local orig_onNextPage = TouchMenu.onNextPage
    if orig_onNextPage then function TouchMenu:onNextPage() if self.item_table and self.item_table.panel then return true end; return orig_onNextPage(self) end end

    local ReaderMenu = require("apps/reader/modules/readermenu")
    local FileManagerMenu = require("apps/filemanager/filemanagermenu")

    ReaderMenu._getTabIndexFromLocation = function(self, ges) return self.last_tab_index end
    FileManagerMenu._getTabIndexFromLocation = function(self, ges) return self.last_tab_index end

    local quick_settings_tab = { icon = "quicksettings", remember = false, panel = createQuickSettingsPanel }

    local function buildSettingsMenu()
        local button_toggle_items = {}
        for _, id in ipairs(config_default.button_order) do
            table.insert(button_toggle_items, {
                text = button_display_names[id],
                checked_func = function() return config.show_buttons[id] end,
                callback = function() config.show_buttons[id] = not config.show_buttons[id]; saveConfig() end,
            })
        end
        table.insert(button_toggle_items, 1, {
            text = _("Arrange buttons"), keep_menu_open = true, separator = true,
            callback = function()
                local SortWidget = require("ui/widget/sortwidget")
                local sort_items = {}
                for _, id in ipairs(config.button_order) do
                    if button_defs[id] then table.insert(sort_items, { text = button_display_names[id], orig_item = id, dim = not config.show_buttons[id] }) end
                end
                UIManager:show(SortWidget:new{ title = _("Arrange quick settings buttons"), item_table = sort_items, callback = function() for i, item in ipairs(sort_items) do config.button_order[i] = item.orig_item end; saveConfig() end })
            end,
        })
        return {
            text = _("Quick settings"),
            sub_item_table = {
                { text = _("Buttons"), sub_item_table = button_toggle_items },
                { text = _("Show brightness slider"), checked_func = function() return config.show_frontlight end, callback = function() config.show_frontlight = not config.show_frontlight; saveConfig() end },
                { text = _("Show warmth slider"), checked_func = function() return config.show_warmth end, callback = function() config.show_warmth = not config.show_warmth; saveConfig() end, separator = true },
                { text = _("Show available networks when turning on Wi-Fi"), checked_func = function() return config.show_available_networks end, callback = function() config.show_available_networks = not config.show_available_networks; saveConfig() end },
                { text = _("Always open on this tab"), checked_func = function() return config.open_on_start end, callback = function() config.open_on_start = not config.open_on_start; saveConfig() end },
            },
        }
    end

    local function injectSettingsOrder(order_table, key)
        for _, v in ipairs(order_table) do if v == key then return end end
        table.insert(order_table, "----------------------------")
        table.insert(order_table, key)
    end

    local orig_fm_setUpdateItemTable = FileManagerMenu.setUpdateItemTable
    function FileManagerMenu:setUpdateItemTable()
        if type(self.menu_items) ~= "table" then self.menu_items = {} end
        local FileManagerMenuOrder = require("ui/elements/filemanager_menu_order")
        injectSettingsOrder(FileManagerMenuOrder.setting, "quick_settings_config")
        self.menu_items.quick_settings_config = buildSettingsMenu()
        orig_fm_setUpdateItemTable(self)
        if self.tab_item_table then 
            local has_tab = false
            for _, tab in ipairs(self.tab_item_table) do if tab.icon == "quicksettings" then has_tab = true; break end end
            if not has_tab then table.insert(self.tab_item_table, 1, quick_settings_tab) end
        end
    end

    local orig_reader_setUpdateItemTable = ReaderMenu.setUpdateItemTable
    function ReaderMenu:setUpdateItemTable()
        if type(self.menu_items) ~= "table" then self.menu_items = {} end
        local ReaderMenuOrder = require("ui/elements/reader_menu_order")
        injectSettingsOrder(ReaderMenuOrder.setting, "quick_settings_config")
        self.menu_items.quick_settings_config = buildSettingsMenu()
        orig_reader_setUpdateItemTable(self)
        if self.tab_item_table then 
            local has_tab = false
            for _, tab in ipairs(self.tab_item_table) do if tab.icon == "quicksettings" then has_tab = true; break end end
            if not has_tab then table.insert(self.tab_item_table, 1, quick_settings_tab) end
        end
    end
end

return QuickSettingsPlugin
