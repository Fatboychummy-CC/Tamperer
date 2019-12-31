-- requires
local defaults = require("modules.defaults")

local function dread(def)
  def = def or ""
  local pos = string.len(def) + 1
  local sx, sy = term.getCursorPos()
  local mx = term.getSize()
  local ins = false
  local tmr = -1
  local bOn = false

  term.setCursorBlink(true)

  while true do
    -- draw --

    -- clear until end of line
    term.setCursorPos(sx, sy)
    io.write(string.rep(' ', mx - sx + 1))
    -- write what we've got
    term.setCursorPos(sx, sy)
    local pss = pos - (mx - sx + 1)
    if pss >= 0 then
      io.write(string.sub(def, pss + 1))
    else
      io.write(def)
    end
    -- set cursor to our cursor's position
    local psss = sx + pos - 1
    if psss > mx then
      psss = mx
    end
    term.setCursorPos(psss, sy)
    -- if insert mode, blink full cursor
    if bOn then
      local o = term.getBackgroundColor()
      term.setBackgroundColor(colors.white)
      io.write(' ')
      term.setBackgroundColor(o)
    end

    -- get user input --
    local ev = {os.pullEvent()}
    local event = ev[1]

    if event == "char" then
      local char = ev[2]

      -- insert character into string
      -- depending on read mode
      if ins then
        def = string.sub(def, 1, pos - 1) .. char .. string.sub(def, pos + 1)
      else
        def = string.sub(def, 1, pos - 1) .. char .. string.sub(def, pos)
      end
      -- move cursor right 1 position
      pos = pos + 1
    elseif event == "key" then
      local key = ev[2]

      if key == keys.backspace then
        local ps = pos - 2

        if pos - 2 < 0 then
          ps = 0
        end

        def = string.sub(def, 1, ps) .. string.sub(def, pos)
        pos = pos - 1
        if pos < 1 then
          pos = 1
        end
      elseif key == keys.enter then
        term.setCursorBlink(false)
        print()
        return def
      elseif key == keys.right then
        pos = pos + 1
        if pos > string.len(def) + 1 then
          pos = string.len(def) + 1
        end
      elseif key == keys.left then
        pos = pos - 1
        if pos < 1 then
          pos = 1
        end
      elseif key == keys.up then
        pos = 1
      elseif key == keys.down then
        pos = string.len(def) + 1
      elseif key == keys.delete then
        def = string.sub(def, 1, pos - 1) .. string.sub(def, pos + 1)
      elseif key == keys.insert then
        if ins then
          ins = false
          term.setCursorBlink(true)
          os.cancelTimer(tmr)
          tmr = -1
          bOn = false
        else
          ins = true
          term.setCursorBlink(false)
          tmr = os.startTimer(0.4)
        end
      end
    elseif event == "timer" then
      local tm = ev[2]
      if tm == tmr then
        bOn = not bOn
        tmr = os.startTimer(0.4)
      end
    end
  end
end

-- create error if variable a is not of type b
local function cerr(a, b, err, lvl)
  if type(a) ~= b then
    error(err, lvl + 1 or 2)
  end
end

-- create error if length of string 'a' is greater than a max 'b'
local function clen(a, b, name, lvl)
  if type(a) ~= "string" then error("Check failure: not string", 2) end
  if string.len(a) > b then
    error("Page layout string " .. name .. " is too long (max: " .. tostring(b) .. ")", lvl + 1 or 2)
  end
end

-- check the page for errors
local function checkPage(page)
  -- the readability of this function is horrifying

  -- length of titles/pagenames: 12
  -- length of infos:            25
  -- length of bigInfos:         defX * 3

  cerr(page, "table", "Page layout is not a table.", 3)

  cerr(page.name, "string", "Page layout is missing name.", 3)
  clen(page.name, 12, "page.name", 3)

  cerr(page.info, "string", "Page " .. page.name .. " is missing info.", 3)
  clen(page.info, 25, "page.info", 3)

  cerr(page.bigInfo, "string", "Page " .. page.name .. " is missing bigInfo.", 3)
  clen(page.bigInfo, defaults.turtleX * 3, "page.bigInfo", 3)

  cerr(page.colors or page.colours, "table", "Page " .. page.name .. " is missing colors/colours table.", 3)
  cerr(page.colors.bg or page.colours.bg, "table", "Page " .. page.name .. " is missing bg color/colour table.", 3)
  local exp = {"main"}
  for i = 1, #exp do
    cerr(page.colors.bg[exp[i]] or page.colours.bg[exp[i]], "string", "Page " .. page.name .. " is missing bg color/colour entry" .. exp[i] .. ".", 3)
  end
  cerr(page.colors.fg or page.colours.fg, "table", "Page " .. page.name .. " is missing fg color/colour table.", 3)
  exp = {"main", "input", "unhighlight", "highlight", "info", "title"}
  for i = 1, #exp do
    cerr(page.colors.fg[exp[i]] or page.colours.fg[exp[i]], "string", "Page " .. page.name .. " is missing fg color/colour entry" .. exp[i] .. ".", 3)
  end

  if page.selections then
    for i = 1, #page.selections do
      local cur = page.selections[i]
      cerr(cur.title, "string", "Page " .. page.name .. ", selection " .. tostring(i) .. " is missing entry 'title'.", 3)
      clen(cur.title, 12, "page.selections[" .. tostring(i) .. "].title", 3)

      cerr(cur.info, "string", "Page " .. page.name .. ", selection " .. tostring(i) .. " is missing entry 'info'.", 3)
      clen(cur.info, 25, "page.selections[" .. tostring(i) .. "].info", 3)

      cerr(cur.bigInfo, "string", "Page " .. page.name .. ", selection " .. tostring(i) .. " is missing entry 'bigInfo'.", 3)
      clen(cur.bigInfo, defaults.turtleX * 3, "page.selections[" .. tostring(i) .. "].bigInfo", 3)
    end
  end

  if page.settings then
    for i = 1, #page.settings do
      local cur = page.settings[i]
      cerr(cur.title, "string", "Page " .. page.name .. ", setting " .. tostring(i) .. " is missing entry 'title'.")
      clen(cur.title, 12, "page.selections[" .. tostring(i) .. "].title", 3)

      cerr(cur.bigInfo, "string", "Page " .. page.name .. ", setting " .. tostring(i) .. " is missing entry 'bigInfo'.")
      clen(cur.bigInfo, defaults.turtleX * 3, "page.selections[" .. tostring(i) .. "].bigInfo", 3)

      cerr(cur.setting, "string", "Page " .. page.name .. ", setting " .. tostring(i) .. " is missing entry 'setting'.")

      cerr(cur.tp, "string", "Page " .. page.name .. ", setting " .. tostring(i) .. " is missing entry 'tp' (the type of setting).")
      if cur.min then
        cerr(cur.min, "number", string.format("Page %s, setting %d, minimum is of wrong type.", page.name, i))
      end
      if cur.max then
        cerr(cur.max, "number", string.format("Page %s, setting %d, maximum is of wrong type.", page.name, i))
      end
    end
  end

  if page.subPages then
    -- ONLY CHECK TOPMOST SUBPAGE, DON'T RECURSIVE CHECK
  end
end

-- returns:
-- 1: number 0, 1, 2, 3 (0:empty, 1:selection, 2:setting, 3:subpage)
-- 2: table item or nil
local function iter(obj, i)
  local sels = #obj.selections
  local sets = #obj.settings
  local subs = #obj.subPages
  if i > sels then
    if i > sels + sets then
      -- if the last, return final object
      if i == sels + sets + subs + 1 then
        return 1, {title = obj.final, info = "", bigInfo = ""}
      end
      -- if past the last, return 0
      if i > sels + sets + subs then
        return 0
      end
      -- return a subpage
      return 3, obj.subPages[i - sels - sets]
    end
    -- return a setting
    return 2, obj.settings[i - sels]
  end
  -- return a selection
  return 1, obj.selections[i]
end

-- return the size of the objects selections/settings/subPages together
local function size(obj)
  return #obj.selections + #obj.settings + #obj.subPages
end

-- edit the setting at index i, in terminal position p
local function edit(obj, i, p)
  local tp, set = iter(obj, i)
  if tp ~= 2 then
    error("Dawg something happened!", 2)
  end

  term.setCursorPos(15, 4 + p)
  term.setTextColor(colors[obj.colors.fg.input])

  -- handle the editing
  if set.tp == "string" then
    settings.set(set.setting, dread(settings.get(set.setting)))
    settings.save(".settings")
  elseif set.tp == "number" then
    io.write("NOT YET EDITABLE.            ")
    os.sleep(2)
  elseif set.tp == "color" then
    io.write("NOT YET EDITABLE.            ")
    os.sleep(2)
  elseif set.tp == "boolean" then
    io.write("NOT YET EDITABLE.            ")
    os.sleep(2)
  else
    io.write(string.format("Cannot edit type '%s'.", set.tp))
    os.sleep(2)
  end
end

-- display the page
local function display(obj)
  -- DEVNOTE: colors "push" themselves downstream

  local sel = 1
  local pointer = 1
  local pStart = 1
  local over = {}

  -- check that the page is OK
  checkPage(obj)

  while true do
    -- clear
    term.setBackgroundColor(colors[obj.colors.bg.main] or colours[obj.colours.bg.main])
    term.setTextColor(colors[obj.colors.fg.title] or colours[obj.colours.fg.title])
    term.clear()

    -- display the page title
    term.setCursorPos(1, 1)
    io.write(obj.name)

    -- display the page info
    term.setCursorPos(1, 2)
    term.setTextColor(colors[obj.colors.fg.info] or colours[obj.colours.fg.info])
    io.write(obj.info)

    -- display the four items.
    for i = 0, 3 do
      local ctype, cur = iter(obj, pStart + i)
      term.setCursorPos(2, 5 + i)

      -- discriminate by type
      if ctype == 1 then
        -- selection
        term.setTextColor(colors[obj.colors.fg.main] or colours[obj.colours.fg.main])
        io.write(cur.title)

        term.setCursorPos(15, 5 + i)
        term.setTextColor(colors[obj.colors.fg.unhighlight] or colours[obj.colours.fg.unhighlight])
        io.write(cur.info)
      elseif ctype == 2 then
        -- setting changer
        local set = settings.get(cur.setting)
        if type(set) == "string" and string.len(set) > 25 then
          set = set:sub(1, 22)
          set = set .. "..."
        end

        term.setTextColor(colors[obj.colors.fg.main] or colours[obj.colours.fg.main])
        io.write(cur.title)

        term.setCursorPos(15, 5 + i)
        term.setTextColor(colors[obj.colors.fg.unhighlight] or colours[obj.colours.fg.unhighlight])
        if cur.tp == "string" or cur.tp == "number" then
          io.write(set or "Error: empty")
        elseif cur.tp == "boolean" then
          if set == true then
            io.write("  false [ true ]")
          elseif set == false then
            io.write("[ false ] true")
          else
            -- nil or broke
            io.write("? false ? true ?")
          end
        elseif cur.tp == "color" then
          io.write("Support soon:tm:")
        else
          io.write("Unsupported type.")
        end
      elseif ctype == 3 then
        -- subpage selection
        io.write("Not yet supported.")
      else
        io.write("Broken.")
      end
    end

    -- get the selected item
    local seltp, selected = iter(obj, sel)

    -- print the info of the selected item
    term.setTextColor(colors[obj.colors.fg.info] or colours[obj.colours.fg.info])
    term.setCursorPos(1, defaults.turtleY - 2)
    io.write(selected.bigInfo)

    -- print the pointer
    term.setCursorPos(1, 4 + pointer)
    term.setTextColor(colors[obj.colors.fg.highlight] or colours[obj.colours.fg.highlight])
    io.write(">")

    -- draw down arrow
    term.setCursorPos(1, 9)
    if pStart + 3 >= size(obj) + 1 then
      term.setTextColor(colors[obj.colors.fg.unhighlight] or colours[obj.colours.fg.unhighlight])
    end
    io.write(string.char(31))

    -- draw up arrow
    term.setCursorPos(1, 4)
    if pStart > 1 then
      term.setTextColor(colors[obj.colors.fg.highlight] or colours[obj.colours.fg.highlight])
    else
      term.setTextColor(colors[obj.colors.fg.unhighlight] or colours[obj.colours.fg.unhighlight])
    end
    io.write(string.char(30))

    local ev, key = os.pullEvent("key")
    if key == keys.up then
      sel = sel - 1
      if pointer == 1 then
        pStart = pStart - 1
      end
      if pStart < 1 then
        pStart = 1
      end
      pointer = pointer - 1
      if pointer < 1 then
        pointer = 1
      end
      if sel < 1 then
        sel = size(obj) + 1
        pointer = (size(obj) + 1) < 4 and (size(obj) + 1) or 4
        pStart = sel - 3
        if pStart < 1 then
          pStart = 1
        end
      end
    elseif key == keys.down then
      sel = sel + 1
      if pointer == 4 then
        pStart = pStart + 1
      end
      pointer = pointer + 1
      if pointer > 4 then
        pointer = 4
      end
      if sel > size(obj) + 1 then
        sel = 1
        pStart = 1
        pointer = 1
      end
    elseif key == keys.enter then
      if seltp == 1 then
        -- selection
        return sel
      elseif seltp == 2 then
        -- setting
        edit(obj, sel, pointer)
      elseif seltp == 3 then
        -- subPage
      end
    end
  end
  printError("This shouldn't happen.")
  printError("Please report to le github with your layout file.")
  os.sleep(30)
end

return display
