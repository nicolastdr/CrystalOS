local U={}
local settings
local palette={colors.cyan,colors.blue,colors.purple,colors.magenta,colors.green,colors.orange,colors.red,colors.lightBlue}
local paletteNames={"Ciano","Azul","Roxo","Magenta","Verde","Laranja","Vermelho","Azul-claro"}
local function logoData(app)
 local path="/CrystalOS/user/logos/"..app.id..".txt"
 local label=app.name:sub(1,8); local pixels={3,2,4,3}
 if fs.exists(path) then
  local f=fs.open(path,"r")
  if f then label=f.readLine() or label; for i=1,4 do pixels[i]=tonumber(f.readLine() or "") or pixels[i] end; f.close() end
 end
 return label,pixels
end
local flushScreen
function U.setFlush(fn) flushScreen=fn end
function U.init(s) settings=s; settings.load() end
function U.clear(bg) term.setBackgroundColor(bg or colors.black); term.setTextColor(colors.white); term.clear(); term.setCursorPos(1,1) end
function U.header(title)
 term.setBackgroundColor(colors.gray); term.setTextColor(colors.white); term.setCursorPos(1,1); term.clearLine(); term.write("  "..title)
 term.setBackgroundColor(colors.black); term.setTextColor(colors.white); term.setCursorPos(1,3)
end
function U.footer(msg)
 local w,h=term.getSize(); term.setCursorPos(1,h); term.setBackgroundColor(settings.accent or colors.blue); term.setTextColor(colors.white); term.clearLine(); term.write(" "..(msg or "CrystalOS")); term.setBackgroundColor(colors.black)
end
function U.message(title,body)
 U.clear(); U.header(title); print(body or ""); print(""); print("Pressione qualquer tecla para voltar."); U.footer("CrystalOS"); os.pullEvent("key")
end
function U.logo(app,x,y)
 local _,p=logoData(app)
 for row=1,2 do for col=1,2 do term.setCursorPos(x+(col-1)*2,y+row-1); term.setBackgroundColor(palette[p[(row-1)*2+col]] or colors.purple); term.write("  ") end end
 term.setBackgroundColor(colors.black)
end
function U.logoStudio(catalog)
 U.clear(); U.header("Crystal Logo Studio"); print("Digite o ID do aplicativo:")
 for i=1,#catalog do print(catalog[i].id.." - "..catalog[i].name) end
 write("> "); local id=read(); local app
 for _,a in ipairs(catalog) do if a.id==id then app=a end end
 if not app then U.message("Logo Studio","Aplicativo nao encontrado."); return end
 local old,p=logoData(app); print("Rotulo curto (ate 8 caracteres):"); write("> "); local label=read():sub(1,8); if label=="" then label=old end
 for i=1,8 do print(i.." - "..paletteNames[i]) end
 local chosen={}
 for i=1,4 do write("Pixel "..i.." ["..p[i].."]: "); local n=tonumber(read()) or p[i]; if n<1 or n>8 then n=3 end; chosen[i]=n end
 fs.makeDir("/CrystalOS/user/logos"); local f=fs.open("/CrystalOS/user/logos/"..app.id..".txt","w")
 if f then f.write(label.."\n"); for i=1,4 do f.write(tostring(chosen[i]).."\n") end; f.close() end
 U.message("Logo salva","Logo atualizada para "..app.name..".")
end
function U.search(catalog)
 local query,selected="",1
 while true do
  local w,h=term.getSize(); U.clear(colors.black)
  term.setCursorPos(2,2); term.setTextColor(colors.lightBlue); term.write("CRYSTAL SEARCH")
  term.setCursorPos(2,4); term.setBackgroundColor(colors.gray); term.setTextColor(colors.white)
  local prompt=" > "..query; term.write(prompt:sub(1,w-2)..string.rep(" ",math.max(0,w-2-#prompt))); term.setBackgroundColor(colors.black)
  local matches={}
  for _,app in ipairs(catalog) do
   if query=="" or app.name:lower():find(query:lower(),1,true) or app.id:lower():find(query:lower(),1,true) then matches[#matches+1]=app end
  end
  term.setCursorPos(2,6); term.setTextColor(colors.lightGray); term.write(#matches.." aplicativo(s) encontrado(s)")
  local visible=math.max(0,h-10)
  for i=1,math.min(#matches,visible) do
   local y=7+i; term.setCursorPos(2,y); term.setBackgroundColor(i==selected and colors.lightBlue or colors.gray); term.setTextColor(colors.white)
   term.write((" "..matches[i].name):sub(1,w-2)..string.rep(" ",math.max(0,w-2-#matches[i].name-1))); term.setBackgroundColor(colors.black)
  end
  term.setCursorPos(2,h-2); term.setTextColor(colors.lightGray); term.write("Digite para filtrar | Enter abrir | Esc voltar")
  U.footer("Crystal Search")
  if flushScreen then flushScreen() end
  local ev,a,b,c=os.pullEvent()
  if ev=="crystal_exit" then return "__exit_os"
  elseif ev=="char" then query=query..a; selected=1
  elseif ev=="paste" then query=query..a; selected=1
  elseif ev=="key" then
   if a==keys.backspace then query=query:sub(1,-2); selected=1
   elseif a==keys.enter then if matches[selected] then return matches[selected].id end
   elseif a==keys.escape then return nil
   elseif a==keys.down then selected=math.min(#matches,math.max(1,selected+1))
   elseif a==keys.up then selected=math.max(1,selected-1)
   end
  elseif ev=="mouse_click" and a==1 then
   local index=c-8
   if index>=1 and index<=math.min(#matches,visible) then return matches[index].id end
   if c==4 then term.setCursorPos(math.min(w,4+#query),4); local ch=os.pullEvent("char"); query=query..ch; selected=1 end
  end
 end
end
function U.desktop(catalog)
 local selected=1
 while true do
  local w,h=term.getSize(); local side=settings.labelPosition=="side"
  local cols=side and 2 or (w>=70 and 6 or (w>=48 and 4 or 3))
  local cellW=math.max(8,math.floor((w-4)/cols)); local cellH=side and 3 or 4
  local rows=math.max(1,math.floor((h-9)/cellH)); local pageSize=cols*rows
  local page=math.floor((selected-1)/pageSize)+1; local first=(page-1)*pageSize+1
  U.clear(colors.black); term.setCursorPos(2,2); term.setTextColor(colors.lightBlue); term.write("◆ CRYSTALOS")
  term.setCursorPos(2,3); term.setTextColor(colors.lightGray); term.write("Desktop  |  Aplicativos")
  for i=first,math.min(#catalog,first+pageSize-1) do
   local n=i-first; local x=2+(n%cols)*cellW; local y=5+math.floor(n/cols)*cellH
   if side then
    term.setCursorPos(x,y); term.setBackgroundColor(i==selected and colors.lightBlue or colors.gray); term.write(string.rep(" ",cellW-1))
    U.logo(catalog[i],x+1,y); term.setCursorPos(x+6,y); term.setTextColor(colors.white); term.setBackgroundColor(i==selected and colors.lightBlue or colors.gray); term.write(catalog[i].name:sub(1,math.max(1,cellW-7)))
   else
    local bg=i==selected and colors.lightBlue or colors.gray
    term.setCursorPos(x,y); term.setBackgroundColor(bg); term.write(string.rep(" ",math.max(1,cellW-1)))
    U.logo(catalog[i],x+math.floor((cellW-4)/2),y)
    local label=catalog[i].name; local lx=x+math.max(0,math.floor((cellW-#label)/2))
    term.setCursorPos(x,y+2); term.setBackgroundColor(bg); term.write(string.rep(" ",math.max(1,cellW-1)))
    term.setCursorPos(lx,y+2); term.setTextColor(colors.white); term.write(label:sub(1,cellW-1))
   end
   term.setBackgroundColor(colors.black)
  end
  term.setCursorPos(2,h-2); term.setBackgroundColor(settings.accent or colors.blue); term.setTextColor(colors.white); term.write(" [Iniciar] [Pesquisar] ")
  term.setBackgroundColor(colors.black); term.setTextColor(colors.lightGray); term.write(" Setas navegar | Enter abrir | / pesquisar | L logos")
  U.footer("CrystalOS")
  local ev,a,b,c=os.pullEvent()
  if ev=="key" then
   if a==keys.l then U.logoStudio(catalog)
   elseif a==keys.slash then local id=U.search(catalog); if id then return id end
   elseif a==keys.enter and catalog[selected] then return catalog[selected].id
   elseif a==keys.right then selected=math.min(#catalog,selected+1)
   elseif a==keys.left then selected=math.max(1,selected-1)
   elseif a==keys.down then selected=math.min(#catalog,selected+cols)
   elseif a==keys.up then selected=math.max(1,selected-cols)
   end
  elseif ev=="mouse_click" and a==1 then
   if c==h-2 and b>=2 and b<=22 then local id=U.search(catalog); if id then return id end
   else
    local col=math.floor((b-2)/cellW); local row=math.floor((c-5)/cellH)
    local idx=first+row*cols+col
    if col>=0 and col<cols and row>=0 and row<rows and idx<=#catalog then if idx==selected then return catalog[idx].id else selected=idx end end
   end
  end
 end
end
return U
