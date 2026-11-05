local U={}
local settings
local palette={colors.cyan,colors.blue,colors.purple,colors.magenta,colors.green,colors.orange,colors.red,colors.lightBlue}
local function logo(app)
  local path="/CrystalOS/user/logos/"..app.id..".txt"
  if fs.exists(path) then
    local f=fs.open(path,"r")
    if f then
      local symbol=f.readLine() or app.name:sub(1,2):upper()
      local n=tonumber(f.readLine() or "")
      f.close()
      return symbol:sub(1,2),palette[n] or colors.purple
    end
  end
  return app.name:gsub(" ",""):sub(1,2):upper(),palette[(#app.id%#palette)+1]
end
function U.init(s) settings=s; settings.load() end
function U.clear(bg)
  term.setBackgroundColor(bg or colors.black); term.setTextColor(colors.white)
  term.clear(); term.setCursorPos(1,1)
end
function U.header(title)
  term.setBackgroundColor(colors.gray); term.setTextColor(colors.white)
  term.setCursorPos(1,1); term.clearLine(); term.write("  "..title)
  term.setBackgroundColor(colors.black); term.setTextColor(colors.white)
  term.setCursorPos(1,3)
end
function U.footer(msg)
  local w,h=term.getSize()
  term.setCursorPos(1,h); term.setBackgroundColor(settings.accent or colors.purple)
  term.setTextColor(colors.black); term.clearLine()
  term.write(" "..(msg or "CrystalOS")); term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
end
function U.message(title,body)
  U.clear(); U.header(title); print(body or "")
  print(""); print("Pressione qualquer tecla para voltar.")
  U.footer("CrystalOS"); os.pullEvent("key")
end
local function drawTile(app,index,x,y,width,selected)
  local symbol,color=logo(app)
  local bg=selected and colors.lightGray or colors.gray
  for row=0,3 do
    term.setCursorPos(x,y+row); term.setBackgroundColor(bg)
    term.setTextColor(colors.white); term.write(string.rep(" ",width))
  end
  term.setCursorPos(x+1,y+1); term.setBackgroundColor(color)
  term.setTextColor(colors.white); term.write(" "..symbol.." ")
  term.setCursorPos(x+5,y+1); term.setBackgroundColor(bg)
  term.setTextColor(colors.white)
  local max=math.max(1,width-6)
  term.write(app.name:sub(1,max))
  term.setCursorPos(x+5,y+2); term.setTextColor(colors.lightGray)
  term.write((app.category or "Aplicativo"):sub(1,math.max(1,width-6)))
  term.setBackgroundColor(colors.black)
end
local function logoStudio(catalog)
  U.clear(); U.header("Crystal Logo Studio")
  print("Personalize o icone de qualquer aplicativo.")
  print("Digite o identificador do aplicativo:")
  for i=1,#catalog do print(catalog[i].id.." - "..catalog[i].name) end
  write("> "); local id=read()
  local app
  for _,a in ipairs(catalog) do if a.id==id then app=a end end
  if not app then U.message("Logo Studio","Aplicativo nao encontrado."); return end
  print("Simbolo curto (1 ou 2 caracteres):"); write("> ")
  local symbol=read():upper():sub(1,2)
  if symbol=="" then symbol=app.name:sub(1,2):upper() end
  print("Cor: 1 ciano, 2 azul, 3 roxo, 4 magenta, 5 verde, 6 laranja, 7 vermelho, 8 azul-claro")
  write("> "); local n=tonumber(read()) or 3
  if n<1 or n>8 then n=3 end
  fs.makeDir("/CrystalOS/user/logos")
  local f=fs.open("/CrystalOS/user/logos/"..app.id..".txt","w")
  if f then f.write(symbol.."\n"..n); f.close() end
  U.message("Logo salva","O icone de "..app.name.." foi personalizado.")
end
function U.desktop(catalog)
  local selected,page=1,1
  local w,h=term.getSize()
  local cols=w>=60 and 3 or 2
  local tileW=math.floor((w-4-(cols-1)*2)/cols)
  local rows=math.max(1,math.floor((h-8)/4))
  local pageSize=cols*rows
  local pages=math.max(1,math.ceil(#catalog/pageSize))
  while true do
    U.clear(colors.black)
    term.setCursorPos(2,2); term.setTextColor(colors.lightBlue); term.write("◆ CRYSTALOS")
    term.setCursorPos(2,3); term.setTextColor(colors.lightGray)
    term.write("Seu espaco de trabalho  |  ".."Pagina "..page.."/"..pages)
    local first=(page-1)*pageSize+1
    for i=first,math.min(#catalog,first+pageSize-1) do
      local localIndex=i-first
      local col=localIndex%cols
      local row=math.floor(localIndex/cols)
      local x=2+col*(tileW+2)
      local y=5+row*4
      drawTile(catalog[i],i,x,y,tileW,i==selected)
    end
    term.setCursorPos(2,h-2); term.setTextColor(colors.lightGray)
    term.write("Setas: navegar  Enter: abrir  L: logos  N/P: paginas")
    U.footer("Q desligar  |  R reiniciar  |  CrystalOS Desktop")
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
      local x,y=b,c
      if y>=5 and y<h-2 then
        local col=math.floor((x-2)/(tileW+2))
        local row=math.floor((y-5)/4)
        if col>=0 and col<cols and row>=0 and row<rows then
          local idx=(page-1)*pageSize+row*cols+col+1
          if idx<=#catalog then
            if idx==selected then return catalog[idx].id else selected=idx end
          end
        end
      end
    end
    if selected<=(page-1)*pageSize or selected>page*pageSize then
      page=math.floor((selected-1)/pageSize)+1
    end
  end
end
return U
