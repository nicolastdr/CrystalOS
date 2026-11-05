-- CrystalOS one-file universal installer for CC:Tweaked
-- Run this file to install or repair the complete system automatically.
local BASE = "https://raw.githubusercontent.com/nicolastdr/CrystalOS/main/"
local function get(url)
  local last = "HTTP request failed"
  for attempt = 1, 3 do
    local ok, response, reason = pcall(http.get, url, nil, true)
    if ok and response then
      local readOK, body = pcall(response.readAll)
      pcall(response.close)
      if readOK and type(body) == "string" then return body end
      last = "Invalid response"
    else
      last = tostring(reason or response or last)
    end
    if attempt < 3 then sleep(1) end
  end
  return nil, last
end
term.setBackgroundColor(colors.black); term.setTextColor(colors.white); term.clear(); term.setCursorPos(1,1)
print("CrystalOS - Instalador universal")
print("--------------------------------")
if not http then
  print("HTTP esta desativado. Ative HTTP nas configuracoes do CC:Tweaked.")
  return
end
print("Baixando o mecanismo de instalacao...")
local updater, err = get(BASE .. "crystal_updater.lua")
if not updater then print("Falha ao baixar: "..tostring(err)); return end
local f = fs.open("/crystal_updater.lua","w")
if not f then print("Nao foi possivel gravar o atualizador."); return end
f.write(updater); f.close()
print("Instalando ou reparando todos os arquivos...")
local ok, result = pcall(shell.run,"/crystal_updater.lua","force")
if not ok or result == false then
  print("O instalador encontrou um erro: "..tostring(result))
  return
end
if fs.exists("/CrystalOS/system/kernel.lua") then
  print("")
  print("CrystalOS instalado com sucesso.")
  print("Reinicie para iniciar o sistema.")
else
  print("")
  print("A instalacao nao foi concluida. Veja as mensagens acima.")
end
