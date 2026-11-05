-- Instalador online do CrystalOS para CC:Tweaked
-- Execute: crystal_installer
local BASE = "https://raw.githubusercontent.com/nicolastdr/CrystalOS/main/"
local files = {
  ["CrystalOS/system/kernel.lua"]="system/kernel.lua",
  ["CrystalOS/system/settings.lua"]="system/settings.lua",
  ["CrystalOS/system/ui.lua"]="system/ui.lua",
  ["CrystalOS/system/apps.lua"]="system/apps.lua",
}
if not http then
  print("HTTP indisponivel. Ative HTTP nas configuracoes do servidor/mundo.")
  return
end
fs.makeDir("/CrystalOS/system")
fs.makeDir("/CrystalOS/user/documents")
local function download(url)
  local ok, response = pcall(http.get, url)
  if not ok or not response then return nil end
  local body=response.readAll(); response.close(); return body
end
for remote, localPath in pairs(files) do
  write("Baixando "..localPath.." ... ")
  local body=download(BASE..remote)
  if not body then print("FALHOU"); print("Verifique HTTP e internet."); return end
  local f=fs.open("/CrystalOS/"..localPath,"w")
  if not f then print("ERRO ao gravar "..localPath); return end
  f.write(body); f.close(); print("OK")
end
local startup=download(BASE.."CrystalOS/startup.lua")
if not startup then print("Nao foi possivel baixar startup.lua."); return end
local f=fs.open("/startup.lua","w"); f.write(startup); f.close()
print("")
print("CrystalOS instalado! Reinicie o computador.")
