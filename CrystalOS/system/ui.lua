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
local function drawTile(app,x,y,width,selected)
 local label,p=logoData(app); local bg=selected and colors.lightGray or colors.gray
 for row=0,3 do term.setCursorPos(x,y+row); term.setBackgroundColor(bg); term.setTextColor(colors.white); term.write(string.rep(" ",width)) end
 for row=1,2 do
  for col=1,2 do
   term.setCursorPos(x+1+(col-1)*2,y+row)
   term.setBackgroundColor(palette[p[(row-1)*2+col]] or colors.purple)
   term.write("  ")
  end
 end
 term.setBackgroundColor(bg); term.setTextColor(colors.white)
 term.setCursorPos(x+7,y+1); term.write(app.name:sub(1,math.max(1,width-8)))
 term.setCursorPos(x+7,y+2); term.setTextColor(colors.lightGray)
 term.write((app.category or "App"):sub(1,math.max(1,width-8)))
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
 print("Texto curto exibido junto da logo (ate 8 caracteres):")
 write("> "); local label=read():sub(1,8); if label=="" then label=old end
 print("Escolha a cor de cada pixel 2x2:")
 for i=1,8 do print(i.." - "..paletteNames[i]) end
 local chosen={}
 for i=1,4 do
  write("Pixel "..i.." (linha "..(math.floor((i-1)/2)+1)..", coluna "..(((i-1)%2)+1)..") ["..p[i].."]: ")
  local n=tonumber(read()) or p[i]; if n<1 or n>8 then n=3 end; chosen[i]=n
 end
 fs.makeDir("/CrystalOS/user/logos")
 local f=fs.open("/CrystalOS/user/logos/"..app.id..".txt","w")
 if f then f.write(label.."\n"); for i=1,4 do f.write(tostring(chosen[i]).."\n") end; f.close() end
 U.message("Logo salva","Logo 2x2 multicolorida atualizada para "..app.name..".")
end
function U.desktop(catalog)
 local selected,page=1,1; local w,h=term.getSize()
 local cols=w>=65 and 3 or 2; local tileW=math.floor((w-4-(cols-1)*2)/cols)
 local rows=math.max(1,math.floor((h-8)/4)); local pageSize=cols*rows
 local pages=math.max(1,math.ceil(#catalog/pageSize))
 while true do
  U.clear(colors.black); term.setCursorPos(2,2); term.setTextColor(colors.lightBlue); term.write("◆ CRYSTALOS")
  term.setCursorPos(2,3); term.setTextColor(colors.lightGray); term.write("Desktop  |  Pagina "..page.."/"..pages)
  local first=(page-1)*pageSize+1
  for i=first,math.min(#catalog,first+pageSize-1) do
   local n=i-first; drawTile(catalog[i],2+(n%cols)*(tileW+2),5+math.floor(n/cols)*4,tileW,i==selected)
  end
  term.setCursorPos(2,h-2); term.setTextColor(colors.lightGray); term.write("Setas: navegar  Enter: abrir  L: editar logos")
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
   elseif a==keys.enter and catalog[selected] then return catalog[selected].id end
  elseif ev=="mouse_click" and a==1 then
   local col=math.floor((b-2)/(tileW+2)); local row=math.floor((c-5)/4)
   if col>=0 and col<cols and row>=0 and row<rows then
    local idx=(page-1)*pageSize+row*cols+col+1
    if idx<=#catalog then if idx==selected then return catalog[idx].id else selected=idx end end
   end
  end
  if selected>(page*pageSize) then page=math.min(pages,page+1) end
 end
end
return U
