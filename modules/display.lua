local function cerr(a, b, err, lvl)
  if type(a) ~= b then
    error(err, lvl + 1 or 2)
  end
end

local function checkPage(page)
  cerr(page, "table", "Page layout is not a table.", 3)
  cerr(page.name, "string", "Page layout is missing name.", 3)
  cerr(page.info, "string", "Page " .. page.name .. " is missing info.", 3)
  cerr(page.bigInfo, "string", "Page " .. page.name .. " is missing bigInfo.", 3)
  cerr(page.colors or page.colours, "table", "Page " .. page.name .. " is missing colors/colours table.", 3)
  cerr(page.colors.bg or page.colours.bg, "table", "Page " .. page.name .. " is missing bg color/colour table.", 3)
  local exp = {"main", "highlight"}
  for i = 1, #exp do
    cerr(page.colors.bg[exp[i]] or page.colours.bg[exp[i]], "string", "Page " .. page.name .. " is missing bg color/colour entry" .. exp[i] .. ".", 3)
  end
  cerr(page.colors.fg or page.colours.fg, "table", "Page " .. page.name .. " is missing fg color/colour table.", 3)
  exp = {"main", "input", "highlight", "info", "title"}
  for i = 1, #exp do
    cerr(page.colors.fg[exp[i]] or page.colours.fg[exp[i]], "string", "Page " .. page.name .. " is missing fg color/colour entry" .. exp[i] .. ".", 3)
  end
end

local function display(obj)
  -- DEVNOTE: colors "push" themselves downstream
  checkPage(obj)
end

return display
