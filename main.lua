local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local DataStorage = require("datastorage")
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
local LuaSettings = require("luasettings")
local T = require("ffi/util").template
local PLUGIN_VERSION = "1.2.0"

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
        button_order = { "focus", "wifi", "night", "frontlight", "rotate", "rotation", "usb", "search", "cloud", "zlibrary", "calibre", "calibre_search", "streak", "localsend", "stats_progress", "stats_calendar", "battery_stats", "restart", "exit", "sleep", "quickrss", "opds", "puzzle", "crossword", "connections", "casualchess", "kosync", "filebrowserplus", "bookfusion" },
        show_buttons = {
            wifi = true, night = true, frontlight = true, rotate = true, rotation = false, search = false, usb = false, cloud = false,
            zlibrary = false, calibre = false, calibre_search = false, restart = true, exit = true, sleep = true,
            streak = false, stats_progress = false, stats_calendar = false, battery_stats = false,
            localsend = false,
            quickrss = false, opds = false, puzzle = false, crossword = false, connections = false,
            casualchess = false, kosync = false, filebrowserplus = false, bookfusion = false, focus = false,
        },
        show_frontlight = true,
        show_warmth = true,
        show_available_networks = true,
        next_custom_id = 0,
        focus_mode = false,
        focus_hidden_tabs = {},
    }

    local config = G_reader_settings:readSetting("quick_settings_plugin", {})
    for k, v in pairs(config_default) do
        if config[k] == nil then config[k] = util.tableDeepCopy(v) end
    end
    if type(config.show_buttons) ~= "table" then config.show_buttons = util.tableDeepCopy(config_default.show_buttons) end
    if type(config.button_order) ~= "table" then config.button_order = util.tableDeepCopy(config_default.button_order) end
    -- Backfill any new button keys missing from a previously saved config
    for k, v in pairs(config_default.show_buttons) do
        if config.show_buttons[k] == nil then config.show_buttons[k] = v end
    end
    -- Backfill any new buttons missing from a previously saved button_order
    local _button_order_set = {}
    for _, id in ipairs(config.button_order) do _button_order_set[id] = true end
    for _, id in ipairs(config_default.button_order) do
        if not _button_order_set[id] then table.insert(config.button_order, id) end
    end

    local function saveConfig()
        G_reader_settings:saveSetting("quick_settings_plugin", config)
    end

    -- ============================================================
    -- Fase 1 (schema do zen_ui): Camada de dados dos botões customizados
    -- Arquivo próprio, dentro da pasta do plugin (self.path preenchido pelo
    -- próprio KOReader antes do init() — frontend/pluginloader.lua:206).
    --
    -- Formato de cada entrada, portado de zen_ui.koplugin (confirmado lendo
    -- modules/settings/sections/app_launcher_settings.lua:417-443):
    --   custom_buttons_settings.data[id] = {
    --       name = "...", icon = "...",  -- metadados (nunca uma ação)
    --       action = { [id_da_acao_1] = true, ... },  -- SEPARADO, não misturado
    --   }
    -- A ação fica ANINHADA em .action, não junto com name/icon na mesma
    -- tabela (diferente do esquema do profiles.koplugin que eu tinha copiado
    -- antes). Isso importa porque Dispatcher:addSubMenu(caller, items, entry, "action")
    -- só mexe em entry.action — o item "Nothing" (dispatcher.lua:1046-1055)
    -- reconstrói SÓ entry.action do zero, nunca toca entry.name/entry.icon.
    -- ============================================================

    local custom_buttons_file = self.path .. "/custom_buttons.lua"
    local custom_buttons_settings = LuaSettings:open(custom_buttons_file)

    local function saveCustomButtons()
        custom_buttons_settings:flush()
    end

    -- Retorna a tabela de botões customizados (dict: id -> entrada)
    local function getCustomButtons()
        return custom_buttons_settings.data
    end

    local function getCustomButtonById(id)
        return custom_buttons_settings.data[id]
    end

    -- Cria um botão customizado vazio (sem ações ainda — elas são atribuídas
    -- depois via Dispatcher:addSubMenu). `data` deve conter name e icon.
    -- Retorna o id gerado e a entrada criada. O contador next_custom_id
    -- continua no config grande (é só um número, sem risco de corrupção).
    local function addCustomButton(data)
        config.next_custom_id = (config.next_custom_id or 0) + 1
        local id = "custom_" .. config.next_custom_id
        saveConfig()
        custom_buttons_settings.data[id] = {
            name = data.name, icon = data.icon, action = {},
        }
        saveCustomButtons()
        return id, custom_buttons_settings.data[id]
    end

    -- Atualiza nome/ícone (metadados) de um botão existente. As ações em si
    -- são editadas via Dispatcher:addSubMenu, não por aqui.
    local function updateCustomButton(id, data)
        local entry = custom_buttons_settings.data[id]
        if not entry then return false end
        if data.name ~= nil then entry.name = data.name end
        if data.icon ~= nil then entry.icon = data.icon end
        saveCustomButtons()
        return true
    end

    local function removeCustomButton(id)
        if not custom_buttons_settings.data[id] then return false end
        custom_buttons_settings.data[id] = nil
        saveCustomButtons()
        return true
    end


    -- ============================================================
    -- Fase 2 (corrigida): título legível de ações do Dispatcher
    -- settingsList é uma tabela PRIVADA dentro de dispatcher.lua (não existe
    -- Dispatcher.settingsList). A forma correta de interagir de fora é pelos
    -- métodos públicos do módulo (confirmados lendo frontend/dispatcher.lua):
    --   Dispatcher:getNameFromItem(id, settings, dont_show_value) -> título de 1 ação
    --   Dispatcher:menuTextFunc(settings)                         -> resumo de várias
    --     ações numa entrada (usado em plugins/profiles.koplugin/main.lua:355)
    --   Dispatcher:addSubMenu(caller, menu, location, settings)    -> monta
    --     sozinho o menu nativo de seleção de ações (Fase 5)
    --   Dispatcher:execute(settings, exec_props)                  -> executa
    --     todas as ações presentes na entrada (Fase 4, usado abaixo na Fase 3)
    -- ============================================================

    -- Título legível de uma única ação. Nunca falha: se o id não existir
    -- (ex: veio de um plugin desinstalado), o próprio Dispatcher devolve
    -- "Unknown item" em vez de erro/nil.
    local function getActionTitle(action_id)
        return Dispatcher:getNameFromItem(action_id, nil, true)
    end

    -- Detecção de plugins otimizada baseada no sistema de arquivos do KOReader
    local function hasPlugin(name)
        if G_reader_settings:isTrue("plugin_" .. name .. "_enabled") then return true end
        local DataStorage = require("datastorage")
        local candidates = {
            "plugins/" .. name .. ".koplugin/main.lua",
            DataStorage:getDataDir() .. "/plugins/" .. name .. ".koplugin/main.lua",
        }
        for _, path in ipairs(candidates) do
            local f = io.open(path, "r")
            if f then f:close(); return true end
        end
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
            visible_func = function() return Device:hasFrontlight() end,
            active_func = function() return Device:getPowerDevice():isFrontlightOn() end,
            callback = function(touch_menu)
                Device:getPowerDevice():toggleFrontlight()
                touch_menu:updateItems(1)
            end,
        },
        rotation = {
            icon = "quick_rotate",
            label = _("Rotation"),
            visible_func = function() return Device:hasGSensor() end,
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
        quickrss = {
            icon = "quick_quickrss", label = _("QuickRSS"),
            visible_func = function() return hasPlugin("quickrss") end,
            callback = function(touch_menu)
                touch_menu:closeMenu()
                local ok, QuickRSSUI = pcall(require, "modules/ui/feed_view")
                if ok and QuickRSSUI then
                    UIManager:show(QuickRSSUI:new{})
                else
                    local InfoMessage = require("ui/widget/infomessage")
                    UIManager:show(InfoMessage:new{ text = _("QuickRSS plugin is not installed.") })
                end
            end,
        },
        opds = {
            icon = "quick_opds", label = _("OPDS"),
            visible_func = function() return hasPlugin("opds") end,
            callback = function(touch_menu)
                touch_menu:closeMenu()
                UIManager:broadcastEvent(Event:new("ShowOPDSCatalog"))
            end,
        },
        puzzle = {
            icon = "quick_puzzle", label = _("Puzzle"),
            visible_func = function() return hasPlugin("slidepuzzle") end,
            callback = function(touch_menu)
                touch_menu:closeMenu()
                UIManager:broadcastEvent(Event:new("SlidePuzzleOpen"))
            end,
        },
        crossword = {
            icon = "quick_crossword", label = _("Crossword"),
            visible_func = function() return hasPlugin("crossword") end,
            callback = function(touch_menu)
                touch_menu:closeMenu()
                UIManager:broadcastEvent(Event:new("CrosswordMenu"))
            end,
        },
        connections = {
            icon = "quick_connections", label = _("Connections"),
            visible_func = function() return hasPlugin("connections") end,
            callback = function(touch_menu)
                touch_menu:closeMenu()
                local ok_f, FileManager = pcall(require, "apps/filemanager/filemanager")
                local ok_r, ReaderUI = pcall(require, "apps/reader/readerui")
                local ui = (ok_f and FileManager.instance) or (ok_r and ReaderUI.instance)
                if ui and ui.nytconnections then
                    local items = {}
                    ui.nytconnections:addToMainMenu(items)
                    if items.nytconnections and items.nytconnections.callback then
                        items.nytconnections.callback()
                    end
                else
                    local InfoMessage = require("ui/widget/infomessage")
                    UIManager:show(InfoMessage:new{ text = _("Connections plugin is not installed.") })
                end
            end,
        },
        casualchess = {
            icon = "quick_chess", label = _("Casual Chess"),
            visible_func = function() return hasPlugin("casualkochess") end,
            callback = function(touch_menu)
                touch_menu:closeMenu()
                UIManager:broadcastEvent(Event:new("CasualChessStart"))
            end,
        },
        kosync = {
            icon = "quick_sync", label = _("Sync"),
            visible_func = function() return hasPlugin("kosync") end,
            callback = function(touch_menu)
                touch_menu:closeMenu()
                local ok_f, FileManager = pcall(require, "apps/filemanager/filemanager")
                local ok_r, ReaderUI = pcall(require, "apps/reader/readerui")
                local ui = (ok_f and FileManager.instance) or (ok_r and ReaderUI.instance)
                if ui and ui.kosync then
                    NetworkMgr:runWhenOnline(function()
                        if ui.kosync.onSyncBookProgress then
                            ui.kosync:onSyncBookProgress()
                        elseif ui.kosync.onPushProgress then
                            ui.kosync:onPushProgress()
                        end
                    end)
                else
                    local InfoMessage = require("ui/widget/infomessage")
                    UIManager:show(InfoMessage:new{ text = _("KOSync plugin is not available.") })
                end
            end,
        },
        filebrowserplus = {
            icon = "quick_filebrowser", label = _("FileBrowser+"),
            visible_func = function() return hasPlugin("filebrowserplus") end,
            active_func = function()
                local f = io.open("/tmp/filebrowserplus_koreader.pid", "r")
                if not f then return false end
                local pid = f:read("*n"); f:close()
                if not pid then return false end
                return os.execute(string.format("kill -0 %d 2>/dev/null", pid)) == 0
            end,
            callback = function(touch_menu)
                UIManager:broadcastEvent(Event:new("ToggleFilebrowserPlusServer"))
                UIManager:scheduleIn(1.5, function()
                    if touch_menu.item_table and touch_menu.item_table.panel then
                        touch_menu:updateItems(1)
                    end
                end)
            end,
        },
        bookfusion = {
            icon = "quick_bookfusion", label = _("BookFusion"),
            visible_func = function() return hasPlugin("bookfusion") end,
            callback = function(touch_menu)
                touch_menu:closeMenu()
                local ok_f, FileManager = pcall(require, "apps/filemanager/filemanager")
                local ok_r, ReaderUI = pcall(require, "apps/reader/readerui")
                local ui = (ok_f and FileManager.instance) or (ok_r and ReaderUI.instance)
                if ui and ui.bookfusion then
                    if ui.bookfusion.bf_settings:isLoggedIn() then
                        ui.bookfusion:onSearchBooks()
                    else
                        ui.bookfusion:onLinkDevice()
                    end
                else
                    local InfoMessage = require("ui/widget/infomessage")
                    UIManager:show(InfoMessage:new{ text = _("BookFusion plugin is not installed.") })
                end
            end,
        },
        focus = {
            icon = "quick_focus", label = _("Focus Mode"),
            active_func = function() return config.focus_mode == true end,
            callback = function(touch_menu)
                touch_menu:closeMenu()
                local CheckButton = require("ui/widget/checkbutton")
                local ButtonTable  = require("ui/widget/buttontable")
                local HorizontalGroup = require("ui/widget/horizontalgroup")
                local TitleBar = require("ui/widget/titlebar")
                local Size = require("ui/size")

                    -- Map tab id -> icon name in resources/icons/mdlight/
                    local tab_icons = {
                        filemanager_settings = "appbar.filebrowser",
                        setting              = "appbar.settings",
                        tools                = "appbar.tools",
                        search               = "appbar.search",
                        main                 = "appbar.menu",
                        navi                 = "appbar.navigation",
                        typeset              = "appbar.typeset",
                        filemanager          = "appbar.filebrowser",
                    }

                    local all_tabs = {
                        { id = "filemanager_settings", label = _("File Browser Settings") },
                        { id = "setting",              label = _("Settings") },
                        { id = "tools",                label = _("Tools") },
                        { id = "search",               label = _("Search") },
                        { id = "main",                 label = _("Main") },
                        { id = "navi",                 label = _("Navigation") },
                        { id = "typeset",              label = _("Typesetting") },
                    }

                    local ok_f, FileManager = pcall(require, "apps/filemanager/filemanager")
                    local ok_r, ReaderUI = pcall(require, "apps/reader/readerui")
                    local cur_ui = (ok_f and FileManager.instance) or (ok_r and ReaderUI.instance)
                    local known_ids = { quicksettings = true, filemanager = true }
                    for _, t in ipairs(all_tabs) do known_ids[t.id] = true end
                    if cur_ui and cur_ui.menu and cur_ui.menu.tab_item_table then
                        for _, tab in ipairs(cur_ui.menu.tab_item_table) do
                            local tid = tab.id or tab.icon or tab.name
                            if tid and not known_ids[tid] then
                                table.insert(all_tabs, { id = tid, label = tid, icon = tab.icon })
                                if tab.icon then tab_icons[tid] = tab.icon end
                                known_ids[tid] = true
                            end
                        end
                    end

                    local hidden_set = {}
                    for _, id in ipairs(config.focus_hidden_tabs or {}) do
                        hidden_set[id] = true
                    end

                    local dialog
                    local dialog_width = Screen:getWidth() * 0.85
                    local icon_size = Screen:scaleBySize(32)

                    local function buildDialog()
                        local rows = {}
                        for _, tab in ipairs(all_tabs) do
                            local tid = tab.id
                            local cb = CheckButton:new{
                                text = tab.label,
                                checked = hidden_set[tid] == true,
                                callback = function()
                                    hidden_set[tid] = not hidden_set[tid] or nil
                                    UIManager:close(dialog)
                                    dialog = buildDialog()
                                    UIManager:show(dialog)
                                end,
                                width = dialog_width - 2 * Size.padding.default - icon_size - Size.padding.small,
                            }
                            local icon_name = tab_icons[tid]
                            local row
                            if icon_name then
                                local icon_widget = IconWidget:new{
                                    icon = icon_name,
                                    width = icon_size,
                                    height = icon_size,
                                }
                                row = HorizontalGroup:new{
                                    align = "center",
                                    icon_widget,
                                    HorizontalSpan:new{ width = Size.padding.small },
                                    cb,
                                }
                            else
                                row = cb
                            end
                            table.insert(rows, row)
                        end

                        local btn_table = ButtonTable:new{
                            width = dialog_width - 2 * Size.padding.default,
                            buttons = {
                                {
                                    {
                                        text = _("Cancel"),
                                        callback = function()
                                            if dialog then
                                                local dimen = dialog:getSize()
                                                UIManager:close(dialog)
                                                UIManager:setDirty("all", "ui", dimen)
                                            end
                                        end,
                                    },
                                    {
                                        text = _("Apply & Restart"),
                                        is_enter_default = true,
                                        callback = function()
                                            UIManager:close(dialog)
                                            local new_hidden = {}
                                            for _, tab in ipairs(all_tabs) do
                                                if hidden_set[tab.id] then
                                                    table.insert(new_hidden, tab.id)
                                                end
                                            end
                                            config.focus_mode = #new_hidden > 0
                                            config.focus_hidden_tabs = new_hidden
                                            saveConfig()
                                            UIManager:broadcastEvent(Event:new("Restart"))
                                        end,
                                    },
                                },
                            },
                        }

                        local content = VerticalGroup:new{ align = "left" }
                        table.insert(content, TitleBar:new{
                            title = _("Select tabs to hide"),
                            width = dialog_width,
                            with_bottom_line = true,
                        })
                        for _, row in ipairs(rows) do
                            table.insert(content, row)
                        end
                        table.insert(content, VerticalSpan:new{ width = Size.padding.default })
                        table.insert(content, btn_table)

                        local frame = FrameContainer:new{
                            content,
                            background = Blitbuffer.COLOR_WHITE,
                            bordersize = Size.border.window,
                            padding = Size.padding.default,
                            radius = Size.radius.window,
                        }

                        return CenterContainer:new{
                            dimen = Screen:getSize(),
                            frame,
                        }
                    end

                    dialog = buildDialog()
                    UIManager:show(dialog)
            end,
        },
    }

    local button_display_names = {
        wifi = _("Wi-Fi"), night = _("Night mode"), frontlight = _("Frontlight"), rotate = _("Rotate"), rotation = _("Rotation"), usb = _("USB"), restart = _("Restart"), exit = _("Exit"), sleep = _("Sleep"), search = _("File search"), cloud = _("Cloud storage"), zlibrary = _("Z-Library"), calibre = _("Calibre"), calibre_search = _("Calibre Search"), streak = _("Streak"), localsend = _("LocalSend"), stats_progress = _("Reading Progress"), stats_calendar = _("Reading Calendar"), battery_stats = _("Battery Stats"),
        quickrss = _("QuickRSS"), opds = _("OPDS"), puzzle = _("Puzzle"), crossword = _("Crossword"), connections = _("Connections"), casualchess = _("Casual Chess"), kosync = _("KOSync"), filebrowserplus = _("FileBrowser+"), bookfusion = _("BookFusion"), focus = _("Focus Mode"),
    }

    -- ============================================================
    -- Fase 3: Integração dos botões customizados no grid existente
    -- Cada entrada de custom_buttons_settings.data vira uma entrada normal em
    -- button_defs/button_display_names — reaproveita 100% do sistema de
    -- renderização, ordenação (button_order) e visibilidade (show_buttons)
    -- que já existe pros botões fixos. Nenhuma mudança no createQuickSettingsPanel.
    -- ============================================================

    -- Ícone usado enquanto o botão não tem um escolhido, ou quando a entrada
    -- veio incompleta/corrompida.
    local CUSTOM_BUTTON_FALLBACK_ICON = "quick_puzzle"

    -- Garante que uma entrada tem os campos básicos (name/icon/action),
    -- autocorrigindo se necessário (ex: dado antigo do esquema anterior).
    local function ensureCustomButtonEntry(entry, id)
        if type(entry.action) ~= "table" then entry.action = {} end
        if entry.name == nil then entry.name = id end
        return entry
    end

    -- Constrói a entrada de button_defs de um botão customizado. Recebe o
    -- ID (não a tabela em si!) e relê custom_buttons_settings.data[id] toda vez que
    -- for preciso — callback e label_func nunca guardam uma referência velha.
    --
    -- O callback fecha o menu antes de executar e adia a execução pro
    -- próximo tick — mesmo padrão usado por zen_ui.koplugin em
    -- modules/menu/patches/quick_settings.lua:807-813 e
    -- modules/menu/patches/app_launcher.lua:308-314. Necessário porque
    -- Dispatcher:execute usa UIManager:sendEvent (dispatcher.lua:1309), que só
    -- alcança o DeviceListener (onde mora onToggleNightMode e outros
    -- handlers "none") se ele não estiver atrás de outro widget na pilha —
    -- confirmado em frontend/apps/reader/readerui.lua:429 e
    -- frontend/apps/filemanager/filemanager.lua:415, onde o DeviceListener é
    -- registrado sem always_active=true.
    local function buildCustomButtonDef(id)
        local entry = custom_buttons_settings.data[id]
        local icon = (entry and entry.icon) or CUSTOM_BUTTON_FALLBACK_ICON
        return {
            label_func = function()
                local e = custom_buttons_settings.data[id]
                if not e then return id end
                ensureCustomButtonEntry(e, id)
                return e.name or id
            end,
            -- Estático porque o grid só suporta label_func, não icon_func
            -- (confirmado: só def.icon é lido no render do botão). Por isso
            -- installCustomButtonDef precisa ser chamado de novo sempre que
            -- o ícone mudar, pra essa entrada de button_defs ser reconstruída
            -- com o ícone atual.
            icon = icon,
            callback = function(touch_menu)
                if touch_menu then touch_menu:closeMenu() end
                UIManager:nextTick(function()
                    local entry = custom_buttons_settings.data[id]
                    if not entry then return end
                    ensureCustomButtonEntry(entry, id)
                    Dispatcher:execute(entry.action, { qm_show = false })
                end)
            end,
        }
    end

    -- (Re)instala um botão customizado nas tabelas ao vivo (button_defs,
    -- button_display_names) e garante que ele apareça no grid por padrão.
    -- Chamada tanto na inicialização (pros botões já salvos) quanto ao
    -- criar/editar um botão em tempo real.
    local function installCustomButtonDef(id)
        local entry = custom_buttons_settings.data[id]
        if not entry then return end
        ensureCustomButtonEntry(entry, id)
        button_defs[id] = buildCustomButtonDef(id)
        button_display_names[id] = entry.name or id

        local found = false
        for _, existing_id in ipairs(config.button_order) do
            if existing_id == id then found = true; break end
        end
        if not found then table.insert(config.button_order, id) end
        if config.show_buttons[id] == nil then config.show_buttons[id] = true end
    end

    -- Remove um botão customizado das tabelas ao vivo. Não mexe em
    -- button_order/show_buttons: eles simplesmente deixam de ter efeito
    -- porque button_defs[id] não existe mais (mesma checagem de sempre,
    -- linha "if config.show_buttons[id] and button_defs[id] then").
    local function uninstallCustomButtonDef(id)
        button_defs[id] = nil
        button_display_names[id] = nil
    end

    -- Instala todos os botões customizados já salvos (carregados do disco
    -- em sessões anteriores) assim que button_defs/button_display_names existem.
    for id, _ in pairs(custom_buttons_settings.data) do
        installCustomButtonDef(id)
    end

    -- Limpeza única: remove o botão de teste "Teste F3" criado durante a
    -- validação da Fase 3 (é seguro rodar sempre; não faz nada se não existir).
    for id, entry in pairs(custom_buttons_settings.data) do
        if entry.name == _("Teste F3")
            or (entry.settings and (entry.settings.label == _("Teste F3") or entry.settings.name == _("Teste F3"))) then
            uninstallCustomButtonDef(id)
            removeCustomButton(id)
        end
    end

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
        if config.open_on_start then self.last_index = 1 end
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

        -- Update time/battery info in footer (same as original updateItems)
        local datetime = require("datetime")
        local time_info_txt = datetime.secondsToHour(os.time(), G_reader_settings:isTrue("twelve_hour_clock"))
        local powerd = Device:getPowerDevice()
        if Device:hasBattery() then
            local BD = require("ui/bidi")
            local batt_lvl = powerd:getCapacity()
            local batt_symbol = powerd:getBatterySymbol(powerd:isCharged(), powerd:isCharging(), batt_lvl)
            time_info_txt = BD.wrap(time_info_txt) .. " " .. BD.wrap("⌁") .. BD.wrap(batt_symbol) .. BD.wrap(batt_lvl .. "%")
        end
        self.time_info:setText(time_info_txt)

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

    -- ============================================================
    -- Fase 5 (portada de zen_ui.koplugin): seletor de ações com salvamento
    -- e atualização IMEDIATOS, em vez de esperar o evento "FlushSettings"
    -- (que só dispara em certos momentos do ciclo de vida do app — foi
    -- por causa disso que uma ação escolhida no seletor podia não bater
    -- com o que estava salvo em disco, e o menu não se atualizava sem
    -- reiniciar). Portado de
    -- modules/settings/sections/app_launcher_settings.lua:51-91 do zen_ui.
    --
    -- Embrulha cada item que o Dispatcher:addSubMenu gera: depois do
    -- callback original rodar, se ele marcou caller.updated = true
    -- (dispatcher.lua:865,1051,1087), roda on_update na hora — sem
    -- esperar nada. Recursivo porque itens de categoria "string"/
    -- "configurable" abrem um sub_item_table_func próprio (dispatcher.lua,
    -- categoria configurable em _addItem).
    -- ============================================================
    local function wrapDispatchCallbacks(items, caller, on_update)
        if type(items) ~= "table" then return end
        for _, item in ipairs(items) do
            if type(item.callback) == "function" and not item._qs_dispatch_wrapped then
                local orig_callback = item.callback
                item.callback = function(touch_menu, ...)
                    caller.updated = false
                    local result = orig_callback(touch_menu, ...)
                    if caller.updated then
                        caller.updated = false
                        on_update(touch_menu)
                    end
                    return result
                end
                item._qs_dispatch_wrapped = true
            end
            if type(item.hold_callback) == "function" and not item._qs_dispatch_hold_wrapped then
                local orig_hold_callback = item.hold_callback
                item.hold_callback = function(touch_menu, ...)
                    caller.updated = false
                    local result = orig_hold_callback(touch_menu, ...)
                    if caller.updated then
                        caller.updated = false
                        on_update(touch_menu)
                    end
                    return result
                end
                item._qs_dispatch_hold_wrapped = true
            end
            if type(item.sub_item_table_func) == "function" and not item._qs_dispatch_func_wrapped then
                local orig_sub_item_table_func = item.sub_item_table_func
                item.sub_item_table_func = function(...)
                    local sub_items = orig_sub_item_table_func(...)
                    wrapDispatchCallbacks(sub_items, caller, on_update)
                    return sub_items
                end
                item._qs_dispatch_func_wrapped = true
            end
            wrapDispatchCallbacks(item.sub_item_table, caller, on_update)
        end
    end

    -- ============================================================
    -- Seletor de ícone (portado de zen_ui.koplugin/common/ui/zen_icon_picker.lua)
    -- Grade de ícones em tela cheia, paginada por toque/swipe. Só portei o
    -- estilo "page_number" do rodapé de paginação deles (common/ui/zen_pager.lua)
    -- porque é o único estilo que o icon picker deles realmente usa
    -- (chama pager.paint com force_style="page_number" fixo) — os estilos
    -- "dots"/"bar" e o módulo de fonte customizado (library_font) do resto
    -- do tema deles não se aplicam aqui.
    -- ============================================================
    local Pager = {}
    do
        local Screen = require("device").screen
        Pager.CHEV_W = Screen:scaleBySize(60)
        Pager.PN_ICON_SZ = Screen:scaleBySize(36)
        Pager.PN_FOOTER_H = math.max(Pager.PN_ICON_SZ + Screen:scaleBySize(6), Screen:scaleBySize(20))
        function Pager.getHoldSkip() return "10" end
        function Pager.paint(bb, x, y, w, h, cur_page, total_pages)
            if total_pages <= 1 then return end
            local Blitbuffer = require("ffi/blitbuffer")
            local Font = require("ui/font")
            local RenderText = require("ui/rendertext")
            local IconWidget = require("ui/widget/iconwidget")
            local pn_face = Font:getFace("smallinfofont", Font.sizemap and Font.sizemap["xx_smallinfofont"] or 18)
            local text_str = tostring(cur_page)
            local text_w = RenderText:sizeUtf8Text(0, 9999, pn_face, text_str, true, false).x
            local face_h = pn_face.bb_size or pn_face.size or Screen:scaleBySize(10)
            local base_y = y + math.floor(h / 2 + face_h * 0.25)
            local inner_w = w - Pager.CHEV_W * 2
            local text_x = x + Pager.CHEV_W + math.floor((inner_w - text_w) / 2)
            RenderText:renderUtf8Text(bb, text_x, base_y, pn_face, text_str, false, false, Blitbuffer.COLOR_BLACK)
            local icon_y = y + math.floor((h - Pager.PN_ICON_SZ) / 2)
            local il = IconWidget:new{ icon = "chevron.left", width = Pager.PN_ICON_SZ, height = Pager.PN_ICON_SZ, alpha = true }
            local ir = IconWidget:new{ icon = "chevron.right", width = Pager.PN_ICON_SZ, height = Pager.PN_ICON_SZ, alpha = true }
            il:paintTo(bb, x + math.floor((Pager.CHEV_W - Pager.PN_ICON_SZ) / 2), icon_y)
            ir:paintTo(bb, x + w - Pager.CHEV_W + math.floor((Pager.CHEV_W - Pager.PN_ICON_SZ) / 2), icon_y)
        end
    end

    -- Varre as pastas de ícones disponíveis, igual
    -- common/utils.lua:getIconPickerList do zen_ui: ícones do próprio plugin,
    -- ícones customizados do usuário, e o conjunto padrão do KOReader
    -- (resources/icons/mdlight) — assim funciona mesmo sem nenhum ícone
    -- próprio no seu plugin.
    local function getCustomButtonIconList()
        local ok_lfs, lfs = pcall(require, "libs/libkoreader-lfs")
        if not ok_lfs or not lfs then return {} end
        local seen, all = {}, {}
        local function addDir(dir)
            if not dir then return end
            dir = dir:match("^(.*[^/])/*$") or dir
            if lfs.attributes(dir, "mode") ~= "directory" then return end
            local entries = {}
            for f in lfs.dir(dir) do
                if f:match("%.svg$") and not f:match("%.bak%.svg$") then
                    local name = f:sub(1, -5)
                    if not seen[name] then entries[#entries + 1] = { name = name, file = dir .. "/" .. f } end
                end
            end
            table.sort(entries, function(a, b) return a.name < b.name end)
            for _, item in ipairs(entries) do
                seen[item.name] = true
                all[#all + 1] = item
            end
        end
        addDir(self.path .. "/icons")
        local DataStorage = require("datastorage")
        addDir(DataStorage:getDataDir() .. "/icons")
        addDir(lfs.currentdir() .. "/resources/icons/mdlight")
        return all
    end

    -- Grade de ícones em tela cheia. icons_list: { {name=, file=}, ... }.
    -- on_select(name) roda quando o usuário toca um ícone.
    local function showCustomButtonIconPicker(current_icon, on_select)
        local icons_list = getCustomButtonIconList()
        if #icons_list == 0 then
            local InfoMessage = require("ui/widget/infomessage")
            UIManager:show(InfoMessage:new{ text = _("Nenhum ícone encontrado.") })
            return
        end
        local function displayName(item) return (item.name:gsub("^quick_", ""):gsub("^tab_", ""):gsub("^lookup_", "")) end
        table.sort(icons_list, function(a, b) return displayName(a):lower() < displayName(b):lower() end)

        local Screen = require("device").screen
        local Geom = require("ui/geometry")
        local Blitbuffer = require("ffi/blitbuffer")
        local Font = require("ui/font")
        local Size = require("ui/size")
        local IC = require("ui/widget/container/inputcontainer")
        local CC = require("ui/widget/container/centercontainer")
        local FC = require("ui/widget/container/framecontainer")
        local VG = require("ui/widget/verticalgroup")
        local HG = require("ui/widget/horizontalgroup")
        local IW = require("ui/widget/iconwidget")
        local TW = require("ui/widget/textwidget")

        local sw, sh = Screen:getWidth(), Screen:getHeight()
        local icon_sz = Screen:scaleBySize(42)
        local label_size = math.max(Screen:scaleBySize(8), (Font.sizemap and Font.sizemap["xx_smallinfofont"] or Screen:scaleBySize(18)) - Screen:scaleBySize(2))
        local label_face = Font:getFace("smallinfofont", label_size)
        local label_probe = TW:new{ text = "Wg", face = label_face, padding = 0 }
        local label_h = label_probe:getSize().h
        label_probe:free()
        local cell_pad = Screen:scaleBySize(4)
        local max_cell_brd = Screen:scaleBySize(2)
        local pad = Size.padding.default
        local span = Size.span.vertical_default
        local bar_area_h = Pager.PN_FOOTER_H

        local back_sz = Screen:scaleBySize(24)
        local back_gap = Screen:scaleBySize(6)
        local back_iw = IW:new{ icon = "chevron.left", width = back_sz, height = back_sz }

        local content_w = sw - 2 * pad
        local cols = math.max(4, math.floor(content_w / Screen:scaleBySize(78)))
        local cell_w = math.floor(content_w / cols)
        local cell_h = icon_sz + label_h + cell_pad * 2 + max_cell_brd * 2
        local label_max_w = cell_w - cell_pad * 2 - max_cell_brd * 2

        local title_text_w = content_w - back_sz - back_gap
        local title_tw = TW:new{ text = _("Select icon"), face = Font:getFace("smallinfofont"), bold = true, width = title_text_w }
        local title_text_h = title_tw:getSize().h
        local title_h = math.max(back_sz, title_text_h)

        local overhead = 2 * pad + title_h + span + span + bar_area_h
        local max_grid_h = math.max(cell_h, sh - overhead)
        local rows_per_page = math.max(1, math.floor(max_grid_h / cell_h))
        local grid_h = rows_per_page * cell_h
        local per_page = cols * rows_per_page
        local total_pages = math.max(1, math.ceil(math.max(#icons_list, 1) / per_page))

        local cur_page = 1
        local page_vgs = {}
        for p = 1, total_pages do
            local pv = VG:new{ align = "left" }
            local start_i = (p - 1) * per_page + 1
            local row_g
            for offset = 0, per_page - 1 do
                local i = start_i + offset
                if i > #icons_list then break end
                if offset % cols == 0 then
                    row_g = HG:new{ align = "top" }
                    table.insert(pv, row_g)
                end
                local item = icons_list[i]
                local name = item.name
                local is_sel = (current_icon == name)
                local short = displayName(item)
                local cell_brd = is_sel and Screen:scaleBySize(2) or Screen:scaleBySize(1)
                table.insert(row_g, FC:new{
                    width = cell_w, height = cell_h, bordersize = cell_brd,
                    color = is_sel and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_LIGHT_GRAY,
                    background = is_sel and Blitbuffer.COLOR_LIGHT_GRAY or Blitbuffer.COLOR_WHITE,
                    padding = cell_pad,
                    CC:new{
                        dimen = Geom:new{ w = cell_w - cell_pad*2 - 2*cell_brd, h = cell_h - cell_pad*2 - 2*cell_brd },
                        VG:new{
                            align = "center",
                            IW:new{ file = item.file or nil, icon = item.file and nil or name, width = icon_sz, height = icon_sz, alpha = true },
                            TW:new{ text = short, face = label_face, max_width = label_max_w, padding = 0 },
                        },
                    },
                })
            end
            page_vgs[p] = pv
        end

        local content_x, content_y = pad, pad
        local grid_x = content_x
        local grid_y = content_y + title_h + span
        local bar_y = grid_y + grid_h + span

        local dialog, closed = nil, false
        local function closeDialog()
            if closed then return end
            closed = true
            UIManager:close(dialog, "ui")
            UIManager:forceRePaint()
        end
        local function goToPage(p)
            if p < 1 or p > total_pages then return end
            cur_page = p
            UIManager:setDirty(dialog, function() return "ui", dialog.dimen end)
        end

        local PickerDlg = IC:extend{}
        function PickerDlg:init()
            self:_init()
            self.dimen = Geom:new{ x = 0, y = 0, w = sw, h = sh }
            self:registerTouchZones({
                {
                    id = "picker_tap", ges = "tap",
                    screen_zone = { ratio_x = 0, ratio_y = 0, ratio_w = 1, ratio_h = 1 },
                    handler = function(ges)
                        local gx, gy = ges.pos.x, ges.pos.y
                        if gx >= content_x and gx < content_x + back_sz and gy >= content_y and gy < content_y + title_h then
                            closeDialog(); return true
                        end
                        if total_pages > 1 and gy >= bar_y and gy < bar_y + bar_area_h and gx >= content_x and gx < content_x + content_w then
                            if gx < content_x + Pager.CHEV_W then
                                goToPage(cur_page > 1 and cur_page - 1 or total_pages)
                            elseif gx >= content_x + content_w - Pager.CHEV_W then
                                goToPage(cur_page < total_pages and cur_page + 1 or 1)
                            end
                            return true
                        end
                        local grid_geom = Geom:new{ x = grid_x, y = grid_y, w = cols * cell_w, h = rows_per_page * cell_h }
                        if ges.pos:intersectWith(grid_geom) then
                            local col_i = math.floor((gx - grid_x) / cell_w)
                            local row_i = math.floor((gy - grid_y) / cell_h)
                            local idx = (cur_page - 1) * per_page + row_i * cols + col_i + 1
                            if idx >= 1 and idx <= #icons_list then
                                local selected_name = icons_list[idx].name
                                closeDialog()
                                UIManager:nextTick(function() on_select(selected_name) end)
                            end
                        end
                        return true
                    end,
                },
                {
                    id = "picker_swipe", ges = "swipe",
                    screen_zone = { ratio_x = 0, ratio_y = 0, ratio_w = 1, ratio_h = 1 },
                    handler = function(ges)
                        local dir = ges.direction
                        if dir == "west" then goToPage(cur_page + 1)
                        elseif dir == "east" then goToPage(cur_page - 1)
                        else closeDialog() end
                        return true
                    end,
                },
            })
        end
        function PickerDlg:paintTo(bb, x, y)
            self.dimen.x = x; self.dimen.y = y
            bb:paintRect(0, 0, sw, sh, Blitbuffer.COLOR_WHITE)
            back_iw:paintTo(bb, content_x, content_y + math.floor((title_h - back_sz) / 2))
            title_tw:paintTo(bb, content_x + back_sz + back_gap, content_y + math.floor((title_h - title_text_h) / 2))
            page_vgs[cur_page]:paintTo(bb, grid_x, grid_y)
            Pager.paint(bb, content_x, bar_y, content_w, bar_area_h, cur_page, total_pages)
        end

        dialog = PickerDlg:new{}
        UIManager:show(dialog, "full")
    end

    local function trim(text) return (text or ""):gsub("^%s+", ""):gsub("%s+$", "") end

    -- Acha o id de uma entrada de custom_buttons_settings.data pela
    -- referência da tabela, não pelo `id` capturado no momento em que a tela
    -- foi montada. Necessário porque buildCustomButtonEntryItems recebe
    -- id=nil pra botões ainda em rascunho — o id real só passa a existir
    -- depois do _qs_draft_commit, mas os callbacks de Ícone/Nome/Apagar já
    -- fecharam sobre esse `nil` antes disso acontecer. É exatamente por
    -- causa disso que o ícone escolhido na criação não pegava até reiniciar.
    local function findCustomButtonId(entry)
        for k, v in pairs(custom_buttons_settings.data) do
            if v == entry then return k end
        end
        return nil
    end

    -- Zera o cache de tab_item_table do FileManagerMenu/ReaderMenu. Ao
    -- contrário de "Custom buttons" (que é mutado ao vivo), "Buttons"
    -- (mostrar/ocultar) e "Arrange buttons" só são reconstruídos dentro de
    -- buildSettingsMenu() — sem isso, um botão novo/renomeado/apagado só
    -- aparecia certo ali depois de reiniciar o KOReader. Confirmado em
    -- frontend/apps/filemanager/filemanagermenu.lua:1017-1019 e
    -- frontend/apps/reader/modules/readermenu.lua:416: onShowMenu só chama
    -- setUpdateItemTable() (onde buildSettingsMenu roda) quando
    -- tab_item_table ainda é nil.
    local function invalidateMenuCache()
        if self.ui and self.ui.menu then
            end
    end

    -- Pergunta o nome do botão (InputDialog), igual prompt_label do zen_ui.
    local function promptCustomButtonName(entry, touch_menu)
        local InputDialog = require("ui/widget/inputdialog")
        local dialog
        dialog = InputDialog:new{
            title = _("Nome do botão"),
            input = entry.name or "",
            buttons = {{
                { text = _("Cancelar"), callback = function() UIManager:close(dialog) end },
                {
                    text = _("Definir"), is_enter_default = true,
                    callback = function()
                        local name = trim(dialog:getInputText())
                        if name ~= "" then entry.name = name end
                        UIManager:close(dialog)
                        if not entry._qs_draft_commit then
                            saveCustomButtons()
                            -- Refresca button_display_names[id] (usado em "Buttons"
                            -- e "Arrange buttons") e o cache do menu principal.
                            local real_id = findCustomButtonId(entry)
                            if real_id then installCustomButtonDef(real_id) end
                            invalidateMenuCache()
                        end
                        if touch_menu and touch_menu.updateItems then touch_menu:updateItems(1) end
                    end,
                },
            }},
        }
        UIManager:show(dialog)
        dialog:onShowKeyboard()
    end

    -- Monta as linhas da tela de edição de UM botão customizado: Concluir,
    -- Ação, Ícone, Nome, Apagar — igual build_entry_items do zen_ui
    -- (app_launcher_settings.lua:500-588), mas só a parte de tipo "action"
    -- (não precisamos de pastas/plugins).
    -- `entry._qs_draft_commit`, se existir, é chamado assim que a 1ª ação for
    -- marcada (fluxo de criação); senão é um botão já existente normal.
    -- `parent_items` é a lista "Custom buttons" que está por baixo dessa tela
    -- (a mesma tabela que o TouchMenu vai restaurar ao voltar) — mutar ela
    -- diretamente aqui é o que faz a lista aparecer atualizada sem precisar
    -- reiniciar (confirmado lendo touchmenu.lua:778-780,858-861: back/entrar
    -- num submenu só restaura/empilha a referência antiga, nunca reconstrói).
    local function buildCustomButtonEntryItems(id, entry, parent_items)
        local items = {}

        local action_items = {}
        local caller = {}
        Dispatcher:addSubMenu(caller, action_items, entry, "action")
        wrapDispatchCallbacks(action_items, caller, function(touch_menu)
            if entry._qs_draft_commit then
                entry._qs_draft_commit()
            else
                saveCustomButtons()
            end
            -- Volta pra tela de edição do botão (Ação/Ícone/Nome/Apagar) em vez
            -- de só atualizar a lista de ações no lugar. touch_menu:updateItems(1)
            -- na verdade força a PÁGINA 1 do menu atual
            -- (TouchMenu:updateItems(target_page, target_item_id), touchmenu.lua:652)
            -- — por isso, ao marcar uma ação numa página 2+ do seletor, a tela
            -- pulava de volta pra primeira página em vez de voltar um nível.
            if touch_menu and touch_menu.backToUpperMenu then touch_menu:backToUpperMenu() end
        end)
        table.insert(items, {
            text_func = function()
                if entry.action and next(entry.action) then
                    return T(_("Ação: %1"), Dispatcher:menuTextFunc(entry.action))
                end
                return _("Ação: (nenhuma)")
            end,
            keep_menu_open = true,
            sub_item_table = action_items,
        })

        table.insert(items, {
            text_func = function() return T(_("Ícone: %1"), entry.icon or _("nenhum")) end,
            keep_menu_open = true,
            callback = function(touch_menu)
                showCustomButtonIconPicker(entry.icon, function(name)
                    entry.icon = name
                    if not entry._qs_draft_commit then
                        saveCustomButtons()
                        -- Usa o id ATUAL (não o "id" capturado quando essa tela foi
                        -- aberta): pra um botão recém-criado, buildCustomButtonEntryItems
                        -- foi chamado com id=nil (ainda era rascunho), e esse valor
                        -- nunca muda depois — era por isso que o ícone escolhido não
                        -- pegava no botão de verdade até reiniciar.
                        local real_id = findCustomButtonId(entry) or id
                        installCustomButtonDef(real_id) -- reconstroi button_defs[id] com o icone novo (nao ha icon_func no grid)
                        invalidateMenuCache()
                    end
                    if touch_menu and touch_menu.updateItems then touch_menu:updateItems(1) end
                end)
            end,
        })

        table.insert(items, {
            text_func = function() return T(_("Nome: %1"), entry.name or id) end,
            keep_menu_open = true,
            callback = function(touch_menu) promptCustomButtonName(entry, touch_menu) end,
        })

        table.insert(items, {
            text = _("Apagar"),
            separator = true,
            callback = function(touch_menu)
                if entry._qs_draft_commit then
                    if touch_menu then touch_menu:backToUpperMenu() end
                    return
                end
                local ConfirmBox = require("ui/widget/confirmbox")
                UIManager:show(ConfirmBox:new{
                    text = _("Apagar este botão?"),
                    ok_text = _("Apagar"),
                    ok_callback = function()
                        local real_id = findCustomButtonId(entry) or id
                        uninstallCustomButtonDef(real_id)
                        removeCustomButton(real_id)
                        invalidateMenuCache()
                        if parent_items then
                            for i, it in ipairs(parent_items) do
                                if it.qs_button_id == real_id then table.remove(parent_items, i); break end
                            end
                        end
                        if touch_menu then touch_menu:backToUpperMenu() end
                    end,
                })
            end,
        })

        -- Botão "Concluir": só volta pra tela anterior. Não precisa fazer
        -- mais nada além disso — cada campo (Ação/Ícone/Nome) já salva e
        -- atualiza a lista sozinho assim que é alterado.
        table.insert(items, 1, {
            text = _("Concluir"),
            separator = true,
            callback = function(touch_menu)
                if touch_menu then touch_menu:backToUpperMenu() end
            end,
        })

        return items
    end

    -- Monta o item de menu de um botão customizado já existente.
    -- `parent_items` é passado adiante pra tela de edição poder se remover
    -- da lista sozinha quando apagada (ver buildCustomButtonEntryItems acima).
    local function buildCustomButtonMenuItem(id, parent_items)
        local entry = custom_buttons_settings.data[id]
        if not entry then return { text = id } end
        ensureCustomButtonEntry(entry, id)
        return {
            qs_button_id = id,
            text_func = function()
                return (entry.name or id) .. ": " .. Dispatcher:menuTextFunc(entry.action)
            end,
            sub_item_table_func = function() return buildCustomButtonEntryItems(id, entry, parent_items) end,
        }
    end

    -- ============================================================
    -- Criação de um botão novo: entrada RASCUNHO (fora de
    -- custom_buttons_settings.data até ser "commitada"), igual
    -- new_action_entry + open_new_action_picker do zen_ui
    -- (app_launcher_settings.lua:239-248, 355-369). Só vira um botão de
    -- verdade (ganha id, é salvo, aparece no grid) quando o usuário marca a
    -- primeira ação no seletor — se desistir sem escolher nada, não sobra
    -- botão vazio salvo. Ao commitar, insere direto na lista "Custom
    -- buttons" que está por baixo (touch_menu.item_table no momento do
    -- toque em "Adicionar" é exatamente essa lista), pelo mesmo motivo do
    -- parent_items acima.
    -- ============================================================
    local function openNewCustomButtonPicker(touch_menu)
        if not (touch_menu and type(touch_menu.updateItems) == "function") then return end
        local parent_items = touch_menu.item_table
        local draft = { name = _("Botão personalizado"), action = {} }
        local committed = false
        draft._qs_draft_commit = function()
            if committed or not (draft.action and next(draft.action)) then return end
            committed = true
            local id = "custom_" .. (config.next_custom_id + 1)
            config.next_custom_id = config.next_custom_id + 1
            saveConfig()
            draft._qs_draft_commit = nil
            custom_buttons_settings.data[id] = draft
            saveCustomButtons()
            installCustomButtonDef(id)
            invalidateMenuCache()
            if parent_items then table.insert(parent_items, buildCustomButtonMenuItem(id, parent_items)) end
        end
        table.insert(touch_menu.item_table_stack, touch_menu.item_table)
        touch_menu.parent_id = nil
        touch_menu.item_table = buildCustomButtonEntryItems(nil, draft, parent_items)
        touch_menu:updateItems(1)
    end

    local function buildSettingsMenu()
        local button_toggle_items = {}
        for _, id in ipairs(config.button_order) do
            if button_defs[id] then
                table.insert(button_toggle_items, {
                    text = button_display_names[id] or id,
                    checked_func = function() return config.show_buttons[id] end,
                    callback = function() config.show_buttons[id] = not config.show_buttons[id]; saveConfig() end,
                })
            end
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

        local custom_buttons_items = {
            { text = _("Adicionar botão customizado"), keep_menu_open = true, separator = true, callback = openNewCustomButtonPicker },
        }
        for id, _ in pairs(custom_buttons_settings.data) do
            table.insert(custom_buttons_items, buildCustomButtonMenuItem(id, custom_buttons_items))
        end

        return {
            text = _("Quick settings"),
            sub_item_table = {
                { text = _("Buttons"), sub_item_table = button_toggle_items },
                { text = _("Custom buttons"), sub_item_table = custom_buttons_items },
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

    -- Focus Mode: filter tabs based on user-selected hidden tabs list
    local function shouldKeepTab(tab, is_reader)
        if not config.focus_mode then return true end

        local hidden = config.focus_hidden_tabs or {}
        local hidden_set = {}
        for _, id in ipairs(hidden) do hidden_set[id] = true end

        -- Always keep quicksettings tab
        local values = {}
        local function push(v)
            if type(v) == "string" then
                local n = v:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
                if n ~= "" then table.insert(values, n) end
            end
        end
        push(tab.id); push(tab.icon); push(tab.name)
        if type(tab.text_func) == "function" then
            local ok, t = pcall(tab.text_func); if ok then push(t) end
        end
        push(tab.text)

        for _, v in ipairs(values) do
            if v == "quicksettings" then return true end
            -- In reader mode, always keep filemanager (back) tab
            if is_reader and v == "filemanager" then return true end
        end

        -- Check against user-selected hidden tabs
        for _, v in ipairs(values) do
            if hidden_set[v] then return false end
        end

        return true
    end

    local function filterTabsForFocus(tab_item_table, is_reader)
        if type(tab_item_table) ~= "table" then return tab_item_table end
        local filtered = {}
        for _, tab in ipairs(tab_item_table) do
            if shouldKeepTab(tab, is_reader) then
                table.insert(filtered, tab)
            end
        end
        return filtered
    end

    local orig_fm_setUpdateItemTable = FileManagerMenu.setUpdateItemTable
    function FileManagerMenu:setUpdateItemTable()
        if type(self.menu_items) ~= "table" then self.menu_items = {} end
        if not self.menu_items["KOMenu:menu_buttons"] then self.menu_items["KOMenu:menu_buttons"] = {} end
        local FileManagerMenuOrder = require("ui/elements/filemanager_menu_order")
        injectSettingsOrder(FileManagerMenuOrder.setting, "quick_settings_config")
        self.menu_items.quick_settings_config = buildSettingsMenu()
        orig_fm_setUpdateItemTable(self)
        if self.tab_item_table then
            local has_tab = false
            for _, tab in ipairs(self.tab_item_table) do if tab.icon == "quicksettings" then has_tab = true; break end end
            if not has_tab then table.insert(self.tab_item_table, 1, quick_settings_tab) end
            if config.focus_mode then
                self.tab_item_table = filterTabsForFocus(self.tab_item_table, false)
            end
        end
    end

    local orig_reader_setUpdateItemTable = ReaderMenu.setUpdateItemTable
    function ReaderMenu:setUpdateItemTable()
        if type(self.menu_items) ~= "table" then self.menu_items = {} end
        if not self.menu_items["KOMenu:menu_buttons"] then self.menu_items["KOMenu:menu_buttons"] = {} end
        local ReaderMenuOrder = require("ui/elements/reader_menu_order")
        injectSettingsOrder(ReaderMenuOrder.setting, "quick_settings_config")
        self.menu_items.quick_settings_config = buildSettingsMenu()
        orig_reader_setUpdateItemTable(self)
        if self.tab_item_table then
            local has_tab = false
            for _, tab in ipairs(self.tab_item_table) do if tab.icon == "quicksettings" then has_tab = true; break end end
            if not has_tab then table.insert(self.tab_item_table, 1, quick_settings_tab) end
            if config.focus_mode then
                self.tab_item_table = filterTabsForFocus(self.tab_item_table, true)
            end
        end
    end
end

return QuickSettingsPlugin
