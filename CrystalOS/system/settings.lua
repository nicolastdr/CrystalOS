local M = { accent = colors.cyan, wallpaper = colors.blue }
function M.save()
  fs.makeDir("/CrystalOS/data")
  local f = fs.open("/CrystalOS/data/settings", "w")
  if f then f.write(textutils.serialize({accent=M.accent, wallpaper=M.wallpaper})); f.close() end
end
function M.load()
  if fs.exists("/CrystalOS/data/settings") then
    local f=fs.open("/CrystalOS/data/settings","r")
    local raw=f.readAll(); f.close()
    local ok,t=pcall(textutils.unserialize,raw)
    if ok and type(t)=="table" then M.accent=t.accent or M.accent; M.wallpaper=t.wallpaper or M.wallpaper end
  end
end
function M.screen(ui)
  ui.clear(); ui.header("Configuracoes")
  print("Cor de destaque:")
  print("1 - Ciano   2 - Azul   3 - Roxo   4 - Verde")
  write("> "); local n=read()
  local map={ [1]=colors.cyan,[2]=colors.blue,[3]=colors.purple,[4]=colors.green }
  M.accent=map[tonumber(n)] or M.accent
  M.save(); ui.footer("Salvo. Pressione uma tecla."); os.pullEvent("key")
end
return M
