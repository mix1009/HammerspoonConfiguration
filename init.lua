-- karabiner-elements setting: "simple_modifications": {"caps_lock": "f18"}
-- reference: https://github.com/lodestone/hyper-hacks/blob/master/hammerspoon/init.lua
k = hs.hotkey.modal.new({}, "F17")

-- Enter Hyper Mode when F18 (Hyper/Capslock) is pressed
pressedF18 = function()
  -- hs.alert.show("pressed F18")
  k.triggered = false
  k:enter()
end

-- Leave Hyper Mode when F18 (Hyper/Capslock) is pressed,
--   send ESCAPE if no other keys are pressed.
releasedF18 = function()
  -- hs.alert.show("released F18")
  k:exit()
  if not k.triggered then
    hs.eventtap.keyStroke({}, 'ESCAPE')
  end
end

-- Bind the Hyper key
f18 = hs.hotkey.bind({}, 'F18', pressedF18, releasedF18)
f18s = hs.hotkey.bind({"shift"}, 'F18', pressedF18, releasedF18)
f18c = hs.hotkey.bind({"command"}, 'F18', pressedF18, releasedF18)

-- key bind functions (hyper / hyper-shift)

function h_bind(key, func)
  k:bind('', key, nil, function()
    func()
    k.triggered = true
  end)
end

function hs_bind(key, func)
  k:bind({"shift"}, key, nil, function()
    func()
    k.triggered = true
  end)
end

function hc_bind(key, func)
  k:bind({"command"}, key, nil, function()
    func()
    k.triggered = true
  end)
end


--  reload

function reloadConfig(files)
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
  if direction == "Left" then
    f.x = f.x - s.w / 6
    if f.x < 0 then f.x = 0 end
    win:setFrame(f)
  elseif direction == "Right" then
    f.x = f.x + s.w / 6
    if f.x + f.w > s.w then f.x = s.w - f.w end
    win:setFrame(f)
  elseif direction == "Up" then
    f.y = f.y - s.h / 4
    if f.y < 0 then f.y = 0 end
    win:setFrame(f)
  elseif direction == "Down" then
    f.y = f.y + s.h / 4
    if f.y + f.h > s.h then f.y = s.h - f.h end
    win:setFrame(f)
  end
end

function resizeWindow(direction, increment)
  local win = hs.window.focusedWindow()
  if win == nil then return end
  local f = win:frame()
  local s = win:screen():frame()
  local allowedSpace = s.h/10
  local stickedToLeft = f.x < allowedSpace
  local stickedToRight = f.x + f.w > s.w - allowedSpace
  local stickedToTop = f.y < allowedSpace
  local stickedToBottom = f.y + f.h > s.h - allowedSpace

  -- hs.alert.show(s.h)
  -- hs.alert.show((f.y + f.h))
  -- hs.alert.show(s.h - allowedSpace)

  if direction == "Left" then
    if stickedToLeft then
      f.x = 0
    elseif stickedToRight then
      f.w = f.w + s.w * increment
      f.x = s.w - f.w
      if f.x < allowedSpace then
        f.x = 0
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
  elseif direction == "Right" then
    if stickedToRight then
      f.w = f.w - s.w * increment
      f.x = s.w - f.w
      if f.w < s.w*increment then
        f.w = s.w * increment
        f.x = s.w - f.w
      end
      win:setFrame(f)
    else
      f.w = f.w + s.w * increment
      if f.w > s.w then
        f.w = s.w - f.x
      end
      win:setFrame(f)
    end
  elseif direction == "Up" then
    if stickedToTop then
      f.y = 0
    elseif stickedToBottom then
      f.h = f.h + s.h * increment
      f.y = s.h - f.h
      if f.y < allowedSpace then
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
  elseif direction == "Down" then
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
        f.h = s.h - f.y
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

  if ff ~= nil then
    s = ff
  end

  if f.w == s.w and f.h == s.h and nf then
    win:setFrame(nf)
  else
    appNormalScreenFrame[win.id] = f
    positionWindow(0,0,1,1)
    local f = win:frame()
    if not (f.h == s.h) then
      appFullScreenFrame[win.id] = f
    end
  end
end


-- window management key bindings

h_bind("left", function() resizeWindow("Left", 1/6) end)
h_bind("right", function() resizeWindow("Right", 1/6) end)
h_bind("up", function() resizeWindow("Up", 1/4) end)
h_bind("down", function() resizeWindow("Down", 1/4) end)

hs_bind("left", function() moveWindow("Left") end)
hs_bind("right", function() moveWindow("Right") end)
hs_bind("up", function() moveWindow("Up") end)
hs_bind("down", function() moveWindow("Down") end)

h_bind("H", function() resizeWindow("Left", 1/6) end)
h_bind("L", function() resizeWindow("Right", 1/6) end)
h_bind("K", function() resizeWindow("Up", 1/4) end)
h_bind("J", function() resizeWindow("Down", 1/4) end)
hs_bind("H", function() moveWindow("Left") end)
hs_bind("L", function() moveWindow("Right") end)
hs_bind("K", function() moveWindow("Up") end)
hs_bind("J", function() moveWindow("Down") end)

h_bind("q", function() positionWindow(0, 0, 0.667, 1) end)
h_bind("w", function() positionWindow(0.667, 0, 0.333, 1) end)

h_bind("1", function() positionWindow(0, 0, 0.5, 1) end)
h_bind("2", function() positionWindow(0.5, 0, 0.5, 1) end)
h_bind("3", function() positionWindow(0, 0, 0.5, 0.5) end)
h_bind("4", function() positionWindow(0.5, 0, 0.5, 0.5) end)
h_bind("5", function() positionWindow(0, 0.5, 0.5, 0.5) end)
h_bind("6", function() positionWindow(0.5, 0.5, 0.5, 0.5) end)
h_bind("F", function() toggleFullScreen() end)

hs.window.animationDuration = 0

-- app launch/activate key bindings

function activateApp(name)
  local win = hs.appfinder.appFromName(name)
  if win then win:activate() end
end

function launchApp(name)
  hs.application.launchOrFocus("/Applications/" .. name .. ".app")
end

h_bind("C", function() launchApp("Google Chrome") end)
h_bind("T", function() launchApp("iTerm") end)
h_bind("S", function() launchApp("Safari") end)

hs_bind("S", function() activateApp("iOS Simulator") end)
h_bind("E", function() activateApp("Sublime Text") end)
hs_bind("E", function() activateApp("Evernote") end)
h_bind("X", function() activateApp("Xcode") end)
h_bind("Z", function() activateApp("Finder") end)
h_bind("A", function() activateApp("Android Studio") end)
h_bind("N", function() launchApp("Notes") end)

hs_bind("c", function() launchApp("CodeRunner") end)
hs_bind("v", function() launchApp("VOX") end)
hs_bind("w", function() launchApp("Wunderlist") end)
h_bind("v", function() activateApp("VLC") end)
h_bind("y", function() launchApp("SourceTree") end)


-- media function with hyper-command keys

function pressSystemKey(key)
    hs.eventtap.event.newSystemKeyEvent(key, true):post() 
    hs.eventtap.event.newSystemKeyEvent(key, false):post() 
end

hc_bind("left", function() pressSystemKey("PREVIOUS") end)
hc_bind("right", function() pressSystemKey("NEXT") end)
hc_bind("up", function() pressSystemKey("SOUND_UP") end)
hc_bind("down", function() pressSystemKey("SOUND_DOWN") end)
hc_bind("space", function() pressSystemKey("PLAY") end)


