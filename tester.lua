-- requires
local tamperer = require("minified")

-- user data
local layoutsFolder = "/test/layouts/"
local layouts = fs.list(layoutsFolder)

-- request user input
print("Select, one of the following:")
for i = 1, #layouts do
  print(tostring(i) .. ":", layouts[i])
end

io.write("> ")

-- get user input
local inp = tonumber(io.read())
if type(inp) ~= "number" or inp < 1 or inp > #layouts or inp % 1 ~= 0 then
  error("Nah dawg ur a rart")
end

-- read file data
local fileIn = io.open(layoutsFolder .. layouts[inp], 'r')
local data = textutils.unserialize(fileIn:read("*a"))
fileIn:close()
fileIn = nil

local function callback(filename, setting, newValue, obj)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)
  local function pf(...)
    print(string.format(...))
  end

  pf("Filename       : %s", filename)
  pf("Setting Changed: %s", setting)
  pf("New value set  : %s", newValue)
  pf("OBJ            : %s", obj)
  os.sleep(3)
end

-- run the page
local ok, err = pcall(tamperer.displayFile, layoutsFolder .. layouts[inp], callback, 5)
if not ok then
  io.write("!")
  os.sleep(5)
end
-- clear and set cursor pos to 1, 1
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

-- if there was an error, state the error.
if not ok then
  print("Errored:")
  printError(err)
else
  print("Return code:", err)
end

print("Complete.")
