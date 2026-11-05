local root="/CrystalOS"
local function load(path)
 local ok,result=pcall(dofile,root.."/"..path)
 if not ok then term.setBackgroundColor(colors.black); term.setTextColor(colors.red); term.clear(); term.setCursorPos(1,1); print("CrystalOS - erro ao carregar"); print(tostring(result)); print("Pressione qualquer tecla para reiniciar."); os.pullEvent("key"); os.reboot() end
 return result
end
local ui=load("system/ui.lua")
local apps=load("system/apps.lua")
local settings=load("system/settings.lua")
local catalog=load("system/catalog.lua")
ui.init(settings)
while true do
 local choice=ui.desktop(catalog)
 if choice=="reboot" then os.reboot() elseif choice=="shutdown" then os.shutdown() else apps.launch(choice,ui,catalog,settings) end
end