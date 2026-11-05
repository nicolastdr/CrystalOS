local W={}
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
function W.run(catalog,apps,ui,settings)
 local screen=term.current()
 local sw,sh=screen.getSize()
 local windows,focus,serial={},nil,0
 local selected=1
 local function dimensions()
  sw,sh=screen.getSize()
 end
 local function drawDesktop()
  screen.setBackgroundColor(colors.black); screen.setTextColor(colors.white); screen.clear()
  screen.setCursorPos(2,2); screen.setTextColor(colors.lightBlue); screen.write("◆ CRYSTALOS")
  screen.setCursorPos(2,3); screen.setTextColor(colors.lightGray); screen.write("Desktop")
  local cols=sw>=70 and 6 or (sw>=48 and 4 or 3)
  local cw=math.max(8,math.floor((sw-4)/cols)); local rows=math.max(1,math.floor((sh-9)/4))
  for i=1,math.min(#catalog,cols*rows) do
   local n=i-1; local x=2+(n%cols)*cw; local y=5+math.floor(n/cols)*4
   screen.setCursorPos(x,y); screen.setBackgroundColor(i==selected and colors.gray or colors.black); screen.write(string.rep(" ",cw-1))
   ui.logo(catalog[i],x+math.floor((cw-4)/2),y)
   local name=catalog[i].name; screen.setCursorPos(x+math.max(0,math.floor((cw-#name)/2)),y+2); screen.setTextColor(colors.white); screen.setBackgroundColor(i==selected and colors.gray or colors.black); screen.write(name:sub(1,cw-1))
  end
 end
 local function drawChrome(item)
  local x,y,w,h=item.x,item.y,item.w,item.h
  screen.setBackgroundColor(colors.gray); screen.setTextColor(colors.white)
  for yy=0,h-1 do screen.setCursorPos(x,y+yy); screen.write(string.rep(" ",w)) end
  screen.setCursorPos(x,y); screen.setBackgroundColor(item==windows[focus] and (settings.accent or colors.blue) or colors.gray)
  local title=(" "..item.title):sub(1,math.max(1,w-12))
  screen.write(title)
  screen.setCursorPos(x+w-11,y); screen.write(" [ _ ][ + ][X]")
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
  local w=math.max(18,math.floor(sw*0.72)); local h=math.max(8,math.floor((sh-1)*0.72))
  w=math.min(w,sw-2); h=math.min(h,sh-3)
  local x=clamp(2+((serial-1)*3)%math.max(1,sw-w-1),1,math.max(1,sw-w+1))
  local y=clamp(2+((serial-1)*2)%math.max(1,sh-h-2),1,math.max(1,sh-h))
  local win=window.create(screen,x+1,y+1,w-2,h-2,false)
  local item={id=id,title=app.name,x=x,y=y,w=w,h=h,win=win,minimized=false}
  item.co=coroutine.create(function() apps.launch(id,ui,catalog,settings) end)
  windows[#windows+1]=item; focus=#windows
  local old=term.redirect(win); local ok,err=coroutine.resume(item.co); term.redirect(old)
  if not ok then item.error=tostring(err); item.co=coroutine.create(function() ui.message("Erro: "..item.title,item.error) end) end
  if coroutine.status(item.co)=="dead" then remove(#windows) end
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
    if a==keys.left then selected=math.max(1,selected-1) elseif a==keys.right then selected=math.min(#catalog,selected+1)
    elseif a==keys.enter then startApp(catalog[selected].id)
    elseif a==keys.slash then search()
    elseif a==keys.l then ui.logoStudio(catalog)
    end
   else dispatch(windows[focus],event) end
  elseif ev=="char" or ev=="paste" then dispatch(windows[focus],event)
  elseif ev=="mouse_click" then
   if c<sh and #windows==0 then
    local cols=sw>=70 and 6 or (sw>=48 and 4 or 3)
    local cw=math.max(8,math.floor((sw-4)/cols))
    local col=math.floor((b-2)/cw); local row=math.floor((c-5)/4)
    local idx=row*cols+col+1
    if b>=2 and c>=5 and col>=0 and col<cols and row>=0 and idx<=#catalog then selected=idx; startApp(catalog[idx].id) end
   elseif c==sh then
    if b<=9 then
     if focus and windows[focus] then windows[focus].minimized=true end; focus=nil
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
      elseif rel>=item.w-8 then
       if item.maximized then item.x,item.y,item.w,item.h=item.oldX,item.oldY,item.oldW,item.oldH; item.maximized=false
       else item.oldX,item.oldY,item.oldW,item.oldH=item.x,item.y,item.w,item.h; item.x,item.y,item.w,item.h=1,1,sw,sh-1; item.maximized=true end
       item.win.reposition(item.x+1,item.y+1,item.w-2,item.h-2)
      elseif rel>=item.w-11 then item.minimized=true; focus=nil
      else item.drag={b-item.x,c-item.y} end
     else
      local routed={ev,a,b-item.x,c-item.y}; dispatch(item,routed)
     end
    end
   end
  elseif ev=="mouse_drag" then
   local item=windows[focus]
   if item and item.drag then
    item.x=clamp(b-item.drag[1],1,math.max(1,sw-item.w+1)); item.y=clamp(c-item.drag[2],1,math.max(1,sh-item.h))
    item.win.reposition(item.x+1,item.y+1,item.w-2,item.h-2)
   elseif item then dispatch(item,{ev,a,b-item.x,c-item.y}) end
  elseif ev=="mouse_up" then if windows[focus] then windows[focus].drag=nil end
  elseif ev=="timer" or ev=="redstone" or ev=="peripheral" or ev=="peripheral_detach" or ev=="modem_message" or ev=="rednet_message" or ev=="http_success" or ev=="http_failure" or ev=="task_complete" then
   for _,item in ipairs(windows) do dispatch(item,event) end
  elseif ev=="term_resize" then dimensions() end
 end
end
return W
