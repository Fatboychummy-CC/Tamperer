-- requires
local defaults = require("modules.defaults")

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
    end
  end

  if page.subPages then
    -- ONLY CHECK TOPMOST SUBPAGE, DON'T RECURSIVE CHECK
  end
end

-- display the page
local function display(obj)
  -- DEVNOTE: colors "push" themselves downstream
  checkPage(obj)
end

return display
