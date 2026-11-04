-- Run from the plugin directory: lua tests/button_order.lua
-- Exercise the real config-loading and arrangement code without KOReader's UI.
local file = assert(io.open("main.lua"))
local source = file:read("*a")
file:close()
local setup = assert(source:match("(    local config_default =.-)    %-%- ===="))
local toggles = assert(source:match("(    local function buildButtonToggleItems%(%).-)    local function buildSettingsMenu"))
local load_chunk = loadstring or load
local function fixture(order)
    local saved = { button_order = order, show_buttons = { custom_2 = false } }
    local sort_widget
    local env = {
        G_reader_settings = {
            readSetting = function() return saved end,
            saveSetting = function(_, _, value) saved = value end,
        },
        util = { tableDeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local copy = {}
            for k, v in pairs(value) do copy[k] = v end
            return copy
        end },
        button_defs = { wifi = {}, custom_2 = {} },
        button_display_names = { wifi = "Wi-Fi", custom_2 = "Shortcut" },
        _ = function(text) return text end,
        require = function() return { new = function(_, widget) return widget end } end,
        UIManager = { show = function(_, widget) sort_widget = widget end },
    }
    setmetatable(env, { __index = _G })
    local code = setup .. toggles .. "\nreturn buildButtonToggleItems, function() return config.button_order end"
    local chunk
    if setfenv then
        chunk = assert(load_chunk(code))
        setfenv(chunk, env)
    else
        chunk = assert(load_chunk(code, "button_order", "t", env))
    end
    local items, get_order = chunk()
    return function(sorted_ids)
        items()[1].callback()
        for i = #sort_widget.item_table, 1, -1 do
            table.remove(sort_widget.item_table, i)
        end
        for _, id in ipairs(sorted_ids) do
            table.insert(sort_widget.item_table, { orig_item = id })
        end
        sort_widget.callback()
        return get_order()
    end, get_order
end
local function assert_order(actual, expected)
    assert(table.concat(actual, ",") == table.concat(expected, ","),
        "expected " .. table.concat(expected, ",") .. "; got " .. table.concat(actual, ","))
end

-- Deleting the first custom button leaves a stale ID in the saved list.
-- Sorting must replace that list, including its old tail.
local arrange = fixture({ "wifi", "custom_1", "custom_2" })
assert_order(arrange({ "custom_2", "wifi" }), { "custom_2", "wifi" })
assert_order(arrange({ "wifi", "custom_2" }), { "wifi", "custom_2" })
print("PASS: arrangement removes deleted entries and stays stable on repeat")

-- Existing duplicates must also be repaired when loading settings.
local _, get_order = fixture({ "wifi", "custom_2", "custom_2", "wifi" })
local seen = {}
for _, id in ipairs(get_order()) do
    assert(not seen[id], "duplicate persisted ID: " .. id)
    seen[id] = true
end
assert(seen.custom_2 and seen.wifi and seen.focus, "lost existing or newly backfilled buttons")
print("PASS: loading repairs duplicates and backfills built-in buttons")
