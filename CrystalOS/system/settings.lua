local M = { accent=colors.cyan, wallpaper=colors.blue, labelPosition="below" }
function M.save()
 fs.makeDir("/CrystalOS/data")
 local f=fs.open("/CrystalOS/data/settings","w")
 if f then f.write(textutils.serialize({accent=M.accent,wallpaper=M.wallpaper,labelPosition=M.labelPosition})); f.close() end
end
function M.load()
 if fs.exists("/CrystalOS/data/settings") then
  local f=fs.open("/CrystalOS/data/settings","r")
  if f then
   local raw=f.readAll(); f.close()
   local ok,t=pcall(textutils.unserialize,raw)
   if ok and type(t)=="table" then
    M.accent=t.accent or M.accent
    M.wallpaper=t.wallpaper or M.wallpaper
    M.labelPosition=t.labelPosition or "below"
   end
  end
 end
end
function M.screen(ui)
 while true do
  ui.clear(); ui.header("Configuracoes")
  print("Personalizacao da tela inicial"); print("")
  print("1 - Cor de destaque")
  print("2 - Nome dos aplicativos: "..(M.labelPosition=="side" and "ao lado" or "embaixo"))
  print("3 - Salvar e voltar")
  write("> "); local n=read()
  if n=="1" then
   print("1 Ciano  2 Azul  3 Roxo  4 Verde")
   write("> "); local c=tonumber(read())
   local map={[1]=colors.cyan,[2]=colors.blue,[3]=colors.purple,[4]=colors.green}
   M.accent=map[c] or M.accent
  elseif n=="2" then
   M.labelPosition=M.labelPosition=="side" and "below" or "side"
  elseif n=="3" or n=="" then M.save(); return
  end
 end
end
return M
