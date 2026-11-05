-- CrystalOS universal installer for CC:Tweaked
-- Run: crystal_installer
local BASE = "https://raw.githubusercontent.com/nicolastdr/CrystalOS/main/"
if not http then
  print("HTTP is disabled. Enable HTTP in the CC:Tweaked server/world settings.")
  return
end
local function download(url)
  local ok, response = pcall(http.get, url, nil, true)
  if not ok or not response then return nil end
  local okRead, body = pcall(response.readAll)
  pcall(response.close)
  if okRead then return body end
  return nil
end
term.clear(); term.setCursorPos(1,1)
print("CrystalOS Universal Installer")
print("----------------------------")
print("Downloading installer engine...")
local updater = download(BASE .. "crystal_updater.lua")
if not updater then
  print("Could not download updater. Check internet and HTTP.")
  return
end
local f = fs.open("/crystal_updater.lua", "w")
if not f then print("Cannot write to computer."); return end
f.write(updater); f.close()
print("Installing/updating CrystalOS...")
shell.run("/crystal_updater.lua", "force")
if fs.exists("/CrystalOS/system/kernel.lua") then
  print("")
  print("CrystalOS files are installed.")
  print("Restart the computer to start CrystalOS.")
else
  print("Installation did not complete. Check the errors above.")
end
