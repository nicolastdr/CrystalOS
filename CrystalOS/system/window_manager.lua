local W={}
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
function W.run(catalog,apps,ui,settings)
 local screen=term.current()
 local sw,sh=screen.getSize()
 local windows,focus,serial={},nil,0
 local selected=1
 local shortcuts={"explorer","terminal","settings","notepad","calculator","hub"}
 local shortcutPos={}
 local desktopPath="/CrystalOS/data/desktop"
 local function loadDesktop()
  if fs.exists(desktopPath) then
   local h=fs.open(desktopPath,"r")
   if h then
    local raw=h.readAll(); h.close()
    local ok,data=pcall(textutils.unserialize,raw)
    if ok and type(data)=="table" then
     if type(data.shortcuts)=="table" then shortcuts=data.shortcuts end
     if type(data.positions)=="table" then shortcutPos=data.positions end
    end
   end
  end
 end
 local function saveDesktop()
  fs.makeDir("/CrystalOS/data")
  local h=fs.open(desktopPath,"w")
  if h then h.write(textutils.serialize({shortcuts=shortcuts,positions=shortcutPos})); h.close() end
 end
 loadDesktop()
 local desktopDrag=nil
 local lastDesktopClickId,lastDesktopClickTime=nil,0
 local function desktopNow() return os.epoch and (os.epoch("utc")/1000) or os.clock() end
 local function appById(id) for _,a in ipairs(catalog) do if a.id==id then return a end end end
 local function dimensions()
  sw,sh=screen.getSize()
 end
 local function drawDesktop()
  screen.setBackgroundColor(colors.black); screen.setTextColor(colors.white); screen.clear()
  local wallpaper="/CrystalOS/system/wallpaper.nfp"
  if paintutils and fs.exists(wallpaper) then
   local ok,img=pcall(paintutils.loadImage,wallpaper)
   if ok and img then pcall(paintutils.drawImage,img,1,1) end
  else
   for y=1,sh-1 do
    screen.setCursorPos(1,y); screen.setBackgroundColor(y<math.floor(sh/2) and colors.blue or colors.black)
    screen.write(string.rep(" ",sw))
   end
  end
  screen.setBackgroundColor(colors.black); screen.setTextColor(colors.white)
  screen.setCursorPos(2,1); screen.write("◆ CRYSTALOS v0.9.5")
  for i,id in ipairs(shortcuts) do
   local app=appById(id)
   if app then
    local p=shortcutPos[id] or {x=2+((i-1)%5)*10,y=3+math.floor((i-1)/5)*5}
    local x=clamp(tonumber(p.x) or 2,1,math.max(1,sw-9))
    local y=clamp(tonumber(p.y) or 3,2,math.max(2,sh-4))
    local initials=(app.name:gsub("[^%w ]",""):gsub("(%S)%S+","%1")):upper():sub(1,2)
    if initials=="" then initials=app.id:sub(1,2):upper() end
    screen.setCursorPos(x,y); screen.setBackgroundColor(id==shortcuts[selected] and colors.blue or colors.gray)
    screen.setTextColor(colors.white); screen.write(" "..initials.." ")
    screen.setCursorPos(x,y+1); screen.setBackgroundColor(colors.black); screen.setTextColor(colors.white)
    screen.write(app.name:sub(1,8))
   end
  end
 end
 local function drawChrome(item)
  local x,y,w,h=item.x,item.y,item.w,item.h
  screen.setBackgroundColor(colors.gray); screen.setTextColor(colors.white)
  for yy=0,h-1 do screen.setCursorPos(x,y+yy); screen.write(string.rep(" ",w)) end
  screen.setCursorPos(x,y); screen.setBackgroundColor(item==windows[focus] and (settings.accent or colors.blue) or colors.gray)
  local title=(" "..item.title):sub(1,math.max(1,w-8))
  screen.write(title)
  screen.setCursorPos(x+w-6,y); screen.write("[_][X]")
  screen.setBackgroundColor(colors.black)
 end
 local function render()
  dimensions(); drawDesktop()
  for i,item in ipairs(windows) do
   if not item.minimized then
    item.win.setVisible(false); drawChrome(item); item.win.setVisible(true); item.win.redraw()
   end
  end
  screen.setBackgroundColor(settings.accent or colors.blue); screen.setTextColor(colors.white)
  screen.setCursorPos(1,sh); screen.clearLine()
  screen.write(" Iniciar  Pesquisar ")
  local x=21
  for i,item in ipairs(windows) do
   local label=item.title:sub(1,math.max(3,math.floor((sw-24)/math.max(1,#windows))))
   screen.setCursorPos(x,sh); screen.write("["..label.."]")
   x=x+#label+3
  end
  screen.setBackgroundColor(colors.black); screen.setTextColor(colors.white)
 end
 local function remove(index)
  local item=table.remove(windows,index)
  if item then item.win.setVisible(false); if item.co and coroutine.status(item.co)~="dead" then item.closed=true end end
  focus=#windows>0 and #windows or nil
 end
 local function bring(index)
  if not index or not windows[index] then return end
  local item=table.remove(windows,index); windows[#windows+1]=item; focus=#windows
  item.minimized=false
 end
 local function startApp(id)
  local app
  for _,a in ipairs(catalog) do if a.id==id then app=a; break end end
  if not app then return end
  for i,item in ipairs(windows) do if item.id==id then bring(i); return end end
  serial=serial+1
  local w,h=sw,sh-1
  local x,y=1,1
  local win=window.create(screen,2,2,math.max(1,w-2),math.max(1,h-2),false)
  local item={id=id,title=app.name,x=x,y=y,w=w,h=h,win=win,minimized=false}
  item.co=coroutine.create(function() apps.launch(id,ui,catalog,settings) end)
  windows[#windows+1]=item; focus=#windows
  local old=term.redirect(win); local ok,err=coroutine.resume(item.co); term.redirect(old)
  if not ok then item.error=tostring(err); item.co=coroutine.create(function() ui.message("Erro: "..item.title,item.error) end) end
  if coroutine.status(item.co)=="dead" then remove(#windows) end
 end
 local function startMenu()
  local query=""
  local selected=1
  while true do
   dimensions()
   local matches={}
   for _,app in ipairs(catalog) do
    if query=="" or app.name:lower():find(query:lower(),1,true) or app.id:lower():find(query:lower(),1,true) then matches[#matches+1]=app end
   end
   local mw=math.min(sw-4,34)
   table.insert(matches,1,{id="native_terminal",name="Terminal nativo do ComputerCraft"})
   local mh=math.min(sh-2,math.max(10,#matches+7))
   local mx=2
   local my=math.max(1,sh-mh)
   screen.setBackgroundColor(colors.gray); screen.setTextColor(colors.white)
   for yy=my,my+mh-1 do screen.setCursorPos(mx,yy); screen.write(string.rep(" ",mw)) end
   screen.setCursorPos(mx+1,my+1); screen.setTextColor(colors.cyan); screen.write("CRYSTAL  |  INICIAR")
   screen.setCursorPos(mx+1,my+2); screen.setTextColor(colors.white); screen.write(("Pesquisar: "..query):sub(1,mw-2))
   local visible=math.max(1,mh-6)
   for i=1,math.min(#matches,visible) do
    local yy=my+3+i
    screen.setCursorPos(mx+1,yy)
    screen.setBackgroundColor(i==selected and colors.blue or colors.gray)
    local label=" "..matches[i].name
    screen.write(label:sub(1,mw-2)..string.rep(" ",math.max(0,mw-2-#label)))
   end
   screen.setBackgroundColor(colors.gray); screen.setTextColor(colors.lightGray)
   screen.setCursorPos(mx+1,my+mh-1); screen.write("Enter abrir  Esc fechar")
   local ev,a,b,c=os.pullEvent()
   if ev=="char" then query=query..a; selected=1
   elseif ev=="paste" then query=query..a; selected=1
   elseif ev=="key" then
    if a==keys.escape then return
    elseif a==keys.backspace then query=query:sub(1,-2); selected=1
    elseif a==keys.down then selected=math.min(#matches,math.max(1,selected+1))
    elseif a==keys.up then selected=math.max(1,selected-1)
    elseif a==keys.enter and matches[selected] then return matches[selected].id end
   elseif ev=="mouse_click" then
    if b<mx or b>=mx+mw or c<my or c>=my+mh then return end
    local index=c-(my+3)
    if index>=1 and index<=math.min(#matches,visible) and matches[index] then return matches[index].id end
   end
  end
 end
 local function search()
  local old=term.redirect(screen); local id=ui.search(catalog); term.redirect(old)
  if id then startApp(id) end
 end
 local function dispatch(item,event)
  if not item or item.minimized or not item.co or coroutine.status(item.co)=="dead" then return end
  local old=term.redirect(item.win)
  local ok,err=coroutine.resume(item.co,unpack(event))
  term.redirect(old)
  if not ok then item.error=tostring(err); item.co=coroutine.create(function() ui.message("Erro: "..item.title,item.error) end); local prev=term.redirect(item.win); coroutine.resume(item.co); term.redirect(prev)
  elseif coroutine.status(item.co)=="dead" then
   for i,v in ipairs(windows) do if v==item then remove(i); break end end
  end
 end
 while true do
  render()
  local event={os.pullEventRaw()}
  local ev,a,b,c=unpack(event)
  if ev=="key" then
   if a==keys.q and #windows==0 then return "shutdown"
   elseif a==keys.r and #windows==0 then return "reboot"
   elseif a==keys.escape and #windows>0 then if windows[focus] then windows[focus].minimized=true end; focus=nil
   elseif a==keys.tab and #windows>0 then focus=(focus or 0)%#windows+1; windows[focus].minimized=false
   elseif #windows==0 then
    if a==keys.enter and shortcuts[selected] then startApp(shortcuts[selected])
    elseif a==keys.left or a==keys.up then selected=math.max(1,selected-1)
    elseif a==keys.right or a==keys.down then selected=math.min(#shortcuts,selected+1)
    elseif a==keys.slash then search()
    elseif a==keys.a then
     local old=term.redirect(screen); local id=ui.search(catalog); term.redirect(old)
     if id then
      local exists=false; for _,v in ipairs(shortcuts) do if v==id then exists=true end end
      if not exists then shortcuts[#shortcuts+1]=id; selected=#shortcuts; saveDesktop() end
     end
    elseif a==keys.delete or a==keys.backspace then
     if shortcuts[selected] then table.remove(shortcuts,selected); selected=math.max(1,math.min(selected,#shortcuts)); saveDesktop() end
    elseif a==keys.l then ui.logoStudio(catalog)
    end
   else dispatch(windows[focus],event) end
  elseif ev=="char" or ev=="paste" then dispatch(windows[focus],event)
  elseif ev=="mouse_click" then
   if c<sh and #windows==0 then
    local hit
    for i,id in ipairs(shortcuts) do
     local p=shortcutPos[id] or {x=2+((i-1)%5)*10,y=3+math.floor((i-1)/5)*5}
     if b>=p.x and b<=p.x+8 and c>=p.y and c<=p.y+1 then hit=i; break end
    end
    if hit then
     selected=hit
     local id=shortcuts[hit]
     if lastDesktopClickId==id and desktopNow()-lastDesktopClickTime<0.45 then startApp(id) end
     lastDesktopClickId,lastDesktopClickTime=id,desktopNow()
     local p=shortcutPos[id] or {x=2+((hit-1)%5)*10,y=3+math.floor((hit-1)/5)*5}
     desktopDrag={id=id,dx=b-p.x,dy=c-p.y}
    else desktopDrag=nil end
   elseif c==sh then
    if b<=9 then
     local id=startMenu(); if id=="native_terminal" then return "native_terminal" elseif id then startApp(id) end
    elseif b<=20 then search()
    else
     local x=21
     for i,item in ipairs(windows) do local len=#item.title+2; if b>=x and b<x+len then if focus==i and not item.minimized then item.minimized=true; focus=nil else bring(i) end; break end; x=x+len+1 end
    end
   else
    local hit
    for i=#windows,1,-1 do local item=windows[i]
     if not item.minimized and b>=item.x and b<item.x+item.w and c>=item.y and c<item.y+item.h then hit=i; break end
    end
    if hit then
     bring(hit); local item=windows[focus]
     if c==item.y then
      local rel=b-item.x
      if rel>=item.w-3 then remove(focus)
      elseif rel>=item.w-6 then
       remove(focus)
      elseif rel>=item.w-9 then item.minimized=true; focus=nil
      else -- Janelas permanecem maximizadas; arrastar esta barra esta desativado.
      end
     else
      local routed={ev,a,b-item.x,c-item.y}; dispatch(item,routed)
     end
    end

   end
  elseif ev=="mouse_drag" then
   if #windows==0 and desktopDrag then
    local id=desktopDrag.id
    shortcutPos[id]={x=clamp(b-desktopDrag.dx,1,math.max(1,sw-9)),y=clamp(c-desktopDrag.dy,2,math.max(2,sh-4))}
    saveDesktop()
   end
   local item=windows[focus]
   if item then dispatch(item,{ev,a,b-item.x,c-item.y}) end
  elseif ev=="mouse_up" then desktopDrag=nil; if windows[focus] then windows[focus].drag=nil end
  elseif ev=="timer" or ev=="redstone" or ev=="peripheral" or ev=="peripheral_detach" or ev=="modem_message" or ev=="rednet_message" or ev=="http_success" or ev=="http_failure" or ev=="task_complete" then
   for _,item in ipairs(windows) do dispatch(item,event) end
  elseif ev=="term_resize" then dimensions() end
 end
end
return W
