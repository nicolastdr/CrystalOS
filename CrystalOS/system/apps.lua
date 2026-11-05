local A={}
local function pause() print(""); print("Pressione qualquer tecla."); os.pullEvent("key") end
function A.explorer(ui)
 local path="/"
 while true do
  ui.clear(); ui.header("Explorador de arquivos"); print("Caminho: "..path); print("")
  local items=fs.list(path); for i=1,math.min(#items,12) do local p=fs.combine(path,items[i]); print((fs.isDir(p) and "[DIR] " or "      ")..items[i]) end
  print(""); print("Digite um caminho; .. sobe; vazio volta."); write("> "); local s=read()
  if s=="" then return elseif s==".." then path=fs.getDir(path); if path=="" then path="/" end
  else local p=fs.combine(path,s); if fs.exists(p) and fs.isDir(p) then path=p elseif fs.exists(p) then ui.clear(); ui.header("Arquivo"); local f=fs.open(p,"r"); print(f.readAll():sub(1,700)); f.close(); pause() else print("Nao encontrado."); sleep(1) end end
 end
end
function A.notepad(ui)
 ui.clear(); ui.header("Bloco de notas"); print("Digite o texto. Uma linha /salvar encerra."); local lines={}
 while true do local s=read(); if s=="/salvar" then break end; lines[#lines+1]=s end
 fs.makeDir("/CrystalOS/user/documents"); write("Nome do arquivo: "); local name=read()
 if name~="" and not name:find("[/\\]") then local f=fs.open("/CrystalOS/user/documents/"..name,"w"); if f then f.write(table.concat(lines,"\n")); f.close() end end
end
function A.calculator(ui)
 ui.clear(); ui.header("Calculadora"); print("Expressao (ex.: 12*5+3)"); write("> "); local expr=read()
 if expr:match("^[%d%+%-%*/%%%^%(%)%.%s]+$") then local fn=load("return "..expr); if fn then local ok,result=pcall(fn); print(ok and tostring(result) or "Expressao invalida.") else print("Expressao invalida.") end else print("Caracteres nao permitidos.") end; pause()
end
function A.terminal(ui)
 ui.clear(); ui.header("Terminal"); print("Digite comandos CraftOS. 'exit' retorna.")
 while true do write("> "); local cmd=read(); if cmd=="exit" then return end; if cmd~="" then shell.run(cmd) end end
end
local function generic(ui,app) ui.message(app.name,app.description.."\n\nEstado: "..app.state.."\n\nModulo registrado. Recursos completos ainda estao em desenvolvimento.") end
function A.launch(id,ui,catalog,settings)
 if id=="explorer" then return A.explorer(ui) elseif id=="notepad" then return A.notepad(ui) elseif id=="calculator" then return A.calculator(ui) elseif id=="terminal" then return A.terminal(ui) elseif id=="settings" then return settings.screen(ui) end
 for _,app in ipairs(catalog) do if app.id==id then return generic(ui,app) end end
 ui.message("CrystalOS","Aplicativo nao encontrado.")
end
return A