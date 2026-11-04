-- Run from the plugin directory: lua tests/custom_button_storage.lua
local file = assert(io.open("main.lua"))
local source = file:read("*a")
file:close()
local code = assert(source:match('(    local custom_buttons_file =.-)    local function removeCustomButton'))
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end
local files = { ["/plugins/quicksettings/custom_buttons.lua"] = {
    custom_7 = { name = "My shortcut", icon = "xquick_news", action = { test = true } },
} }
local settings = {}
function settings:open(path)
    return setmetatable({ data = copy(files[path] or {}), file = path }, { __index = self })
end
function settings:wrap(data) return { data = data } end
function settings:has(key) return self.data[key] ~= nil end
function settings:readSetting(key) return self.data[key] end
function settings:saveSetting(key, value) self.data[key] = value end
function settings:flush() files[self.file] = copy(self.data) end
local config = { next_custom_id = 0 }
local function start()
    local env = {
        self = { path = "/plugins/quicksettings" },
        DataStorage = { getSettingsDir = function() return "/settings" end },
        LuaSettings = settings,
        config = config,
        saveConfig = function() end,
    }
    setmetatable(env, { __index = _G })
    local chunk_code = code .. '\nreturn custom_buttons_settings.data, saveCustomButtons'
    local chunk
    if setfenv then
        chunk = assert(loadstring(chunk_code)); setfenv(chunk, env)
    else
        chunk = assert(load(chunk_code, "custom_button_storage", "t", env))
    end
    return chunk()
end
local buttons, save = start()
assert(buttons.custom_7.name == "My shortcut", "legacy button was not imported")
buttons.custom_7.name = "Renamed shortcut"
save()
files["/plugins/quicksettings/custom_buttons.lua"] = nil -- reinstall removes plugin-local files
buttons, save = start()
assert(buttons.custom_7 and buttons.custom_7.name == "Renamed shortcut",
    "custom buttons must survive replacement of the plugin directory")
assert(buttons.custom_7.icon == "xquick_news" and buttons.custom_7.action.test,
    "icon and action must survive migration")
assert(config.next_custom_id >= 7, "ID allocation must not overwrite restored buttons")
print("PASS: migration, editing, and plugin reinstall preserve custom buttons")
buttons.custom_7 = nil
save()
files["/plugins/quicksettings/custom_buttons.lua"] = { custom_7 = { name = "stale" } }
buttons = start()
assert(next(buttons) == nil, "deleted buttons must not be imported again from the legacy file")
print("PASS: an empty saved button list does not resurrect legacy buttons")
