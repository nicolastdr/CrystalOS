local U={}
local settings
local palette={colors.cyan,colors.blue,colors.purple,colors.magenta,colors.green,colors.orange,colors.red,colors.lightBlue}
local paletteNames={"Ciano","Azul","Roxo","Magenta","Verde","Laranja","Vermelho","Azul-claro"}
local function logoData(app)
 local path="/CrystalOS/user/logos/"..app.id..".txt"
 local label=app.name:sub(1,8)
 local pixels={3,2,4,3}
 if fs.exists(path) then
  local f=fs.open(path,"r")
  if f then
   label=f.readLine() or label
   for i=1,4 do pixels[i]=tonumber(f.readLine() or "") or pixels[i] end
   f.close()
  end
 end
 return label,pixels
end
function U.init(s) settings=s; settings.load() end
function U.clear(bg)
 term.setBackgroundColor(bg or colors.black); term.setTextColor(colors.white)
 term.clear(); term.setCursorPos(1,1)
end
function U.header(title)
 term.setBackgroundColor(colors.gray); term.setTextColor(colors.white)
 term.setCursorPos(1,1); term.clearLine(); term.write("  "..title)
 term.setBackgroundColor(colors.black); term.setTextColor(colors.white); term.setCursorPos(1,3)
end
function U.footer(msg)
 local w,h=term.getSize(); term.setCursorPos(1,h)
 term.setBackgroundColor(settings.accent or colors.purple); term.setTextColor(colors.black)
 term.clearLine(); term.write(" "..(msg or "CrystalOS"))
 term.setBackgroundColor(colors.black); term.setTextColor(colors.white)
end
function U.message(title,body)
 U.clear(); U.header(title); print(body or ""); print(""); print("Pressione qualquer tecla para voltar.")
 U.footer("CrystalOS"); os.pullEvent("key")
end
local function drawLogo(app,x,y)
 local _,p=logoData(app)
 for row=1,2 do
  for col=1,2 do
   term.setCursorPos(x+(col-1)*2,y+row-1)
   term.setBackgroundColor(palette[p[(row-1)*2+col]] or colors.purple)
   term.write("  ")
  end
 end
 term.setBackgroundColor(colors.black)
end
local function logoStudio(catalog)
 U.clear(); U.header("Crystal Logo Studio")
 print("Digite o ID do aplicativo para editar:")
 for i=1,#catalog do print(catalog[i].id.." - "..catalog[i].name) end
 write("> "); local id=read(); local app
 for _,a in ipairs(catalog) do if a.id==id then app=a end end
 if not app then U.message("Logo Studio","Aplicativo nao encontrado."); return end
 local old,p=logoData(app)
 print("Texto curto associado a logo (ate 8 caracteres):")
 write("> "); local label=read():sub(1,8); if label=="" then label=old end
 print("Escolha a cor de cada pixel 2x2:")
 for i=1,8 do print(i.." - "..paletteNames[i]) end
 local chosen={}
 for i=1,4 do
  write("Pixel "..i.." ["..p[i].."]: ")
  local n=tonumber(read()) or p[i]; if n<1 or n>8 then n=3 end; chosen[i]=n
 end
 fs.makeDir("/CrystalOS/user/logos")
 local f=fs.open("/CrystalOS/user/logos/"..app.id..".txt","w")
 if f then f.write(label.."\n"); for i=1,4 do f.write(tostring(chosen[i]).."\n") end; f.close() end
 U.message("Logo salva","Logo atualizada para "..app.name..".")
end
local function drawCompact(app,x,y,width,selected,side)
 local bg=selected and colors.lightBlue or colors.gray
 if side then
  term.setCursorPos(x,y); term.setBackgroundColor(bg); term.write(string.rep(" ",width))
  drawLogo(app,x+1,y)
  term.setCursorPos(x+6,y); term.setBackgroundColor(bg); term.setTextColor(colors.white)
  term.write(app.name:sub(1,math.max(1,width-7)))
  term.setBackgroundColor(colors.black)
 else
  term.setCursorPos(x,y+3); term.setBackgroundColor(bg); term.setTextColor(colors.white)
  local label=app.name
  local start=math.max(1,math.floor((width-#label)/2))
  term.write(string.rep(" ",width))
  term.setCursorPos(x+start,y+3); term.write(label:sub(1,width))
  term.setBackgroundColor(colors.black)
  drawLogo(app,x+math.floor((width-4)/2),y)
 end
end
local function searchApps(catalog)
 local query=""
 local selected=1
 local w,h=term.getSize()
 while true do
  U.clear(colors.black)
  term.setCursorPos(2,2); term.setTextColor(colors.lightBlue); term.write("CRYSTAL SEARCH")
  term.setCursorPos(2,4); term.setBackgroundColor(colors.gray); term.setTextColor(colors.white)
  term.write(" > "..query..string.rep(" ",math.max(0,w-5-#query)))
  term.setBackgroundColor(colors.black)
  local matches={}
  for _,app in ipairs(catalog) do
   if query=="" or app.name:lower():find(query:lower(),1,true) or app.id:lower():find(query:lower(),1,true) then matches[#matches+1]=app end
  end
  term.setCursorPos(2,6); term.setTextColor(colors.lightGray); term.write(#matches.." aplicativo(s) encontrado(s)")
  for i=1,math.min(#matches,h-10) do
   local y=7+i
   term.setCursorPos(2,y); term.setBackgroundColor(i==selected and colors.lightBlue or colors.gray)
   term.setTextColor(colors.white); term.write(" "..matches[i].name:sub(1,math.max(1,w-5)))
   term.setBackgroundColor(colors.black)
  end
  term.setCursorPos(2,h-2); term.setTextColor(colors.lightGray); term.write("Digite para filtrar | Enter abrir | Esc voltar | Setas selecionar")
  U.footer("CrystalOS Search")
  local ev,a=os.pullEvent()
  if ev=="char" then query=query..a; selected=1
  elseif ev=="key" then
   if a==keys.backspace then query=query:sub(1,-2); selected=1
   elseif a==keys.enter then if matches[selected] then return matches[selected].id end
   elseif a==keys.escape then return nil
   elseif a==keys.down then selected=math.min(#matches,selected+1)
   elseif a==keys.up then selected=math.max(1,selected-1)
   end
  elseif ev=="mouse_click" and a==1 then
   local index=c-7
   if index>=1 and index<=math.min(#matches,h-10) then return matches[index].id end
  end
 end
end
function U.runWindow(title,callback)
 if not window or not window.create then return callback() end
 local parent=term.current()
 local w,h=parent.getSize()
 if w<18 or h<8 then return callback() end
 local ww=math.max(16,math.min(w-2,math.floor(w*0.88)))
 local wh=math.max(7,math.min(h-2,math.floor(h*0.86)))
 local x=math.floor((w-ww)/2)+1
 local y=math.floor((h-wh)/2)+1
 parent.setBackgroundColor(colors.black); parent.setTextColor(colors.white)
 for row=0,wh-1 do
  parent.setCursorPos(x,y+row); parent.write(string.rep(" ",ww))
 end
 parent.setCursorPos(x,y); parent.setBackgroundColor(settings.accent or colors.blue)
 parent.setTextColor(colors.white); parent.write((" "..title):sub(1,ww))
 parent.setBackgroundColor(colors.black)
 local child=window.create(parent,x+1,y+1,ww-2,wh-2,true)
 local old=term.redirect(child)
 local ok,err=pcall(callback)
 term.redirect(old)
 if not ok then
  U.clear(); U.header("Erro no aplicativo"); print(tostring(err)); print(""); print("Pressione uma tecla."); os.pullEvent("key")
 end
 parent.setBackgroundColor(colors.black); parent.setTextColor(colors.white)
 parent.setCursorPos(1,1); parent.clear()
end
function U.desktop(catalog)
 local selected,page=1,1
 while true do
  local w,h=term.getSize()
  local side=settings.labelPosition=="side"
  local cols=side and 2 or (w>=70 and 5 or (w>=42 and 4 or 3))
  local tileW=side and math.floor((w-6)/2) or math.floor((w-4-(cols-1)*1)/cols)
  local tileH=side and 3 or 4
  local rows=math.max(1,math.floor((h-11)/tileH))
  local pageSize=cols*rows
  local pages=math.max(1,math.ceil(#catalog/pageSize))
  page=math.min(page,pages); selected=math.max(1,math.min(#catalog,selected))
  U.clear(colors.black)
  term.setCursorPos(2,2); term.setTextColor(colors.lightBlue); term.write("◆ CRYSTALOS")
  term.setCursorPos(2,3); term.setTextColor(colors.lightGray); term.write("Iniciar  |  Aplicativos  |  "..page.."/"..pages)
  local first=(page-1)*pageSize+1
  for i=first,math.min(#catalog,first+pageSize-1) do
   local n=i-first
   local x=2+(n%cols)*(tileW+1)
   local y=5+math.floor(n/cols)*tileH
   drawCompact(catalog[i],x,y,tileW,i==selected,side)
  end
  term.setCursorPos(2,h-3); term.setTextColor(colors.white)
  term.setBackgroundColor(settings.accent or colors.blue); term.write(" [PESQUISAR] ")
  term.setBackgroundColor(colors.black); term.setTextColor(colors.lightGray)
  term.write("  Setas: navegar  Enter: abrir  L: logos  N/P: paginas")
  U.footer("Q desligar  |  R reiniciar  |  CrystalOS")
  local ev,a,b,c=os.pullEvent()
  if ev=="key" then
   if a==keys.q then return "shutdown"
   elseif a==keys.r then return "reboot"
   elseif a==keys.l then logoStudio(catalog)
   elseif a==keys.n then page=math.min(pages,page+1); selected=(page-1)*pageSize+1
   elseif a==keys.p then page=math.max(1,page-1); selected=(page-1)*pageSize+1
   elseif a==keys.left then selected=math.max((page-1)*pageSize+1,selected-1)
   elseif a==keys.right then selected=math.min(math.min(#catalog,page*pageSize),selected+1)
   elseif a==keys.up then selected=math.max((page-1)*pageSize+1,selected-cols)
   elseif a==keys.down then selected=math.min(math.min(#catalog,page*pageSize),selected+cols)
   elseif a==keys.enter and catalog[selected] then return catalog[selected].id
   elseif a==keys.slash then local id=searchApps(catalog); if id then return id end
   end
  elseif ev=="mouse_click" and a==1 then
   if c==h-3 and b>=2 and b<=14 then local id=searchApps(catalog); if id then return id end
   else
    local col=math.floor((b-2)/(tileW+1)); local row=math.floor((c-5)/tileH)
    if col>=0 and col<cols and row>=0 and row<rows then
     local idx=(page-1)*pageSize+row*cols+col+1
     if idx<=#catalog then if idx==selected then return catalog[idx].id else selected=idx end end
    end
   end
  end
 end
end
return U
