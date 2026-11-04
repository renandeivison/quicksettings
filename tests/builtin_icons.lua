-- Run from the plugin directory: lua tests/builtin_icons.lua
local file = assert(io.open("main.lua"))
local source = file:read("*a")
file:close()
local setup = assert(source:match("(    local config_default =.-)    %-%- ===="))
local menu = source:match("(    local function buildButtonIconItems%(%).-)    local function buildSettingsMenu") or ""
local saved = { button_order = { "wifi", "night", "custom_1" } }
local selected_icon, on_select, selected_config, dialog
local env = {
    G_reader_settings = {
        readSetting = function() return saved end,
        saveSetting = function(_, _, value) saved = value end,
    },
    util = { tableDeepCopy = function(value)
        if type(value) ~= "table" then return value end
        local result = {}; for k, v in pairs(value) do result[k] = v end
        return result
    end },
    trim = function(value) return (value:gsub("^%s+", ""):gsub("%s+$", "")) end,
    require = function() return { new = function(_, value)
        value.onShowKeyboard = function() end
        value.getInputText = function(self) return self.input end
        return value
    end } end,
    UIManager = { show = function(_, value) dialog = value end, close = function() end },
    button_defs = { wifi = { icon = "quick_wifi" }, night = { icon = "quick_nightmode" }, custom_1 = { icon = "custom" } },
    button_display_names = { wifi = "Wi-Fi", night = "Night", custom_1 = "My shortcut" },
    _ = function(text) return text end,
    T = function(text, value) return (text:gsub("%%1", value)) end,
    showCustomButtonIconPicker = function(icon, callback) selected_icon, on_select = icon, callback end,
}
setmetatable(env, { __index = _G })
local function load_menu()
    local code = setup .. menu .. '\nreturn buildButtonIconItems, config'
    local chunk
    if setfenv then
        chunk = assert(loadstring(code)); setfenv(chunk, env)
    else chunk = assert(load(code, "builtin_icons", "t", env)) end
    local build, config = chunk()
    selected_config = config
    assert(type(build) == "function", "built-in icon settings are missing")
    return build()
end
local items = load_menu()
assert(#items == 2, "only built-in buttons should be listed")
local editor = items[1].sub_item_table
local updates = 0
local touch_menu = { updateItems = function() updates = updates + 1 end }
editor[1].callback(touch_menu)
assert(selected_icon == "quick_wifi", "picker should start at the default icon")
on_select("xquick_news")
assert(saved.button_icons.wifi == "xquick_news" and updates == 1, "selection must be saved and menu updated")
assert(not saved.button_icons.night, "changing one button must not change another")
items = load_menu() -- new plugin instance, same reader settings
editor = items[1].sub_item_table
editor[1].callback(touch_menu)
assert(selected_icon == "xquick_news", "saved selection must survive reload")
-- Exercise the actual icon argument used by the panel renderer.
local expression = assert(source:match('local btn_widget, btn_circle = makeActionButton%((.-), label_text, active and'))
local render_icon = assert(loadstring('return function(config, entry, def) return ' .. expression .. ' end'))()
assert(render_icon(selected_config, { id = "wifi" }, env.button_defs.wifi) == "xquick_news", "panel must use override")
assert(render_icon(selected_config, { id = "custom_1" }, env.button_defs.custom_1) == "custom", "custom icons must remain intact")
editor[2].callback(touch_menu)
assert(saved.button_icons.wifi == nil, "reset must remove the saved override")
assert(render_icon(selected_config, { id = "wifi" }, env.button_defs.wifi) == "quick_wifi", "reset must restore default")
print("PASS: built-in icon selection, reload, independent buttons, rendering, and reset")

assert(editor[3] and editor[4], "built-in name editor and reset are missing")
editor[3].callback(touch_menu)
dialog.input = "  Wireless  "
dialog.buttons[1][2].callback()
assert(saved.button_names.wifi == "Wireless", "trimmed name must be persisted")
assert(not saved.button_names.night, "renaming must not affect other buttons")
local name_expression = assert(source:match("local label_text = ([^\n]+)"))
local render_name = assert(loadstring('return function(config, entry, def) return ' .. name_expression .. ' end'))()
assert(render_name(selected_config, { id = "wifi" }, { label_func = function() return "SSID" end }) == "Wireless", "panel must use saved name")
items = load_menu()
assert(items[1].text_func() == "Wireless", "renamed name must survive reload and appear in settings")
editor = items[1].sub_item_table
editor[4].callback(touch_menu)
assert(saved.button_names.wifi == nil, "reset must remove the name override")
assert(render_name(selected_config, { id = "wifi" }, { label_func = function() return "SSID" end }) == "SSID", "reset must restore dynamic labels")
editor[3].callback(touch_menu)
dialog.input = "   "
dialog.buttons[1][2].callback()
assert(saved.button_names.wifi == nil, "blank names must restore the default")
print("PASS: built-in naming, persistence, trimming, rendering, and reset")
