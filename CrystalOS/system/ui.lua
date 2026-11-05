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
 local page=1
 local w,h=term.getSize()
 local pageSize=math.max(1,math.min(7,h-12))
 local pages=math.ceil(#catalog/pageSize)
 while true do
  U.clear(colors.black); term.setTextColor(colors.lightBlue); term.setCursorPos(2,2); term.write("CRYSTAL")
  term.setTextColor(colors.white); term.setCursorPos(2,3); term.write("CrystalOS")
  term.setTextColor(colors.lightGray); term.setCursorPos(2,5); term.write("Seu ambiente de trabalho")
  term.setCursorPos(2,7); term.write("Aplicativos  |  Pagina "..page.."/"..pages)
  local first=(page-1)*pageSize+1
  for i=first,math.min(#catalog,first+pageSize-1) do
   term.setCursorPos(3,7+(i-first)+1); term.setTextColor(colors.white)
   term.write(string.format("%2d  %s",i,catalog[i].name:sub(1,math.max(8,w-9))))
  end
  term.setCursorPos(2,h-3); term.setTextColor(colors.lightGray); term.write("Numero abre | N proxima | P anterior")
  U.footer("R reinicia | S desliga | CrystalOS Desktop")
  write("> "); local choice=read()
  if choice=="r" or choice=="R" then return "reboot"
  elseif choice=="s" or choice=="S" then return "shutdown"
  elseif choice=="n" or choice=="N" then page=math.min(pages,page+1)
  elseif choice=="p" or choice=="P" then page=math.max(1,page-1)
  else local n=tonumber(choice); if n and catalog[n] then return catalog[n].id else U.message("CrystalOS","Opcao invalida.") end end
 end
end
return U