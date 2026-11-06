-- CrystalOS updater for CC:Tweaked
-- Downloads a complete release into staging, then swaps files with rollback.
local BASE = "https://raw.githubusercontent.com/nicolastdr/CrystalOS/main/"
local ROOT = "/"
local STATE = "/.crystal"
local STAGE = STATE .. "/stage"
local BACKUP = STATE .. "/backup"
local VERSION_FILE = STATE .. "/installed_version"

local function log(s)
  local path = "/CrystalOS/data/update.log"
  pcall(fs.makeDir, "/CrystalOS/data")
  local ok, f = pcall(fs.open, path, "a")
  if ok and f then
    pcall(f.writeLine, os.date("%Y-%m-%d %H:%M:%S") .. " " .. s)
    pcall(f.close)
  end
end
local function say(s) print("[CrystalOS] " .. s); log(s) end
log("Updater started.");
local requestCounter = 0
local function get(url)
  -- Use a unique URL for every request so stale CDN responses cannot be reused.
  requestCounter = requestCounter + 1
  local stamp = (os.epoch and os.epoch("utc")) or os.time()
  url = url .. "?crystalos_release=0.9.7&cb=" .. tostring(stamp) .. "-" .. tostring(requestCounter)
  local lastError = "HTTP request failed"
  for attempt = 1, 3 do
    local ok, response, reason = pcall(http.get, url, nil, true)
    if ok and response then
      local okRead, body = pcall(response.readAll)
      pcall(response.close)
      if okRead and type(body) == "string" then return body end
      lastError = "Invalid response body"
    else
      lastError = tostring(reason or response or "HTTP request failed")
    end
    if attempt < 3 then sleep(1) end
  end
  return nil, lastError
end
local function safePath(path)
  if type(path) ~= "string" or path == "" then return false end
  if path:sub(1,1) == "/" or path:find("\\",1,true) then return false end
  for part in path:gmatch("[^/]+") do
    if part == ".." or part == "." then return false end
  end
  return true
end
local function writeFile(path, body)
  fs.makeDir(fs.getDir(path))
  local f = fs.open(path, "w")
  if not f then return false end
  f.write(body); f.close()
  return true
end
local function readVersion()
  if not fs.exists(VERSION_FILE) then return "" end
  local f = fs.open(VERSION_FILE, "r")
  if not f then return "" end
  local v = f.readAll(); f.close()
  return v
end
local function restore(changed)
  for i = #changed, 1, -1 do
    local path = changed[i]
    if fs.exists(path) then fs.delete(path) end
    local backup = fs.combine(BACKUP, path)
    if fs.exists(backup) then
      fs.makeDir(fs.getDir(path))
      fs.move(backup, path)
    end
  end
end

if not http then
  say("HTTP is disabled; continuing with the installed version.")
  return
end

local manifestText, err = get(BASE .. "manifest.txt")
if not manifestText then say(err .. "; using installed version."); return end
local okManifest, manifest = pcall(textutils.unserialize, manifestText)
if not okManifest or type(manifest) ~= "table" or type(manifest.version) ~= "string" or type(manifest.files) ~= "table" then
  say("Manifesto invalido (" .. tostring(manifest) .. "); atualizacao cancelada."); return
end
local complete = true
for _, entry in ipairs(manifest.files) do
  if type(entry) ~= "table" or not safePath(entry.path) then
    complete = false
    break
  end
  local localPath = fs.combine(ROOT, entry.path)
  if not fs.exists(localPath) or fs.isDir(localPath) then
    complete = false
    break
  end
  if entry.size and fs.getSize(localPath) ~= entry.size then
    complete = false
    break
  end
end
if ... ~= "force" and readVersion() == manifest.version and complete then
  say("Already up to date (" .. manifest.version .. ").")
  return
end
if not complete then
  say("Missing or damaged files detected; repairing CrystalOS.")
end

say("Preparing update " .. manifest.version)
if fs.exists(STAGE) then fs.delete(STAGE) end
if fs.exists(BACKUP) then fs.delete(BACKUP) end
fs.makeDir(STAGE); fs.makeDir(BACKUP)

local staged = {}
for _, entry in ipairs(manifest.files) do
  if type(entry) ~= "table" or not safePath(entry.path) then
    say("Unsafe path in manifest; update cancelled."); fs.delete(STAGE); return
  end
  local body, downloadErr = get(BASE .. entry.path)
  if not body then
    say("Falha ao baixar " .. entry.path .. " apos 3 tentativas: " .. tostring(downloadErr))
    fs.delete(STAGE); return
  end
  if entry.size and #body ~= entry.size then
    say("Verificacao de tamanho falhou em " .. entry.path .. " (esperado " .. tostring(entry.size) .. ", recebido " .. tostring(#body) .. "); atualizacao cancelada.")
    fs.delete(STAGE); return
  end
  local target = fs.combine(STAGE, entry.path)
  if not writeFile(target, body) then
    say("Could not stage " .. entry.path); fs.delete(STAGE); return
  end
  staged[#staged + 1] = entry.path
end

local changed = {}
for _, path in ipairs(staged) do
  local destination = fs.combine(ROOT, path)
  local source = fs.combine(STAGE, path)
  local backup = fs.combine(BACKUP, path)
  fs.makeDir(fs.getDir(destination))
  if fs.exists(destination) then
    fs.makeDir(fs.getDir(backup))
    local okMove = pcall(fs.move, destination, backup)
    if not okMove then
      say("Backup failed for " .. path); restore(changed); fs.delete(STAGE); return
    end
  end
  local okInstall = pcall(fs.move, source, destination)
  if not okInstall then
    say("Install failed for " .. path); restore(changed)
    if fs.exists(backup) then fs.move(backup, destination) end
    fs.delete(STAGE); return
  end
  changed[#changed + 1] = path
end

fs.makeDir(STATE)
writeFile(VERSION_FILE, manifest.version)
fs.delete(STAGE)
fs.delete(BACKUP)
say("Updated to " .. manifest.version)
