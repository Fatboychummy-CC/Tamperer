--[[
  Tamperer, by fatboychummy.
  A simple GUI creator where you make quick GUIs by making a lson table

  Sha256 API included (when required) created by Anavrins: https://pastebin.com/6UV4qfNF



  TODO: better color handling
  TODO: cleanup
  TODO: more code comments
  TODO: Better name for the "positions" table
]]

--[[
 positions: stores vital locations that are to be used in place of hardcoded
 locations, along with other data

  X:       max size X
  Y:       max size Y
  nameLen: Max length of an item name
  infoLen: Max length of an item info
  startY:  start point for the menu, default to 4
  bigY:    bigInfo Y position, default to y-2
  items:   how many items to display per page
]]

local positions = {}
positions.X, positions.Y = term.getSize()
positions.bigY = positions.Y - 2
positions.startY = 4

-- Mode selector, for quick comparison of what type of display we are using.
local mode = 0
if pocket then
  -- pocket mode
  mode = 1

  positions.nameLen = 8
  positions.infoLen = 16
  positions.items = 11

elseif turtle then
  -- turtle  mode
  mode = 2

  positions.nameLen = 12
  positions.infoLen = 25
  positions.items = 4
else
  -- computer mode
  mode = 3

  positions.nameLen = 16
  positions.infoLen = 32
  positions.items = 10
end

local ccolors = {}
for k, v in pairs(colors) do
  ccolors[k] = v
  ccolors[v] = k
end
for k, v in pairs(colours) do
  ccolors[k] = v
  ccolors[v] = k
end

--[[
  format table with data we can check easily later.
  -- .choices(x,y,z)         > allow only the following choices for this value
  -- .depends(x=type(value)) > setting this value depends on value x being of type type and value value
  -- .len(x)                 > maximum length of string.
  -- ["?"] > iterative
  -- ["!"] > table not required.
]]
local format = {
  name     = "string",
  info     = "string",
  bigInfo  = "string",
  platform = "string.choices(all,turtle,pocket,computer)",

  colors = {
    bg = {
      main = "color"
    },
    fg = {
      main          = "color",
      title         = "color",
      info          = "color",
      listInfo      = "color",
      listTitle     = "color",
      bigInfo       = "color",
      selector      = "color",
      arrowDisabled = "color",
      arrowEnabled  = "color",
      input         = "color",
      error         = "color",
    }
  },
  selections = {
    ["!"] = true,
    ["?"] = {
      title   = "string",
      info    = "string",
      bigInfo = "string"
    }
  },
  settings = {
    ["!"] = true,
    location = "string",
    ["?"] = {
      setting = "string",
      title   = "string",
      tp      = "string.choices(string,number,color,password,boolean)",
      bigInfo = "string",
      min     = "nil/number.depends(tp=string(number))",
      max     = "nil/number.depends(tp=string(number))",
      store   = "nil/string.depends(tp=string(password)).choices(plain,sha256,sha256salt,kristwallet)"
    }
  },
  final = "nil/string"
}

format.subPages = {
  ["!"] = true,
  ["?"] = format
}

-- grab a file from link, and put into file named name
local function getRequiredFile(link, name)
  term.clear()
  term.setCursorPos(1, 1)
  print("Grabbing a file that is required to display this page...")
  print(link, "==>", name)

  -- it's already here, exit.
  if fs.exists(name) then
    return
  end

  -- download the file
  local h = http.get(link) -- connect to link
  if h then
    print("Connected.")
    local dat = h.readAll() -- read the data
    h.close()

    -- open the local file
    local h2 = io.open(name, 'w')
    if h2 then
      -- write the local file
      h2:write(dat):close()
      print("Complete.")
    else
      error("Failed to open " .. tostring(name) .. " for writing.", 2)
    end
  else
    error("Failed to connect to " .. tostring(link), 2)
  end
end

--[[
  "Default" read
  Like read or io.read, but allows you to set an initial value.
  (Also the insert key allows to swap from insert to overwrite)

  readChar is for passwords, set it to "*" or whatever floats your boat.
]]
local function dread(def, readChar)
  def = def or ""
  local pos = string.len(def) + 1
  local sx, sy = term.getCursorPos()
  local mx = term.getSize()
  local ins = false
  local tmr = -1
  local bOn = false

  term.setCursorBlink(true)

  -- main loop
  while true do
    -- if readChar is enabled, display it as a bunch of those characters.
    -- otherwise leave it as is.
    local disp = type(readChar) == "string" and string.rep(readChar:sub(1, 1), string.len(def)) or def
    -- draw --

    -- clear until end of line
    term.setCursorPos(sx, sy)
    io.write(string.rep(' ', mx - sx + 1))
    -- write what we've got
    term.setCursorPos(sx, sy)
    local pss = pos - (mx - sx + 1)
    if pss >= 0 then
      io.write(string.sub(disp, pss + 1))
    else
      io.write(disp)
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

      if key == keys.backspace then -- remove a character from left of current position
        local ps = pos - 2

        if pos - 2 < 0 then
          ps = 0
        end

        def = string.sub(def, 1, ps) .. string.sub(def, pos)
        pos = pos - 1
        if pos < 1 then
          pos = 1
        end
      elseif key == keys.enter then -- return what is input
        term.setCursorBlink(false)
        print()
        return def
      elseif key == keys.right then -- move position to the right
        pos = pos + 1
        if pos > string.len(def) + 1 then
          pos = string.len(def) + 1
        end
      elseif key == keys.left then -- move position to the left
        pos = pos - 1
        if pos < 1 then
          pos = 1
        end
      elseif key == keys.up then -- jump to the beginning
        pos = 1
      elseif key == keys.down then -- jump to the end
        pos = string.len(def) + 1
      elseif key == keys.delete then -- remove a character from right of current position
        def = string.sub(def, 1, pos - 1) .. string.sub(def, pos + 1)
      elseif key == keys.insert then -- swap between insert/overwrite modes
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
    elseif event == "timer" then -- if in insert mode, blink the full character.
      local tm = ev[2]
      if tm == tmr then
        bOn = not bOn
        tmr = os.startTimer(0.4)
      end
    end
  end
end

-- check the page for errors
local function checkPage(page)
  -- nil/number/string.depends(x=string(bla)).choices(x,y,z)
  local split = "[^/]+"
  local depends = "%.depends%((.+)=(.+)%((.+)%)%)"
  local choices = "%.choices%((.-)%)"
  local choicesSplit = "[^,]+"
  local function formatTypes(name, key, types, got)
    return string.format("Section '%s': '%s': Expected '%s', got '%s'.", name, key, type(types) == "string" and types or table.concat(types, "/"), got)
  end

  local function check(tbl, name, format2)
    if type(tbl) ~= "table" then error("AAAA") end
    if name == nil then
      error(formatTypes("unknown", "name", "string", "nil"), 0)
    end
    -- for each item in the format page
    for k, v in pairs(format2 or format) do
      if k == "?" then
        -- handle iterative items (1,2,3,4,5,6) where all are similar
        print("Iterative ignored.")
      elseif k == "!" then
        -- extra statement to block the else from receiving !
        print("Non-Requirement.")
      elseif type(v) == "table" then
        if type(tbl[k]) ~= "table" and not v["!"] then
          -- if not a table AND required, error.
          print(textutils.serialize(tbl))
          error(formatTypes(name, k, "table", type(tbl[k])))
        elseif type(tbl[k]) == "table" then
          -- recurse
          print("Recurse.", k, tbl[k])
          check(tbl[k], name .. "." .. tostring(k), v)
        else
          tbl[k] = {}
        end
      else
        -- handle any other type.
        print("Other.", v)

        -- get types allowed by splitting the string
        print("Split.")
        local types = {}
        for match in v:gmatch(split) do
          types[#types + 1] = match
        end

        -- check for presence of matching type and proper dependencies (if any)
        print("Check")
        local ok = false
        for i = 1, #types do
          local current = types[i]
          print("  " .. current)
          -- check if dependencies
          local dKey, dType, dVal = current:match(depends)
          -- check if choices
          local cs = current:match(choices)

          -- check if the type matches
          local tOK = false
          local firstDot = current:find("%.")
          local tp = current
          if firstDot then
            tp = current:sub(1, firstDot - 1)
          end
          if type(tbl[k]) == tp then
            tOK = true
          end

          -- check for dependencies and if they match.
          local dOK = false
          if dKey then
            -- if dkey, then a dependency exists.  tbl[dkey] should be of type dtype, with value dval.
            print("##dependency")
            if dType == "number" then
              dVal = tonumber(dVal)
            elseif dType == "password" then
              error(string.format("Section '%s': '%s': Cannot depend on password!", name, k))
            end
            if tbl[dKey] and type(tbl[dKey]) == dType and tbl[dKey] == dVal then
              dOK = true
            end
          else
            dOK = true
          end

          -- check for choices and if they match
          local cOK = false
          if cs then
            print("##choices")
            local tCs = {}
            for match in cs:gmatch(choicesSplit) do
              tCs[#tCs + 1] = match
            end

            for i = 1, #tCs do
              if tp == "number" then
                tCs[i] = tonumber(tCs[i])
              end
              if tCs[i] == tbl[k] then
                cOK = true
                break
              end
            end
          else
            cOK = true
          end

          -- if all checks are ok, we are good.
          if dOK and cOK and tOK then
            ok = true
            break
          end
          if tOK and not dOK then
            error(string.format(
              "Section '%s': '%s': Dependency not met ('%s' must be of type '%s', and with value '%s').",
              name, k,
              dKey, dType, dVal
            ))
          end
          if tOK and not cOK then
            error(string.format(
              "Section '%s': '%s': Choices allowed: %s (got %s).",
              name, k,
              cs, tbl[k]
            ))
          end
        end
        if not ok then

        end
      end
    end
  end
  check(page, page.name)
  term.clear()
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
        return 1, {title = obj.final or "Exit", info = "", bigInfo = ""}
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

-- read a number.
local function readNumber(obj, set, p)
  local str = tostring(settings.get(set.setting))
  local mx, my = term.getSize()

  if str == "nil" then str = "0" end

  while true do
    -- set cursor to where it needs to be
    term.setCursorPos(positions.nameLen + 3, positions.startY + p)
    io.write(string.rep(' ', mx - 14))
    term.setCursorPos(positions.nameLen + 3, positions.startY + p)
    local inp = tonumber(dread(str)) -- read the input, attempt to convert to number

    if not inp then
      -- NaN
      term.setCursorPos(positions.nameLen + 3, positions.startY + p)
      io.write(string.rep(' ', mx - 14))
      term.setCursorPos(positions.nameLen + 3, positions.startY + p)
      local col = term.getTextColor()
      term.setTextColor(ccolors[obj.colors.fg.error])
      io.write("Not a number.")
      term.setTextColor(col)

      os.sleep(2)
    else
      local ok = true
      -- check if number is below min
      if set.min and inp < set.min then
        ok = false
        term.setCursorPos(positions.nameLen + 3, positions.startY + p)
        io.write(string.rep(' ', mx - 14))
        term.setCursorPos(positions.nameLen + 3, positions.startY + p)
        local col = term.getTextColor()
        term.setTextColor(ccolors[obj.colors.fg.error])
        io.write(string.format("Minimum: %d", set.min))
        term.setTextColor(col)
        str = tostring(set.min)
      end

      -- check if number is above max
      if set.max and inp > set.max then
        ok = false
        term.setCursorPos(positions.nameLen + 3, positions.startY + p)
        io.write(string.rep(' ', mx - 14))
        term.setCursorPos(positions.nameLen + 3, positions.startY + p)
        local col = term.getTextColor()
        term.setTextColor(ccolors[obj.colors.fg.error])
        io.write(string.format("Maximum: %d", set.max))
        term.setTextColor(col)
        str = tostring(set.max)
      end

      -- if all was good, return the number.  Else, an error was displayed.
      -- Sleep for 2 seconds to let the user read it.
      if ok then
        return inp
      else
        os.sleep(2)
      end
    end
  end
end

-- Read a color.  Accepts be "gray" or "grey", or "128".
local function readColor(obj, set, p)
  local str = tostring(ccolors[settings.get(set.setting)])
  local mx, my = term.getSize()

  if str == "nil" then str = "?" end

  while true do
    term.setCursorPos(positions.nameLen + 3, positions.startY + p)
    io.write(string.rep(' ', mx - 14))
    term.setCursorPos(positions.nameLen + 3, positions.startY + p)
    local inp = dread(str)
    local ninp = tonumber(inp)

    if ninp then
      -- number input
      if ccolors[ninp] then
        return ninp
      else
        term.setCursorPos(positions.nameLen + 3, positions.startY + p)
        io.write(string.rep(' ', mx - 14))
        term.setCursorPos(positions.nameLen + 3, positions.startY + p)
        local col = term.getTextColor()
        term.setTextColor(ccolors[obj.colors.fg.error])
        io.write("Not a color.")
        term.setTextColor(col)
        os.sleep(2)
      end
    else
      -- color-name input
      if ccolors[inp] then
        return ccolors[inp]
      else
        term.setCursorPos(positions.nameLen + 3, positions.startY + p)
        io.write(string.rep(' ', mx - 14))
        term.setCursorPos(positions.nameLen + 3, positions.startY + p)
        local col = term.getTextColor()
        term.setTextColor(ccolors[obj.colors.fg.error])
        io.write("Not a color.")
        term.setTextColor(col)
        os.sleep(2)
      end
    end
  end
end

-- Actually read the password
local function getPass(obj, set, p)
  local mx, my = term.getSize()

  while true do
    -- get user initial input
    term.setCursorPos(2, positions.startY + p)
    io.write(string.rep(' ', mx - 1))
    term.setCursorPos(2, positions.startY + p)
    term.setTextColor(ccolors[obj.colors.fg.listTitle])
    io.write("Password:")
    term.setCursorPos(positions.nameLen + 3, positions.startY + p)
    io.write(string.rep(' ', mx - 14))
    term.setCursorPos(positions.nameLen + 3, positions.startY + p)
    term.setTextColor(ccolors[obj.colors.fg.input])
    local pass = dread("", '*')

    -- get the user to repeat the password to make sure no typos
    term.setCursorPos(2, positions.startY + p)
    io.write(string.rep(' ', mx - 1))
    term.setCursorPos(2, positions.startY + p)
    term.setTextColor(ccolors[obj.colors.fg.listTitle])
    io.write("Repeat:")
    term.setCursorPos(positions.nameLen + 3, positions.startY + p)
    io.write(string.rep(' ', mx - 14))
    term.setCursorPos(positions.nameLen + 3, positions.startY + p)
    term.setTextColor(ccolors[obj.colors.fg.input])
    local pass2 = dread("", '*')

    -- if they match, return the password
    if pass == pass2 then
      -- Password hashed and returned immediately.  No middle function call
      -- between the password read and the hashing.
      local salt

      if set.store == "sha256" or set.store == "sha256salt"
        or set.store == "kristwallet" then
        -- grab the sha256 lib
        -- Requiring here should be okay to do, I doubt there'll be more than
        -- one password per page so it won't affect speed or anything.
        local sha256 = require(".sha256")

        -- if we want to salt it, generate a salt.
        if set.store == "sha256salt" then
          salt = math.random(1, 100000)
          pass = tostring(salt) .. "," .. pass
        end

        -- if it's a kristwallet format, insert the kristwallet salt.
        if set.store == "kristwallet" then
          pass = "KRISTWALLET" .. pass
        end

        -- convert to sha256, then to characters that are human-readable.
        pass = sha256.digest(pass):toHex()

        -- if it's a kristwallet, append -000 in kristwallet fashion
        if set.store == "kristwallet" then
          pass = pass .. "-000"
        end
      end

      return pass, salt
    else
      -- the passwords did not match (typo or something else)
      term.setCursorPos(positions.nameLen + 3, positions.startY + p)
      io.write(string.rep(' ', mx - 14))
      term.setCursorPos(positions.nameLen + 3, positions.startY + p)
      local col = term.getTextColor()
      term.setTextColor(ccolors[obj.colors.fg.error])
      io.write("Not matching!")
      term.setTextColor(col)
      os.sleep(2)
    end
  end
end

-- ask the user if they are sure they want to edit the password
local function askPass(obj, set, p)
  local mx, my = term.getSize()
  local confirm = false

  term.setTextColor(ccolors[obj.colors.fg.listTitle])

  term.setCursorPos(2, positions.startY + p)
  io.write(string.rep(' ', mx - 1))
  term.setCursorPos(2, positions.startY + p)
  io.write("You sure?")


  while true do
    -- get the user to confirm they want to change the password
    term.setCursorPos(positions.nameLen + 3, positions.startY + p)
    io.write(string.rep(' ', mx - 14))
    term.setCursorPos(positions.nameLen + 3, positions.startY + p)
    term.setTextColor(ccolors[obj.colors.fg.input])
    io.write(confirm and "[ YES ] NO" or "  YES [ NO ]")

    local ev, key = os.pullEvent("key")

    if key == keys.right or key == keys.left or key == keys.tab then
      confirm = not confirm
    elseif key == keys.enter then
      return confirm
    end
  end
end

-- edit the setting at index i, in terminal position p
local function edit(obj, i, p)
  local mx, my = term.getSize()
  local tp, set = iter(obj, i)
  if tp ~= 2 then
    error("Dawg something happened!", 2)
  end

  term.setCursorPos(positions.nameLen + 3, positions.startY + p)
  term.setTextColor(colors[obj.colors.fg.input])

  -- handle the editing
  -- get an x input, with the input starting with the currently set setting
  if set.tp == "string" then
    settings.set(set.setting, dread(settings.get(set.setting)))
    settings.save(obj.settings.location)
  elseif set.tp == "number" then
    local inp = readNumber(obj, set, p)

    settings.set(set.setting, inp)
    settings.save(obj.settings.location)
  elseif set.tp == "color" then
    local col = readColor(obj, set, p)

    settings.set(set.setting, col)
    settings.save(obj.settings.location)
  elseif set.tp == "boolean" then
    local sete = settings.get(set.setting)
    if sete == nil then
      sete = true
    else
      sete = not sete
    end
    settings.set(set.setting, sete)
    settings.save(obj.settings.location)
  elseif set.tp == "password" then
    if askPass(obj, set, p) then
      local pass, salt = getPass(obj, set, p)
      settings.set(set.setting, pass)
      if salt then
        settings.set(set.setting .. ".salt", salt)
      end
      settings.save(obj.settings.location)
    end
  else
    -- if the type is uneditable, say it's uneditable.
    local col = term.getTextColor()
    term.setTextColor(ccolors[obj.colors.fg.error])
    io.write(string.format("Cannot edit type '%s'.", set.tp))
    term.setTextColor(col)
    os.sleep(2)
  end
end

-- display the page
-- obj: the page to be displayed
-- I_ABSOLUTELY_KNOW_WHAT_I_AM_DOING: Set to true, will skip error checking.
--    Warning: Only do this if you absolutely know what you are doing.
local function display(obj, I_ABSOLUTELY_KNOW_WHAT_I_AM_DOING)

  local sel = 1
  local pointer = 1
  local pStart = 1
  local over = {}

  -- check that the page is OK
  if not I_ABSOLUTELY_KNOW_WHAT_I_AM_DOING then
    checkPage(obj)
  end

  if not obj.settings.location then
    obj.settings.location = ".settings"
  end

  settings.load(obj.settings.location)

  while true do
    -- clear
    term.setBackgroundColor(colors[obj.colors.bg.main])
    term.setTextColor(colors[obj.colors.fg.title])
    term.clear()

    -- display the page title
    term.setCursorPos(1, 1)
    io.write(obj.name)

    -- display the page info
    term.setCursorPos(1, 2)
    term.setTextColor(colors[obj.colors.fg.info])
    io.write(obj.info)

    -- display the four items.
    for i = 0, positions.items - 1 do
      local ctype, cur = iter(obj, pStart + i)
      term.setCursorPos(2, 5 + i)

      -- discriminate by type
      if ctype == 1 then
        -- selection
        term.setTextColor(colors[obj.colors.fg.listTitle])
        io.write(cur.title)

        term.setCursorPos(positions.nameLen + 3, 5 + i)
        term.setTextColor(colors[obj.colors.fg.listInfo])
        io.write(cur.info)
      elseif ctype == 2 then
        -- setting changer
        local set = settings.get(cur.setting)
        if type(set) == "string" and string.len(set) > positions.infoLen then
          set = set:sub(1, positions.infoLen - 3)
          set = set .. "..."
        end

        term.setTextColor(colors[obj.colors.fg.listTitle])
        io.write(cur.title)

        term.setCursorPos(positions.nameLen + 3, 5 + i)
        term.setTextColor(colors[obj.colors.fg.listInfo])
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
          io.write(set and string.format("%s (%d)", ccolors[set], set)
                   or "? (nil)")
        elseif cur.tp == "password" then
          local cv = {plain = "Plaintext", sha256 = "sha256", sha256salt = "sha256 + salt", kristwallet = "Kristwallet"}
          if pocket then
            io.write(set and cv[cur.store] or "Not yet set")
          else
            io.write(set and "Stored as " .. cv[cur.store] or "Not yet set")
          end
        else
          io.write(pocket and "Unsupported" or "Unsupported type.")
        end
      elseif ctype == 3 then
        -- subpage selection
        term.setTextColor(colors[obj.colors.fg.listTitle])
        io.write(cur.name)

        term.setTextColor(colors[obj.colors.fg.listInfo])
        term.setCursorPos(positions.nameLen + 3, 5 + i)
        io.write(cur.info)
      elseif ctype ~= 0 then
        io.write("Broken.")
      end
    end

    -- get the selected item
    local seltp, selected = iter(obj, sel)

    -- print the info of the selected item
    term.setTextColor(colors[obj.colors.fg.bigInfo])
    term.setCursorPos(1, positions.Y - 2)
    io.write(selected.bigInfo)

    -- print the pointer
    term.setCursorPos(1, positions.startY + pointer)
    term.setTextColor(colors[obj.colors.fg.selector])
    io.write(">")

    -- draw down arrow
    term.setCursorPos(1, positions.startY + positions.items + 1)
    if pStart + positions.items > size(obj) + 1 then
      term.setTextColor(colors[obj.colors.fg.arrowDisabled])
    else
      term.setTextColor(colors[obj.colors.fg.arrowEnabled])
    end
    io.write(string.char(31))

    -- draw up arrow
    term.setCursorPos(1, positions.startY)
    if pStart > 1 then
      term.setTextColor(colors[obj.colors.fg.arrowEnabled])
    else
      term.setTextColor(colors[obj.colors.fg.arrowDisabled])
    end
    io.write(string.char(30))

    -- the pointer and page display shit
    local ev, key = os.pullEvent("key")
    if key == keys.up then -- if you press upArrow...
      sel = sel - 1 -- move the selected item up one
      if pointer == 1 then -- if the pointer is at 1, scroll up.
        pStart = pStart - 1
      end
      if pStart < 1 then -- if we've scrolled up too far, set the scroll back to where it was.
        pStart = 1
      end
      pointer = pointer - 1 -- move the pointer up a slot
      if pointer < 1 then -- if the pointer is too high, set the pointer back to the top.
        pointer = 1
      end
      if sel < 1 then -- if we've reached the tippy top of the ladder
        sel = size(obj) + 1 -- select the very bottom item
        pointer = (size(obj) + 1) < positions.items
                  and (size(obj) + 1) or positions.items -- move the pointer to the bottom
        pStart = sel - positions.items + 1 -- scroll down to the bottom
        if pStart < 1 then
          pStart = 1 -- then make sure we didn't scroll up after we tried to scroll down.
        end
      end
    elseif key == keys.down then -- if you press downArrow...
      sel = sel + 1 -- move the selected item down one
      if pointer == positions.items then -- if the pointer is at the bottom
        pStart = pStart + 1 -- scroll down
      end
      pointer = pointer + 1 -- move the pointer down
      if pointer > positions.items then -- if the pointer is now too far down...
        pointer = positions.items -- move it back up to the bottom
      end
      if sel > size(obj) + 1 then -- if we've scrolled past the bottom
        sel = 1 -- select the very top item
        pStart = 1 -- scroll up
        pointer = 1 -- set the pointer to be the very first item.
      end
    elseif key == keys.enter then -- if we press enter...
      if seltp == 1 then -- item type is a selectable item
        return sel -- return the selected item number
      elseif seltp == 2 then -- item type is a setting
        edit(obj, sel, pointer) -- edit the setting
      elseif seltp == 3 then -- item type is a subPage
        -- get the page
        local i, cur = iter(obj, sel)
        -- clone-down certain items that don't need to be in every subpage
        if not cur.colors then
          cur.colors = obj.colors
        end
        if not cur.platform then
          cur.platform = obj.platform
        end
        if not cur.settings then
          cur.settings = {location = obj.settings.location}
        end
        if not cur.settings.location then
          cur.settings.location = obj.settings.location
        end

        -- run the sub page
        display(cur, I_ABSOLUTELY_KNOW_WHAT_I_AM_DOING)
      end
    end
  end
  printError("This shouldn't happen.")
  printError("Please report to le github with your layout file.")
  os.sleep(30)
end

return display
