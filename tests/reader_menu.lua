-- Run from the plugin directory: lua tests/reader_menu.lua
local file = assert(io.open("main.lua"))
local source = file:read("*a")
file:close()
local hooks = source:match("(    local orig_reader_onShowMenu =.-)    local orig_reader_setUpdateItemTable") or ""
local ReaderMenu = {}
function ReaderMenu:onShowMenu(tab_index, do_not_show)
    self.menu_container = {{ item_table = tab_index == 1 and { panel = true } or {} }}
    self.not_shown = do_not_show
    return true
end
local env = {
    ReaderMenu = ReaderMenu,
    Event = { new = function(_, name) return name end },
}
setmetatable(env, { __index = _G })
local chunk
if setfenv then
    chunk = assert(loadstring(hooks))
    setfenv(chunk, env)
else
    chunk = assert(load(hooks, "reader_menu_hooks", "t", env))
end
chunk()
local bottom_open = true
local reader = setmetatable({
    ui = { handleEvent = function(_, event)
        assert(event == "CloseConfigMenu", "unexpected event")
        bottom_open = false
    end },
}, { __index = ReaderMenu })
assert(reader:onShowMenu(1) == true, "opening gesture must remain consumed")
assert(not bottom_open, "QuickSettings must close the bottom panel before it can intercept taps")
print("PASS: opening QuickSettings closes the bottom panel")
bottom_open = true
reader:onShowMenu(2)
assert(bottom_open, "ordinary reader tabs should keep the existing bottom-menu behavior")
print("PASS: other reader tabs retain normal behavior")
reader:onShowMenu(1, true)
assert(bottom_open and reader.not_shown, "building an unseen menu must not close the bottom panel")
print("PASS: background menu construction does not close the bottom panel")
