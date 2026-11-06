local root="/CrystalOS"
local function load(path)
 local ok,result=pcall(dofile,root.."/"..path)
 if not ok then
  term.setBackgroundColor(colors.black); term.setTextColor(colors.red); term.clear(); term.setCursorPos(1,1)
  print("CrystalOS - erro ao carregar"); print(tostring(result)); print("Pressione qualquer tecla para reiniciar."); os.pullEvent("key"); os.reboot()
 end
 return result
end
local ui=load("system/ui.lua")
local apps=load("system/apps.lua")
local settings=load("system/settings.lua")
local catalog=load("system/catalog.lua")
local wm=load("system/window_manager.lua")
ui.init(settings)
while true do
 local result=wm.run(catalog,apps,ui,settings)
 if result=="native_terminal" then
  term.setBackgroundColor(colors.black); term.setTextColor(colors.white); term.clear(); term.setCursorPos(1,1)
  print("Terminal nativo do ComputerCraft. Digite exit para voltar ao CrystalOS.")
  shell.run("/rom/programs/shell.lua")
 elseif result=="reboot" then os.reboot()
 elseif result=="shutdown" then os.shutdown()
 else break end
end
