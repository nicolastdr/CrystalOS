local U={}
local settings
function U.init(s) settings=s; settings.load() end
function U.clear(bg)
  term.setBackgroundColor(bg or colors.black); term.setTextColor(colors.white); term.clear(); term.setCursorPos(1,1)
end
function U.header(title)
  term.setBackgroundColor(settings.accent); term.setTextColor(colors.black)
  term.setCursorPos(1,1); term.clearLine(); term.write("  "..title)
  term.setBackgroundColor(colors.black); term.setTextColor(colors.white); term.setCursorPos(1,3)
end
function U.footer(msg)
  local w,h=term.getSize()
  term.setCursorPos(1,h); term.setBackgroundColor(settings.accent); term.setTextColor(colors.black); term.clearLine()
  term.write(" "..(msg or "CrystalOS")); term.setBackgroundColor(colors.black); term.setTextColor(colors.white)
end
function U.desktop()
  U.clear(settings.wallpaper)
  term.setTextColor(colors.white)
  term.setCursorPos(2,2); print("CrystalOS")
  term.setCursorPos(2,4); print("Um ambiente simples para CC:Tweaked")
  term.setCursorPos(2,6); print("[1] Explorador de arquivos")
  term.setCursorPos(2,7); print("[2] Bloco de notas")
  term.setCursorPos(2,8); print("[3] Calculadora")
  term.setCursorPos(2,9); print("[4] Terminal")
  term.setCursorPos(2,10); print("[5] Configuracoes")
  term.setCursorPos(2,12); print("[R] Reiniciar   [S] Desligar")
  U.footer("CrystalOS | Menu principal")
  while true do
    local _,key=os.pullEvent("key")
    if key==keys.one then return "explorer"
    elseif key==keys.two then return "notepad"
    elseif key==keys.three then return "calculator"
    elseif key==keys.four then return "terminal"
    elseif key==keys.five then return "settings"
    elseif key==keys.r then return "reboot"
    elseif key==keys.s then return "shutdown" end
  end
end
return U
