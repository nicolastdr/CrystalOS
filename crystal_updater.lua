-- CrystalOS updater for CC:Tweaked
-- Downloads a complete release into staging, then swaps files with rollback.
local BASE = "https://raw.githubusercontent.com/nicolastdr/CrystalOS/main/"
local ROOT = "/"
local STATE = "/.crystal"
local STAGE = STATE .. "/stage"
local BACKUP = STATE .. "/backup"
local VERSION_FILE = STATE .. "/installed_version"

local function say(s) print("[CrystalOS] " .. s) end
local function get(url)
  local ok, response = pcall(http.get, url, nil, true)
  if not ok or not response then return nil, "HTTP request failed" end
  local okRead, body = pcall(response.readAll)
  pcall(response.close)
  if not okRead or type(body) ~= "string" then return nil, "Invalid response" end
  return body
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
  say("Invalid manifest; update cancelled."); return
end
if ... ~= "force" and readVersion() == manifest.version then
  return
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
    say("Download failed for " .. entry.path .. ": " .. tostring(downloadErr))
    fs.delete(STAGE); return
  end
  if entry.size and #body ~= entry.size then
    say("Size check failed for " .. entry.path .. "; update cancelled.")
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
