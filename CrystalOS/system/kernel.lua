local root = "/CrystalOS"
local function load(path)
  local ok, result = pcall(dofile, root .. "/" .. path)
  if not ok then
    term.setBackgroundColor(colors.black); term.setTextColor(colors.red); term.clear()
    print("CrystalOS - erro ao carregar")
    print(tostring(result))
    print("Pressione qualquer tecla para reiniciar.")
    os.pullEvent("key"); os.reboot()
  end
  return result
end
local ui = load("system/ui.lua")
local apps = load("system/apps.lua")
local settings = load("system/settings.lua")
ui.init(settings)
while true do
  local choice = ui.desktop()
  if choice == "explorer" then apps.explorer(ui)
  elseif choice == "notepad" then apps.notepad(ui)
  elseif choice == "calculator" then apps.calculator(ui)
  elseif choice == "terminal" then apps.terminal(ui)
  elseif choice == "settings" then settings.screen(ui)
  elseif choice == "reboot" then os.reboot()
  elseif choice == "shutdown" then os.shutdown() end
end
