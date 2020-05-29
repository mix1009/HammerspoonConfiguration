-- use with Karabiner-Elements (https://karabiner-elements.pqrs.org/)
--
-- change caps lock to "Cmd+Ctrl+Option" key using below 
-- copy and paste in browser location:
-- karabiner://karabinder/assets/complex_modifications/import?url=https://raw.githubusercontent.com/mix1009/HammerspoonConfiguration/master/karabiner.json
-- add complex modification "Change caps_lock to command+control+option." from Karabiner-Elmements Preferences.
--
-- also available from http://mix1009.com/karabiner.html

function h_bind(key, func)
  -- hyper key (caps lock)
  hs.hotkey.bind({"command","control","option"}, key, func)
end

function hs_bind(key, func)
  -- hyper+shift key (caps lock + shift)
  hs.hotkey.bind({"command","control","option","shift"}, key, func)
end

function reloadConfig(files)
  --  reload (mapped as hyper-r )
  doReload = false
  for _,file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end

local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("HammerSpoon config loaded!")

h_bind("r", function() hs.reload() end)

-- window management functions

function moveWindow(direction)
  local win = hs.window.focusedWindow()
  if win == nil then return end
  local f = win:frame()
  local s = win:screen():frame()
  if direction == "left" then
    f.x = f.x - s.w / 12
    --if f.x < 0 then f.x = 0 end
    win:setFrame(f)
  elseif direction == "right" then
    f.x = f.x + s.w / 12
    --if f.x + f.w > s.w then f.x = s.w - f.w end
    win:setFrame(f)
  elseif direction == "up" then
    f.y = f.y - s.h / 8
    --if f.y < 0 then f.y = 0 end
    win:setFrame(f)
  elseif direction == "down" then
    f.y = f.y + s.h / 8
    --if f.y + f.h > s.h then f.y = s.h - f.h end
    win:setFrame(f)
  end
end

function resizeWindow(direction, increment)
  -- hs.alert.show("resize...")
  local win = hs.window.focusedWindow()
  if win == nil then return end
  local f = win:frame()
  local s = win:screen():frame()
  local allowedSpaceFraction = 30
  local allowedSpaceWidth = s.w/allowedSpaceFraction
  local allowedSpaceHeight = s.h/allowedSpaceFraction
  local stickedToLeft = (f.x % s.w) < allowedSpaceWidth
  local rightPos = (f.x + f.w - 1) % s.w
  local stickedToRight = rightPos > (s.w - allowedSpaceWidth)
  local stickedToTop = f.y < allowedSpaceHeight
  local stickedToBottom = (f.y + f.h - 1) > (s.h - allowedSpaceHeight)
  local screenOffset = math.floor(f.x / s.w) * s.w
  
  -- hs.alert.show(s.h)
  -- hs.alert.show("x=" .. f.x .. ", w=" .. f.w .. ", sw=" .. s.w .. ", rp=" .. rightPos)
  -- hs.alert.show(stickedToRight)
  
  if direction == "left" then
    if stickedToLeft then
      f.x = 0 + screenOffset
    elseif stickedToRight then
      f.w = f.w + s.w * increment
      f.x = s.w - f.w + screenOffset
      if (f.x % s.w) < allowedSpaceWidth then
        f.x = 0 + screenOffset
        f.w = s.w
      end
      win:setFrame(f)
      return
    end
    f.w = f.w - s.w * increment
    if f.w < s.w*increment then
      f.w = s.w * increment
    end
    win:setFrame(f)
  elseif direction == "right" then
    if stickedToRight then
      f.w = f.w - s.w * increment
      f.x = s.w - f.w + screenOffset
      if f.w < s.w*increment then
        f.w = s.w * increment
        f.x = s.w - f.w + screenOffset
      end
      win:setFrame(f)
    else
      f.w = f.w + s.w * increment
      if f.w > s.w then
        f.w = s.w - f.x
      end
      win:setFrame(f)
    end
  elseif direction == "up" then
    if stickedToTop then
      f.y = 0
    elseif stickedToBottom then
      f.h = f.h + s.h * increment
      f.y = s.h - f.h
      if f.y < allowedSpaceHeight then
        f.y = 0
        f.h = s.h
      end
      win:setFrame(f)
      return
    end
    f.h = f.h - s.h * increment
    if f.h < s.h*increment then
      f.h = s.h * increment
    end
    win:setFrame(f)
  elseif direction == "down" then
    if stickedToBottom then
      -- hs.alert.show("stickedToBottom")
      f.h = f.h - s.h * increment
      f.y = s.h - f.h
      if f.h < s.h*increment then
        -- hs.alert.show("stickedToBottom - set to minimum")
        f.h = s.h * increment
        f.y = s.h - f.h
      end
      win:setFrame(f)
    else
      -- hs.alert.show("stickedToBottom no")
      f.h = f.h + s.h * increment
      if f.h > s.h then
        f.h = s.h
      end
      win:setFrame(f)
    end
  end
end

function positionWindow(x, y, w, h)
  local win = hs.window.focusedWindow()
  if win == nil then return end
  local f = win:frame()
  local s = win:screen():frame()
  f.x = x * s.w
  f.y = y * s.h
  f.w = s.w * w
  f.h = s.h * h
  -- hs.alert.show(f)
  win:setFrame(f)
end

function positionWindowWithinScreen(x, y, w, h)
  local win = hs.window.focusedWindow()
  if win == nil then return end
  local f = win:frame()
  local s = win:screen():frame()
  local screenOffset = math.floor(f.x / s.w) * s.w
  
  f.x = x * s.w + screenOffset
  f.y = y * s.h
  f.w = s.w * w
  f.h = s.h * h
  win:setFrame(f)
end

appNormalScreenFrame = {}
appFullScreenFrame = {}

function toggleFullScreen()
  local win = hs.window.focusedWindow()
  if win == nil then return end
  local f = win:frame()
  local s = win:screen():frame()
  local nf = appNormalScreenFrame[win.id]
  local ff = appFullScreenFrame[win.id]
  local screenOffset = math.floor(f.x / s.w) * s.w
  
  if ff ~= nil then
    s = ff
  end
  
  if f.w == s.w and f.h == s.h and nf then
    win:setFrame(nf)
  else
    appNormalScreenFrame[win.id] = f
    positionWindowWithinScreen(0,0,1,1)
    local f = win:frame()
    if not (f.h == s.h) then
      appFullScreenFrame[win.id] = f
    end
  end
end

function resizeWindowFunc(direction, increment)
  return function() resizeWindow(direction, increment) end
end

function moveWindowFunc(direction)
  return function() moveWindow(direction) end
end


hs.window.animationDuration = 0

function activateApp(name)
  return function()
    local win = hs.appfinder.appFromName(name)
    if win then win:activate() end
  end
end

function file_exists(name)
  local f=io.open(name,"r")
  if f~=nil then io.close(f) return true else return false end
end

function launchApp(name)
  return function()
    if file_exists("/Applications/" .. name .. ".app") then
      hs.application.launchOrFocus("/Applications/" .. name .. ".app")
      return
    end
    hs.application.launchOrFocus("/System/Applications/" .. name .. ".app")
  end
end

function pressSystemKeyFunction(key)
  -- media function with hyper-command keys
  return function()
    hs.eventtap.event.newSystemKeyEvent(key, true):post() 
    hs.eventtap.event.newSystemKeyEvent(key, false):post() 
  end
end

function speakSelectedText()
  -- used for "Speak selected text"
  -- Settings-Accessibility-Speech
  -- set Key as "Command+Shift+Control+S" for speak selected text
  return function()
    hs.eventtap.keyStroke({"command", "shift", "ctrl"}, "s")
  end
end

focusing = false
function focusStartOrEnd()
  -- focus / unfocus using Focus app. (https://heyfocus.com)
  return function()
    if not focusing then
      hs.execute("open focus://focus?minutes=45")
      focusing = true
    else
      hs.execute("open focus://unfocus")
      focusing = false
    end
  end
end


-------------------------------------------------------------------------------
-- window management key bindings

horizontalIncrement = 1/12
verticalIncrement = 1/8

h_bind("left", resizeWindowFunc("left", horizontalIncrement))
h_bind("right", resizeWindowFunc("right", horizontalIncrement))
h_bind("up", resizeWindowFunc("up", verticalIncrement))
h_bind("down", resizeWindowFunc("down", verticalIncrement))

hs_bind("left", moveWindowFunc("left"))
hs_bind("right", moveWindowFunc("right"))
hs_bind("up", moveWindowFunc("up"))
hs_bind("down", moveWindowFunc("down"))

h_bind("h", resizeWindowFunc("left", horizontalIncrement))
h_bind("l", resizeWindowFunc("right", horizontalIncrement))
h_bind("k", resizeWindowFunc("up", verticalIncrement))
h_bind("j", resizeWindowFunc("down", verticalIncrement))
hs_bind("h", moveWindowFunc("left"))
hs_bind("l", moveWindowFunc("right"))
hs_bind("k", moveWindowFunc("up"))
hs_bind("j", moveWindowFunc("down"))

h_bind("q", function() positionWindowWithinScreen(0, 0, 0.667, 1) end)
h_bind("w", function() positionWindowWithinScreen(0.667, 0, 0.333, 1) end)

h_bind("1", function() positionWindow(0, 0, 0.5, 1) end)
h_bind("2", function() positionWindow(0.5, 0, 0.5, 1) end)

if #hs.screen.allScreens() > 1  then
  h_bind("3", function() positionWindow(1, 0, 0.5, 1) end)
  h_bind("4", function() positionWindow(1.5, 0, 0.5, 1) end)
  h_bind("5", function() positionWindow(0, 0, 0.5, 0.5) end)
  h_bind("6", function() positionWindow(0.5, 0, 0.5, 0.5) end)
  h_bind("7", function() positionWindow(0, 0.5, 0.5, 0.5) end)
  h_bind("8", function() positionWindow(0.5, 0.5, 0.5, 0.5) end)
else
  h_bind("3", function() positionWindow(0, 0, 0.5, 0.5) end)
  h_bind("4", function() positionWindow(0.5, 0, 0.5, 0.5) end)
  h_bind("5", function() positionWindow(0, 0.5, 0.5, 0.5) end)
  h_bind("6", function() positionWindow(0.5, 0.5, 0.5, 0.5) end)
end
h_bind("f", function() toggleFullScreen() end)

-------------------------------------------------------------------------------
-- app key bindings

h_bind("c", launchApp("Brave Browser"))
h_bind("e", launchApp("Visual Studio Code"))
h_bind("g", launchApp("GitHub Desktop"))
h_bind("m", launchApp("Motion"))
h_bind("n", launchApp("Microsoft OneNote"))
h_bind("o", activateApp("Simulator"))
h_bind("p", launchApp("Preview"))
h_bind("s", launchApp("Safari"))
h_bind("t", launchApp("iTerm"))
h_bind("u", activateApp("Unity"))
h_bind("x", activateApp("Xcode"))
h_bind("y", launchApp("SourceTree"))
h_bind("z", activateApp("Finder"))

hs_bind("a", activateApp("Android Studio"))
hs_bind("c", launchApp("Google Chrome"))
hs_bind("d", activateApp("Discord"))
hs_bind("n", launchApp("Notes"))
hs_bind("o", activateApp("Opera")) 
hs_bind("q", launchApp("QuickTime Player"))
hs_bind("s", activateApp("Sketch"))
hs_bind("t", launchApp("Microsoft To Do"))
hs_bind("v", launchApp("VOX"))
hs_bind("x", activateApp("Final Cut Pro"))

-------------------------------------------------------------------------------
-- misc key bindings 
h_bind("a", speakSelectedText())
hs_bind("f", focusStartOrEnd())

-------------------------------------------------------------------------------
-- media key bindings

-- hs_bind("left", pressSystemKeyFunction("PREVIOUS"))
-- hs_bind("right", pressSystemKeyFunction("NEXT"))
-- hs_bind("up", pressSystemKeyFunction("SOUND_UP"))
-- hs_bind("down", pressSystemKeyFunction("SOUND_DOWN"))
-- hs_bind("space", pressSystemKeyFunction("PLAY"))
