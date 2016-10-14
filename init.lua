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

function pressHyperKey(key)
  hs.eventtap.keyStroke({"cmd", "alt", "ctrl"}, key)
end

function pressHyperShiftKey(key)
  hs.eventtap.keyStroke({"cmd", "alt", "ctrl", "shift"}, key)
end

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
  if direction == "left" then
    f.x = f.x - s.w / 12
    if f.x < 0 then f.x = 0 end
    win:setFrame(f)
  elseif direction == "right" then
    f.x = f.x + s.w / 12
    if f.x + f.w > s.w then f.x = s.w - f.w end
    win:setFrame(f)
  elseif direction == "up" then
    f.y = f.y - s.h / 8
    if f.y < 0 then f.y = 0 end
    win:setFrame(f)
  elseif direction == "down" then
    f.y = f.y + s.h / 8
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

  if direction == "left" then
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
  elseif direction == "right" then
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
  elseif direction == "up" then
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

function resizeWindowFunc(direction, increment)
  return function() resizeWindow(direction, increment) end
end

function moveWindowFunc(direction)
  return function() moveWindow(direction) end
end


-- window management key bindings

h_bind("left", resizeWindowFunc("left", 1/12))
h_bind("right", resizeWindowFunc("right", 1/12))
h_bind("up", resizeWindowFunc("up", 1/8))
h_bind("down", resizeWindowFunc("down", 1/8))

hs_bind("left", moveWindowFunc("left"))
hs_bind("right", moveWindowFunc("right"))
hs_bind("up", moveWindowFunc("up"))
hs_bind("down", moveWindowFunc("down"))

h_bind("h", resizeWindowFunc("left", 1/12))
h_bind("l", resizeWindowFunc("right", 1/12))
h_bind("k", resizeWindowFunc("up", 1/8))
h_bind("j", resizeWindowFunc("down", 1/8))
hs_bind("h", moveWindowFunc("left"))
hs_bind("l", moveWindowFunc("right"))
hs_bind("k", moveWindowFunc("up"))
hs_bind("j", moveWindowFunc("down"))

h_bind("q", function() positionWindow(0, 0, 0.667, 1) end)
h_bind("w", function() positionWindow(0.667, 0, 0.333, 1) end)

h_bind("1", function() positionWindow(0, 0, 0.5, 1) end)
h_bind("2", function() positionWindow(0.5, 0, 0.5, 1) end)
h_bind("3", function() positionWindow(0, 0, 0.5, 0.5) end)
h_bind("4", function() positionWindow(0.5, 0, 0.5, 0.5) end)
h_bind("5", function() positionWindow(0, 0.5, 0.5, 0.5) end)
h_bind("6", function() positionWindow(0.5, 0.5, 0.5, 0.5) end)
h_bind("f", function() toggleFullScreen() end)

hs.window.animationDuration = 0

-- app launch/activate key bindings

function activateApp(name)
  return function()
    local win = hs.appfinder.appFromName(name)
    if win then win:activate() end
  end
end

function launchApp(name)
  return function()
    hs.application.launchOrFocus("/Applications/" .. name .. ".app")
  end
end

h_bind("c", launchApp("Google Chrome"))
h_bind("t", launchApp("iTerm"))
hs_bind("t", function() pressHyperShiftKey("t") end)
h_bind("d", function() pressHyperShiftKey("d") end)

h_bind("s", launchApp("Safari"))

hs_bind("s", activateApp("iOS Simulator"))
h_bind("e", launchApp("Sublime Text"))
hs_bind("e", activateApp("Evernote"))
h_bind("x", activateApp("Xcode"))
h_bind("z", activateApp("Finder"))
hs_bind("a", activateApp("Android Studio"))
h_bind("n", launchApp("Notes"))
h_bind("i", activateApp("iTunes"))
hc_bind("f", activateApp("Firefox"))
hs_bind("o", activateApp("Opera"))

hs_bind("c", launchApp("Calendar"))
hs_bind("v", launchApp("VOX"))
hs_bind("w", launchApp("Wunderlist"))
h_bind("v", activateApp("VLC"))
h_bind("y", launchApp("SourceTree"))
h_bind("p", launchApp("Preview"))
h_bind("b", function()
    local win = hs.appfinder.appFromName("Sublime Text")
    if win then win:activate() end
    hs.eventtap.keyStroke({"cmd"}, "b")
    win = hs.appfinder.appFromName("Minecraft")
    if win then win:activate() end
end)


-- media function with hyper-command keys

function pressSystemKeyFunction(key)
    return function()
      hs.eventtap.event.newSystemKeyEvent(key, true):post() 
      hs.eventtap.event.newSystemKeyEvent(key, false):post() 
    end
end

hc_bind("left", pressSystemKeyFunction("PREVIOUS"))
hc_bind("right", pressSystemKeyFunction("NEXT"))
hc_bind("up", pressSystemKeyFunction("SOUND_UP"))
hc_bind("down", pressSystemKeyFunction("SOUND_DOWN"))
hc_bind("space", pressSystemKeyFunction("PLAY"))


h_bind("a", function()
  -- hs.alert.show("hyper-shift-A")
  -- used for "Speak selected text"
  pressHyperShiftKey("a")
end)

focusing = false

hs_bind("f", function()
  if not focusing then
    hs.execute("open focus://focus?minutes=45")
    focusing = true
  else
    hs.execute("open focus://unfocus")
    focusing = false
  end
end)
