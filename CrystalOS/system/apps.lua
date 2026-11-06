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

function A.crystalTerminal(ui,catalog)
 local function sizeOf(path)
  if not fs.exists(path) then return 0 end
  if not fs.isDir(path) then return fs.getSize(path) end
  local total=0
  for _,name in ipairs(fs.list(path)) do total=total+sizeOf(fs.combine(path,name)) end
  return total
 end
 local function bytes(n)
  if n>=1024*1024 then return string.format("%.2f MB",n/1024/1024)
  elseif n>=1024 then return string.format("%.2f KB",n/1024)
  else return tostring(n).." bytes" end
 end
 local function output(s) print(tostring(s)) end
 local function runCommand(line)
  local args=splitCommand(line); local cmd=(args[1] or ""):lower()
  if cmd=="" then return
  elseif cmd=="help" or cmd=="ajuda" then
   output("Comandos CrystalOS:")
   output("help - mostra esta ajuda")
   output("clear - limpa a tela")
   output("about - informacoes do CrystalOS")
   output("sysinfo - estado do computador e ambiente")
   output("storage - uso de armazenamento")
   output("scan - detecta perifericos conectados")
   output("inspect <caminho> - analisa arquivo ou pasta")
   output("apps - lista aplicativos instalados")
   output("where - mostra a pasta atual")
   output("exit OS - encerra o CrystalOS e retorna ao CraftOS")
   output("exit - fecha apenas este aplicativo")
  elseif cmd=="clear" or cmd=="cls" then ui.clear()
  elseif cmd=="about" then output("CrystalOS 0.9.8 | Crystal Terminal")
  elseif cmd=="where" then output("Diretorio atual: /CrystalOS")
  elseif cmd=="sysinfo" then
   local w,h=term.getSize()
   output("Sistema: CrystalOS 0.9.8")
   output("Ambiente: "..(os.version and os.version() or "CraftOS"))
   output("Computador ID: "..tostring(os.getComputerID and os.getComputerID() or "indisponivel"))
   output("Label: "..tostring(os.getComputerLabel and os.getComputerLabel() or "sem nome"))
   output("Terminal: "..w.." x "..h)
   output("HTTP: "..tostring(http~=nil))
   output("Redstone: "..tostring(redstone~=nil))
  elseif cmd=="storage" then
   local used=sizeOf("/")
   local free=fs.getFreeSpace and fs.getFreeSpace("/") or nil
   local capacity=fs.getCapacity and fs.getCapacity("/") or nil
   output("Armazenamento acessivel")
   output("Espaco ocupado: "..bytes(used))
   output("Espaco livre: "..(type(free)=="number" and bytes(free) or tostring(free or "nao informado")))
  elseif cmd=="scan" then
   local names=peripheral.getNames()
   output("Perifericos detectados: "..#names)
   for _,name in ipairs(names) do
    local types=peripheral.getType(name)
    output("- "..name.." : "..tostring(types))
   end
   output("Modem rednet: "..tostring(peripheral.find("modem")~=nil))
   output("Monitor: "..tostring(peripheral.find("monitor")~=nil))
   output("Drive: "..tostring(peripheral.find("drive")~=nil))
  elseif cmd=="inspect" then
   local path=args[2]
   if not path then output("Uso: inspect <caminho>")
   elseif not fs.exists(path) then output("Caminho nao encontrado: "..path)
   elseif fs.isDir(path) then
    local count=0; for _ in ipairs(fs.list(path)) do count=count+1 end
    output("Tipo: pasta"); output("Itens diretos: "..count); output("Tamanho total: "..bytes(sizeOf(path)))
   else
    output("Tipo: arquivo"); output("Tamanho: "..bytes(fs.getSize(path))); output("Nome: "..fs.getName(path))
    local ext=fs.getName(path):match("%.([^%.]+)$"); output("Extensao: "..(ext or "sem extensao"))
   end
  elseif cmd=="apps" then
   output("Aplicativos registrados: "..#catalog)
   for _,app in ipairs(catalog) do output("- "..app.name.." ["..app.id.."]") end
  elseif cmd=="exit" and (args[2] or ""):lower()=="os" then
   os.queueEvent("crystal_exit_os"); return "exit_os"
  elseif cmd=="exit" then return "close"
  else output("Comando desconhecido: "..cmd..". Digite help.") end
 end
 while true do
  ui.clear(); ui.header("Crystal Terminal")
  print("Terminal de administracao do CrystalOS 0.9.8")
  print("Digite help para ver os comandos.")
  print("exit OS sai completamente do CrystalOS.")
  print("")
  local line=read()
  local result=runCommand(line or "")
  if result=="exit_os" then return "exit_os"
  elseif result=="close" then return end
  if result~="exit_os" then pause() end
 end
end

local function genericEditor(ui,app,path) editor(ui,app.name,path) end
local function appHub(ui,catalog)
 local lines={}; for _,a in ipairs(catalog) do lines[#lines+1]=a.name.." ["..a.category.."] - "..a.description end
 ui.message("Crystal Hub",table.concat(lines,"\n"))
end
local function search(ui)
 ui.clear(); ui.header("Crystal Search"); local q=ask("Nome/trecho do arquivo"); if q=="" then return end
 local found={}; listFiles("/",q,found); ui.message("Resultados",#found==0 and "Nenhum arquivo encontrado." or table.concat(found,"\n"))
end
local function doctor(ui)
 local w,h=term.getSize(); local free=0
 for _,p in ipairs(fs.list("/")) do free=free+1 end
 local modem=peripheral.find("modem")~=nil
 local sh=rawget(_G,"shell")
 local shellRun=type(sh)=="table" and type(sh.run)=="function"
 local shellExecute=type(sh)=="table" and type(sh.execute)=="function"
 ui.message("Crystal Doctor","Diagnostico CraftOS\nTerminal: "..w.."x"..h.."\nItens na raiz: "..free.."\nModem detectado: "..tostring(modem).."\nHTTP disponivel: "..tostring(http~=nil).."\nAPI shell: "..tostring(type(sh)=="table").."\nshell.run: "..tostring(shellRun).."\nshell.execute: "..tostring(shellExecute).."\nos.run: "..tostring(type(os.run)=="function").."\nEnergia/perifericos: consulte o computador hospedeiro.")
end
local function appforge(ui)
 ui.clear(); ui.header("Crystal AppForge"); print("Criador simples de aplicativos CrystalOS.")
 local id=ask("ID (sem espacos)"); if not id:match("^[%w_%-]+$") then ui.message("AppForge","ID invalido."); return end
 local name=ask("Nome do aplicativo"); local desc=ask("Descricao")
 local path="/CrystalOS/user/apps/"..id..".app"
 local data=textutils.serialize({id=id,name=name,description=desc,version="1.0",type="text-app"})
 save(path,data); ui.message("AppForge","Projeto criado em "..path.."\nEdite o arquivo pelo Crystal Code para ampliar o projeto.")
end
local function planner(ui)
 local path="/CrystalOS/user/planner/tasks.txt"; local old=""
 if fs.exists(path) then local f=fs.open(path,"r"); old=f.readAll(); f.close() end
 ui.clear(); ui.header("Crystal Planner"); print("Tarefas atuais:\n"..old); print("1 adicionar  2 limpar  0 voltar")
 local n=ask("Opcao")
 if n=="1" then local t=ask("Nova tarefa"); save(path,old..(old=="" and "" or "\n").."- [ ] "..t)
 elseif n=="2" then save(path,"") end
end
local function sheets(ui)
 ui.clear(); ui.header("Crystal Sheets"); print("Planilha CSV simples. Uma linha por vez; /fim salva.")
 local rows={}; while true do local s=read(); if s=="/fim" then break end; rows[#rows+1]=s end
 local name=ask("Nome da planilha"); if name=="" then name="planilha.csv" end
 save("/CrystalOS/user/sheets/"..name,table.concat(rows,"\n")); ui.message("Sheets","Planilha CSV salva.")
end
local function diagram(ui)
 ui.clear(); ui.header("Crystal Diagram"); print("Descreva nos/etapas e ligacoes em texto.")
 print("Exemplo: Inicio -> Processo -> Fim. /salvar encerra.")
 local lines={}; while true do local s=read(); if s=="/salvar" then break end; lines[#lines+1]=s end
 local name=ask("Nome"); save("/CrystalOS/user/diagrams/"..(name~="" and name or "diagrama")..".txt",table.concat(lines,"\n"))
end
local function archive(ui)
 ui.clear(); ui.header("Crystal Archive"); print("Arquivo de pacote Crystal (nao ZIP interoperavel).")
 print("1 empacotar um arquivo  2 extrair pacote")
 local op=ask("Opcao")
 if op=="1" then
  local src=ask("Caminho do arquivo"); if not fs.exists(src) or fs.isDir(src) then ui.message("Archive","Arquivo nao encontrado."); return end
  local f=fs.open(src,"r"); local data=f.readAll(); f.close()
  local pack=textutils.serialize({format="CrystalArchive1",name=fs.getName(src),data=data})
  local dest=ask("Destino .car"); if dest=="" then dest="/CrystalOS/user/archive/"..fs.getName(src)..".car" end
  save(dest,pack); ui.message("Archive","Pacote salvo em "..dest)
 elseif op=="2" then
  local src=ask("Caminho .car"); if not fs.exists(src) then ui.message("Archive","Pacote nao encontrado."); return end
  local f=fs.open(src,"r"); local raw=f.readAll(); f.close(); local ok,p=pcall(textutils.unserialize,raw)
  if ok and type(p)=="table" and p.format=="CrystalArchive1" then local dest=ask("Destino"); if dest=="" then dest="/"..p.name end; save(dest,p.data); ui.message("Archive","Arquivo extraido para "..dest) else ui.message("Archive","Pacote invalido.") end
 end
end
local function network(ui)
 local modem=peripheral.find("modem")
 if not modem then ui.message("Crystal Link","Nenhum modem de redstone/wireless foi detectado. Conecte um modem para usar rednet."); return end
 local side=peripheral.getName(modem); rednet.open(side)
 ui.message("Crystal Link","Modem ativo em "..side.."\nRednet aberto. Para trocar dados, os outros computadores precisam executar um programa compativel.")
end
local function play(ui)
 ui.clear(); ui.header("Crystal Play"); math.randomseed(os.epoch and os.epoch("utc") or os.clock()*1000)
 local target=math.random(1,20); print("Adivinhe o numero de 1 a 20. Voce tem 5 tentativas.")
 for i=1,5 do local n=tonumber(ask("Tentativa "..i)); if n==target then ui.message("Crystal Play","Acertou!"); return elseif n and n<target then print("Mais alto.") else print("Mais baixo.") end end
 ui.message("Crystal Play","Fim de jogo. O numero era "..target..".")
end
local function clipboard(ui)
 local path="/CrystalOS/user/clipboard/history.txt"; local old=""
 if fs.exists(path) then local f=fs.open(path,"r"); old=f.readAll(); f.close() end
 ui.clear(); ui.header("Crystal Clipboard"); print("Historico salvo:\n"..old:sub(1,700))
 local s=ask("Novo texto (vazio volta)"); if s~="" then save(path,old..(old=="" and "" or "\n---\n")..s) end
end
local function vault(ui)
 local path="/CrystalOS/user/vault"; folder(path)
 while true do
  ui.clear(); ui.header("Crystal Vault")
  print("Arquivos locais (nao criptografados):")
  for _,name in ipairs(fs.list(path)) do print(name) end
  print(""); print("1 criar arquivo de texto  2 abrir arquivo  0 voltar")
  local op=ask("Opcao")
  if op=="0" or op=="" then return
  elseif op=="1" then
   local name=ask("Nome do arquivo"):gsub("[/\\\\]","")
   if name~="" then editor(ui,"Crystal Vault",path.."/"..name) end
  elseif op=="2" then
   local name=ask("Nome do arquivo"):gsub("[/\\\\]","")
   local target=path.."/"..name
   if fs.exists(target) and not fs.isDir(target) then
    local f=fs.open(target,"r"); local body=f.readAll(); f.close(); ui.message(name,body)
   else ui.message("Crystal Vault","Arquivo nao encontrado.") end
  end
 end
end

function A.launch(id,ui,catalog,settings)
 if id=="explorer" then return A.explorer(ui)
 elseif id=="notepad" then return A.notepad(ui)
 elseif id=="calculator" then return A.calculator(ui)
 elseif id=="crystal_terminal" then return A.crystalTerminal(ui,catalog)
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
