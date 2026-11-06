local A={}
local function pause() print(""); print("Pressione uma tecla."); os.pullEvent("key") end
local function ask(label) write(label..": "); return read() end
local function folder(path) if not fs.exists(path) then fs.makeDir(path) end end
local function save(path,data) folder(fs.getDir(path)); local f=fs.open(path,"w"); if f then f.write(data); f.close(); return true end; return false end
local function editor(ui,title,path)
 ui.clear(); ui.header(title); print("Arquivo: "..path); print("Digite o conteudo. Uma linha /salvar encerra.")
 local lines={}; while true do local s=read(); if s=="/salvar" then break end; lines[#lines+1]=s end
 if save(path,table.concat(lines,"\n")) then ui.message(title,"Salvo em "..path) else ui.message(title,"Falha ao salvar.") end
end
local function listFiles(path,needle,out)
 if #out>=40 then return end
 local ok,items=pcall(fs.list,path); if not ok then return end
 for _,name in ipairs(items) do
  local p=fs.combine(path,name)
  if fs.isDir(p) then listFiles(p,needle,out)
  elseif name:lower():find(needle:lower(),1,true) then out[#out+1]=p end
  if #out>=40 then return end
 end
end
function A.explorer(ui)
 local path="/"
 while true do
  ui.clear(); ui.header("Explorador de arquivos"); print("Caminho: "..path); print("")
  local items=fs.list(path); for i=1,math.min(#items,14) do local p=fs.combine(path,items[i]); print((fs.isDir(p) and "[DIR] " or "      ")..items[i]) end
  print(""); print("Digite pasta/arquivo; .. sobe; vazio volta.")
  local s=ask("Abrir")
  if s=="" then return elseif s==".." then path=fs.getDir(path); if path=="" then path="/" end
  else local p=fs.combine(path,s)
   if fs.exists(p) and fs.isDir(p) then path=p
   elseif fs.exists(p) then local f=fs.open(p,"r"); local body=f and f.readAll() or ""; if f then f.close() end; ui.message(s,body:sub(1,1200))
   else ui.message("Explorador","Caminho nao encontrado.") end
  end
 end
end
function A.notepad(ui) editor(ui,"Bloco de notas","/CrystalOS/user/documents/"..(ask("Nome do arquivo") or "nota.txt")) end
function A.calculator(ui)
 ui.clear(); ui.header("Calculadora"); print("Expressao numerica (ex.: (12+3)*4)")
 local expr=ask("Expressao")
 if expr and expr:match("^[%d%+%-%*/%%%^%(%)%.%s]+$") then
  local fn=load("return "..expr); if fn then local ok,res=pcall(fn); print(ok and tostring(res) or "Expressao invalida.") else print("Expressao invalida.") end
 else print("Use apenas numeros e operadores.") end; pause()
end
-- Divide uma linha de comando em argumentos, respeitando aspas.
-- Usado apenas quando a API shell.execute nao esta disponivel.
-- Parser simples de argumentos: preserva espacos dentro de aspas.
local function splitCommand(line)
 local args,buf={},{}
 local quote,escaped=nil,false
 local function push()
  if #buf>0 then args[#args+1]=table.concat(buf); buf={} end
 end
 for i=1,#line do
  local ch=line:sub(i,i)
  if escaped then buf[#buf+1]=ch; escaped=false
  elseif ch=="\\" then escaped=true
  elseif quote then
   if ch==quote then quote=nil else buf[#buf+1]=ch end
  elseif ch=="'" or ch=='"' then quote=ch
  elseif ch:match("%s") then push()
  else buf[#buf+1]=ch end
 end
 if escaped then buf[#buf+1]="\\" end
 push()
 return args
end

local function findProgram(program,currentDir,searchPath)
 if program:sub(1,1)=="/" then
  if fs.exists(program) and not fs.isDir(program) then return program end
  if fs.exists(program..".lua") and not fs.isDir(program..".lua") then return program..".lua" end
  return nil
 end
 local candidates={}
 if program:find("/",1,true) then
  candidates[#candidates+1]=fs.combine(currentDir,program)
 else
  candidates[#candidates+1]=fs.combine(currentDir,program)
  for dir in searchPath:gmatch("[^:]+") do candidates[#candidates+1]=fs.combine(dir,program) end
 end
 for _,path in ipairs(candidates) do
  if fs.exists(path) and not fs.isDir(path) then return path end
  if fs.exists(path..".lua") and not fs.isDir(path..".lua") then return path..".lua" end
 end
 return nil
end

local function makeTerminalShell(initialDir)
 local state={dir=initialDir or "/",path=(os.getenv and os.getenv("PATH")) or ".:/rom/programs:/rom/programs/turtle"}
 local api={}
 function api.dir() return state.dir end
 function api.setDir(path)
  local resolved=fs.combine(state.dir,path)
  if not fs.exists(resolved) or not fs.isDir(resolved) then error("Not a directory",2) end
  state.dir=resolved
 end
 function api.resolve(path) return fs.combine(state.dir,path) end
 function api.path() return state.path end
 function api.setPath(path) state.path=path end
 function api.resolveProgram(command) return findProgram(command,state.dir,state.path) end
 function api.getRunningProgram() return "/CrystalOS/system/apps.lua" end
 local function execute(program,...)
  if type(program)~="string" then error("program must be a string",2) end
  local path=api.resolveProgram(program)
  if not path then printError("No such program: "..program); return false end
  local env=setmetatable({shell=api},{__index=_G})
  env._G=env
  return os.run(env,path,...)
 end
 function api.execute(program,...) return execute(program,...) end
 function api.run(...)
  local args=splitCommand(table.concat({...}," "))
  if #args==0 then return false end
  local program=table.remove(args,1)
  local unpackArgs=table.unpack or unpack
   return execute(program,unpackArgs(args))
 end
 return api,state
end

function A.launch(id,ui,catalog,settings)
 if id=="explorer" then return A.explorer(ui)
 elseif id=="notepad" then return A.notepad(ui)
 elseif id=="calculator" then return A.calculator(ui)
 elseif id=="settings" then return settings.screen(ui)
 elseif id=="hub" or id=="store" then return appHub(ui,catalog)
 elseif id=="search" then return search(ui)
 elseif id=="doctor" then return doctor(ui)
 elseif id=="appforge" then return appforge(ui)
 elseif id=="planner" then return planner(ui)
 elseif id=="sheets" then return sheets(ui)
 elseif id=="diagram" then return diagram(ui)
 elseif id=="archive" then return archive(ui)
 elseif id=="link" then return network(ui)
 elseif id=="play" then return play(ui)
 elseif id=="clipboard" then return clipboard(ui)
 elseif id=="vault" then return vault(ui)
 elseif id=="flow_studio" then return genericEditor(ui,{name="Flow Studio"},"/CrystalOS/user/flows/novo.flow")
 elseif id=="space" then return genericEditor(ui,{name="Crystal Space"},"/CrystalOS/user/workspaces/espaco.txt")
 elseif id=="mindspace" then return genericEditor(ui,{name="MindSpace"},"/CrystalOS/user/mindspace/mapa.txt")
 elseif id=="motion" then return genericEditor(ui,{name="Crystal Motion"},"/CrystalOS/user/motion/animacao.txt")
 elseif id=="3d_lab" then return genericEditor(ui,{name="Crystal 3D Lab"},"/CrystalOS/user/models/modelo.txt")
 elseif id=="code" then return genericEditor(ui,{name="Crystal Code"},"/CrystalOS/user/code/programa.lua")
 elseif id=="theme_studio" then return settings.screen(ui)
 elseif id=="capture" then return ui.message("Crystal Capture","A API CraftOS nao oferece captura de tela universal. Use o recurso de screenshot do emulador ou do cliente Minecraft.")
 end
 ui.message("CrystalOS","Aplicativo nao encontrado.")
end
return A
