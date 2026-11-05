-- CrystalOS Logo Studio storage helper
-- Each application logo is stored independently under /CrystalOS/user/logos.
local L={}
local palette={"cyan","blue","purple","magenta","green","orange","red","lightBlue"}
function L.save(appId,symbol,colorIndex)
  if type(appId)~="string" or not appId:match("^[%w_%-]+$") then return false,"Identificador invalido" end
  if type(symbol)~="string" or symbol=="" then return false,"Simbolo vazio" end
  colorIndex=tonumber(colorIndex) or 3
  if colorIndex<1 or colorIndex>#palette then colorIndex=3 end
  fs.makeDir("/CrystalOS/user/logos")
  local f=fs.open("/CrystalOS/user/logos/"..appId..".txt","w")
  if not f then return false,"Nao foi possivel salvar" end
  f.write(symbol:sub(1,2).."\n"..tostring(colorIndex)); f.close()
  return true
end
function L.load(appId,defaultSymbol)
  local path="/CrystalOS/user/logos/"..appId..".txt"
  if not fs.exists(path) then return defaultSymbol or "AP",3 end
  local f=fs.open(path,"r"); if not f then return defaultSymbol or "AP",3 end
  local symbol=f.readLine() or defaultSymbol or "AP"
  local color=tonumber(f.readLine() or "3") or 3
  f.close()
  if color<1 or color>#palette then color=3 end
  return symbol:sub(1,2),color
end
return L
