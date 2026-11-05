-- CrystalOS boot loader
os.setComputerLabel("CrystalOS")
if fs.exists("/crystal_updater.lua") then
  shell.run("/crystal_updater.lua")
end
if fs.exists("/CrystalOS/system/kernel.lua") then
  shell.run("/CrystalOS/system/kernel.lua")
else
  term.clear(); term.setCursorPos(1,1)
  print("CrystalOS is not installed.")
  print("Run: crystal_installer")
end
