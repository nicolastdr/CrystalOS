local U={}
local settings
function U.init(s) settings=s; settings.load() end
function U.clear(bg) term.setBackgroundColor(bg or colors.black); term.setTextColor(colors.white); term.clear(); term.setCursorPos(1,1) end
function U.header(title)
 term.setBackgroundColor(colors.gray); term.setTextColor(colors.white); term.setCursorPos(1,1); term.clearLine(); term.write("  "..title)
 term.setBackgroundColor(colors.black); term.setTextColor(colors.white); term.setCursorPos(1,3)
end
function U.footer(msg)
 local w,h=term.getSize(); term.setCursorPos(1,h); term.setBackgroundColor(settings.accent or colors.purple); term.setTextColor(colors.black); term.clearLine(); term.write(" "..(msg or "CrystalOS")); term.setBackgroundColor(colors.black); term.setTextColor(colors.white)
end
function U.message(title,body)
 U.clear(colors.black); U.header(title); print(body or ""); print(""); print("Pressione qualquer tecla para voltar."); U.footer("CrystalOS"); os.pullEvent("key")
end
function U.desktop(catalog)
 while true do
  U.clear(colors.black); local w,h=term.getSize()
  term.setTextColor(colors.lightBlue); term.setCursorPos(2,2); term.write("CRYSTAL")
  term.setTextColor(colors.white); term.setCursorPos(2,3); term.write("CrystalOS")
  term.setTextColor(colors.lightGray); term.setCursorPos(2,5); term.write("Seu ambiente de trabalho")
  term.setCursorPos(2,7); term.write("Aplicativos:")
  local visible=math.min(#catalog,math.max(1,h-11))
  for i=1,visible do term.setCursorPos(3,7+i); term.setTextColor(colors.white); term.write(string.format("%2d  %s",i,catalog[i].name:sub(1,math.max(8,w-9)))) end
  term.setCursorPos(2,h-3); term.setTextColor(colors.lightGray); term.write("Numero do app | R reinicia | S desliga")
  U.footer("CrystalOS | Desktop"); write("> "); local choice=read()
  if choice=="r" or choice=="R" then return "reboot" elseif choice=="s" or choice=="S" then return "shutdown" end
  local n=tonumber(choice); if n and catalog[n] then return catalog[n].id end
  U.message("CrystalOS","Opcao invalida.")
 end
end
return U