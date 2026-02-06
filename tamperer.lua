--- Mini Menu Library
--- Provides a simple menu system for user interaction.

local expect, field = (function()
  local e = require "cc.expect"
  return e.expect, e.field
end)()
local strings = require "cc.strings"
local sha256, random
local PBKDF2_ITERATIONS = 500
local PBKDF2_SALT_LENGTH = 16
local TAMPERER_TEMP_DIR = "/.tamperer_tmp/"


---@class TampererOptions The built version of the menu options.
---@field title string The title of the menu.
---@field description string A short description displayed below the title.
---@field colors TampererColors Custom colors for the menu.

---@class TampererColors
---@field title TampererGenericOptionColors The colors for the title.
---@field description TampererGenericOptionColors The colors for the description.
---@field selection_arrow TampererGenericOptionColors The colors for the selection arrow.
---@field arrows_on TampererGenericOptionColors The colors for the scroll arrows, when enabled.
---@field arrows_off TampererGenericOptionColors The colors for the scroll arrows, when disabled.
---@field selected TampererGenericOptionColors The colors for selected options.
---@field unselected TampererGenericOptionColors The colors for unselected options.
---@field selection_description TampererGenericOptionColors The colors for the selection description.
---@field popup_border TampererGenericOptionColors The colors for borders of popups.
---@field body_bg number The background color for the body of the menu.
---@field tree_view_deeper TampererGenericOptionColors The colors for the "go deeper" indicator in tree views.

---@class TampererGenericOptionColors
---@field fg number The foreground color.
---@field bg number The background color.



---@class OverrideTampererOptions The user-facing options for the menu, not all need to be specified.
---@field title string The title of the menu.
---@field description string? A short description displayed below the title.
---@field colors OverrideTampererColors? Custom colors for the menu.

---@class OverrideTampererColors
---@field title OverrideTampererGenericOptionColors? The colors for the title.
---@field description OverrideTampererGenericOptionColors? The colors for the description.
---@field selection_arrow OverrideTampererGenericOptionColors? The colors for the selection arrow.
---@field arrows_on OverrideTampererGenericOptionColors? The colors for the scroll arrows, when enabled.
---@field arrows_off OverrideTampererGenericOptionColors? The colors for the scroll arrows, when disabled.
---@field selected OverrideTampererGenericOptionColors? The colors for selected options.
---@field unselected OverrideTampererGenericOptionColors? The colors for unselected options.
---@field selection_description OverrideTampererGenericOptionColors? The colors for the selection description.
---@field popup_border OverrideTampererGenericOptionColors? The colors for borders of popups.
---@field body_bg number? The background color for the body of the menu.
---@field tree_view_deeper OverrideTampererGenericOptionColors? The colors for the "go deeper" indicator in tree views.

---@class OverrideTampererGenericOptionColors
---@field fg number? The foreground color.
---@field bg number? The background color.



---@alias TampererTypes
---| "number"
---| "string"
---| "longstring"
---| "boolean"
---| "list"
---| "callback" # fun(self: Tamperer, selection: TampererSelection)
---| "submenu"
---| "password"
---| "passwordnohash"
---| "passwordcallback"
---| "file"
---| "color"
---| "exit" # Exits the currently running menu when selected.


---@class TampererSelection
---@field i_label string The internal label for the selection. Useful for identifying it.
---@field label string|fun(self: TampererSelection): string The label for the selection, or a function that returns it based off of the current state.
---@field description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@field type TampererTypes The type of the selection.
---@field value any The current value of the selection.
---@field display_value string The serialized value of the selection, for display purposes.

---@class TampererSelection.Boolean : TampererSelection
---@field type "boolean"
---@field value boolean

---@class TampererSelection.List : TampererSelection
---@field type "list"
---@field value integer
---@field options string[] The list of options.

---@class TampererSelection.Number : TampererSelection
---@field type "number"
---@field value number
---@field minimum number? The minimum allowable value.
---@field maximum number? The maximum allowable value.

---@class TampererSelection.String : TampererSelection
---@field type "string" | "longstring"
---@field value string
---@field minimum_length number? The minimum allowable length.
---@field maximum_length number? The maximum allowable length.

---@class TampererSelection.Callback : TampererSelection
---@field type "callback"
---@field value fun(self: Tamperer, selection: TampererSelection) The callback to execute when selected.

---@class TampererSelection.Submenu : TampererSelection
---@field type "submenu"
---@field value Tamperer The submenu to open when selected.

---@class TampererSelection.Password : TampererSelection
---@field type "password"
---@field value { hash: string, salt: string } The hashed password and salt.
---@field password_options TampererPasswordOptionsFilled The options used for the password hashing and or requirements.

---@class TampererSelection.PasswordNoHash : TampererSelection
---@field type "passwordnohash"
---@field value string The raw password.
---@field password_options TampererPasswordOptionsFilled The options used for the password hashing and or requirements.

---@class TampererSelection.PasswordCallback : TampererSelection
---@field type "passwordcallback"
---@field value { hash: string, salt: string } The hashed password and salt to use for verification.
---@field callback fun() The callback to execute when the correct password is entered.
---@field password_options TampererPasswordOptionsFilled The options used for the password hashing and or requirements.

---@class TampererSelection.File : TampererSelection
---@field type "file"
---@field value string The file path.

---@class TampererSelection.Color : TampererSelection
---@field type "color"
---@field value integer The color code.

---@class TampererSelection.Exit : TampererSelection
---@field type "exit"
---@field value nil

---@class TampererPasswordOptionsFilled
---@field hashing TampererPasswordOptions.Hashing The hashing options.
---@field requirements TampererPasswordOptions.Requirements The password requirements.

---@class TampererPasswordOptionsFilled.Hashing
---@field iterations integer The number of iterations to use for PBKDF2 hashing.
---@field salt_length integer The length of the salt to generate for PBKDF2 hashing.

---@class TampererPasswordOptionsFilled.Requirements
---@field min_length integer The minimum length required for the password.
---@field max_length integer The maximum length allowed for the password.
---@field require_uppercase boolean Whether at least one uppercase letter is required.
---@field require_lowercase boolean Whether at least one lowercase letter is required.
---@field require_number boolean Whether at least one number is required.
---@field require_special boolean Whether at least one special character is required.
---@field disallowed_characters string A string of characters that are not allowed in the password.

---@class TampererPasswordOptions
---@field hashing TampererPasswordOptions.Hashing? The hashing options.
---@field requirements TampererPasswordOptions.Requirements? The password requirements.

---@class TampererPasswordOptions.Hashing
---@field iterations integer? The number of iterations to use for PBKDF2 hashing, defaults to 500.
---@field salt_length integer? The length of the salt to generate for PBKDF2 hashing, if a salt is not provided.

---@class TampererPasswordOptions.Requirements
---@field min_length integer? The minimum length required for the password.
---@field max_length integer? The maximum length allowed for the password.
---@field require_uppercase boolean? Whether at least one uppercase letter is required.
---@field require_lowercase boolean? Whether at least one lowercase letter is required.
---@field require_number boolean? Whether at least one number is required.
---@field require_special boolean? Whether at least one special character is required.
---@field disallowed_characters string? A string of characters that are not allowed in the password.




---@class TampererState
---@field selected_index number The currently selected index in the menu.
---@field scroll_offset number The current scroll offset for the menu.



---@type TampererColors
local default_colors = {
  title = { fg = colors.yellow, bg = colors.black },
  description = { fg = colors.lightGray, bg = colors.black },
  selected = { fg = colors.white, bg = colors.black },
  unselected = { fg = colors.white, bg = colors.black },
  selection_description = { fg = colors.gray, bg = colors.black },
  arrows_on = { fg = colors.white, bg = colors.black },
  arrows_off = { fg = colors.gray, bg = colors.black },
  selection_arrow = { fg = colors.yellow, bg = colors.black },
  popup_border = { fg = colors.yellow, bg = colors.black },
  body_bg = colors.black,
  tree_view_deeper = { fg = colors.green, bg = colors.black },
}

local color_lookup = {}
for name, color in pairs(colors) do
  if type(color) == "number" then
    color_lookup[color] = name:lower()
    color_lookup[name:lower()] = color
  end
end



--- Updates the display value of a selection based on its type and current value.
---@param selection TampererSelection The selection to update.
local function display_value(selection)
  local w = term.getSize()
  local midpoint = math.ceil(w * 0.38)
  local val_max_length = w - midpoint
  if selection.type == "number" or selection.type == "string" or selection.type == "longstring" then
    ---@cast selection TampererSelection.Number|TampererSelection.String
    selection.display_value = tostring(selection.value)
  elseif selection.type == "list" then
    ---@cast selection TampererSelection.List
    selection.display_value = selection.options[selection.value] or "Invalid Option"
  elseif selection.type == "boolean" then
    ---@cast selection TampererSelection.Boolean
    selection.display_value = selection.value and "[ true ] false" or "  true [ false ]"
  elseif selection.type == "password" then
    ---@cast selection TampererSelection.Password
    selection.display_value = ('\xb7'):rep(8) -- Display 8 bullet points regardless of password length.
  elseif selection.type == "passwordnohash" then
    ---@cast selection TampererSelection.PasswordNoHash
    -- We display less bullet points here to indicate that whatever lib underneath is pulling the raw password.
    -- This doesn't necessarily mean it's less secure, but it is a hint to the user.
    selection.display_value = ('\xb7'):rep(6) -- Display 6 bullet points regardless of password length.
  elseif selection.type == "passwordcallback" then
    ---@cast selection TampererSelection.PasswordCallback
    selection.display_value = "Password protected."
  elseif selection.type == "file" then
    ---@cast selection TampererSelection.File

    local path = selection.value
    if #path > val_max_length then
      path = "..." .. path:sub(-val_max_length + 3)
    end

    selection.display_value = path
  elseif selection.type == "color" then
    ---@cast selection TampererSelection.Color
    local color_code, color_name
    if type(selection.value) == "string" then
      ---@diagnostic disable-next-line: undefined-field
      color_name = selection.value:lower()
      -- Grab the color code from the name.
      color_code = color_lookup[color_name]
    else
      color_code = selection.value
      color_name = color_lookup[color_code]
    end

    if color_name and color_code then
      selection.display_value = ("%s (%d)"):format(color_name, color_code)
    else
      selection.display_value = "Invalid color"
    end
  elseif selection.type == "callback" or selection.type == "submenu" or selection.type == "exit" then
    selection.display_value = ""
  else
    selection.display_value = "Unknown type"
  end
end



--- Initialize ccryptolib
local function init_sha()
  if not sha256 then
    local ok, mod = pcall(require, "ccryptolib.sha256")
    if not ok then
      error("SHA-256 could not be loaded. Please install CCryptolib.", 0)
    end
    sha256 = mod
  end
  if not random then
    local ok, mod = pcall(require, "ccryptolib.random")
    if not ok then
      error("Random module could not be loaded. Please install CCryptolib.", 0)
    end
    random = mod
  end
  if not random.isInit() then
    local x, y = term.getCursorPos()
    term.write((' '):rep(10))
    term.setCursorPos(x, y)
    term.write("Init...")
    random.initWithTiming()
    term.setCursorPos(x, y)
    term.write((' '):rep(10))
    term.setCursorPos(x, y)
  end
end

--- Hash a password using SHA-256.
---@param password string The password to hash.
---@param password_options TampererPasswordOptionsFilled The PBKDF2 options to use.
---@return string hash The hashed password.
---@return string salt The salt used in hashing.
local function hash_password(password, password_options)
  init_sha()

  local salt = random.random(password_options.hashing.salt_length)
  local hash = sha256.pbkdf2(password, salt, password_options.hashing.iterations)

  return hash, salt
end



---@class Tamperer
---@field options TampererOptions The options for the menu.
---@field selections TampererSelection[] The selections in the menu.
---@field state TampererState The current state data of the menu.
---@field on_change fun(self: Tamperer, selection: TampererSelection)? The callback for when an option is changed.
local Tamperer = {}

local mm_mt = {}
mm_mt.__index = Tamperer


--- Create a new Tamperer.
---@param options OverrideTampererOptions The options for the menu.
---@return Tamperer menu The created menu.
function Tamperer.new(options)
  local self = setmetatable({
    options = {},
    selections = {},
    state = {selected_index = 1, scroll_offset = 0},
  }, mm_mt)

  expect(1, options, "table")
  field(options, "title", "string")
  field(options, "description", "string", "nil")
  field(options, "colors", "table", "nil")
  self.options.title = options.title
  self.options.description = options.description or ""
  self.options.colors = {} ---@diagnostic disable-line: missing-fields We fill this in below.
  local user_colors = options.colors or {}

  for k, color in pairs(default_colors) do
    if user_colors[k] then
      if type(color) == "table" then
        self.options.colors[k] = {
          fg = user_colors[k].fg or color.fg,
          bg = user_colors[k].bg or color.bg,
        }
      else
        self.options.colors[k] = user_colors[k]
      end
    else
      self.options.colors[k] = color
    end
  end

  return self
end



--- Draw the menu in its current state.
---@return self self For method chaining.
function Tamperer:draw()
  local w, h = term.getSize()

  -- Allocate most of the space to the value display.
  -- Turtle: mid 15, label 12, value 24
  local midpoint = math.ceil(w * 0.38)
  local max_label_length = midpoint - 3
  local val_max_length = w - midpoint
  local max_selections = h - 9

  term.setBackgroundColor(self.options.colors.body_bg)
  term.clear()

  -- Draw title
  term.setCursorPos(1, 1)
  term.setBackgroundColor(self.options.colors.title.bg)
  term.setTextColor(self.options.colors.title.fg)
  term.clearLine()
  term.write(self.options.title)

  -- Draw description (max 2 lines)
  local wrapped = strings.wrap(self.options.description, w)
  term.setCursorPos(1, 2)
  term.setBackgroundColor(self.options.colors.description.bg)
  term.setTextColor(self.options.colors.description.fg)
  term.write(wrapped[1] or "")
  term.setCursorPos(1, 3)
  term.write(wrapped[2] or "")

  -- Draw the current selection description, max height - 1 (title) - 2 (description) - 4 (selection description) - 2 (scroll arrows)
  -- Pull the description, if needed
  local selected = self.selections[self.state.selected_index + self.state.scroll_offset]
  local description
  if type(selected.description) == "function" then
    description = selected:description()
  else
    description = selected.description
  end
  ---@cast description string

  local wrapped = strings.wrap(description, w)
  local size = math.min(4, #wrapped)
  for i = 1, size do
    term.setCursorPos(1, h - size + i)
    term.setBackgroundColor(self.options.colors.description.bg)
    term.setTextColor(self.options.colors.description.fg)
    term.write(wrapped[i])
  end

  -- Draw the options in the body.
  -- 4 options drawn at a time.
  for i = 1, max_selections do
    -- for y = 5, 8 do
    local y = i + 4
    local selection = self.selections[y - 4 + self.state.scroll_offset]
    if not selection then break end -- No more selections to draw.
    if selection == selected then
      term.setBackgroundColor(self.options.colors.selection_arrow.bg)
      term.setTextColor(self.options.colors.selection_arrow.fg)
      term.setCursorPos(1, y)
      term.write('>')
      term.setBackgroundColor(self.options.colors.selected.bg)
      term.setTextColor(self.options.colors.selected.fg)
    else
      term.setBackgroundColor(self.options.colors.unselected.bg)
      term.setTextColor(self.options.colors.unselected.fg)
      term.setCursorPos(2, y)
    end

    -- Pull the label, if needed
    local label
    if type(selection.label) == "function" then
      label = selection:label()
    else
      label = selection.label
    end
    ---@cast label string

    term.write(label:sub(1, max_label_length))

    -- Get the display value, and display it.
    display_value(selection)
    term.setTextColor(self.options.colors.selection_description.fg)
    term.setBackgroundColor(self.options.colors.selection_description.bg)
    term.setCursorPos(midpoint, y)
    term.write(selection.display_value:sub(1, val_max_length))
  end

  -- Draw the scroll arrows, if needed.
  if #self.selections > max_selections then
    term.setCursorPos(1, 4)
    if self.state.scroll_offset > 0 then
      term.setTextColor(self.options.colors.arrows_on.fg)
      term.setBackgroundColor(self.options.colors.arrows_on.bg)
    else
      term.setTextColor(self.options.colors.arrows_off.fg)
      term.setBackgroundColor(self.options.colors.arrows_off.bg)
    end
    term.write('\x1e')

    term.setCursorPos(1, h - 4)
    if self.state.scroll_offset + max_selections < #self.selections then
      term.setTextColor(self.options.colors.arrows_on.fg)
      term.setBackgroundColor(self.options.colors.arrows_on.bg)
    else
      term.setTextColor(self.options.colors.arrows_off.fg)
      term.setBackgroundColor(self.options.colors.arrows_off.bg)
    end
    term.write('\x1f')
  end

  return self
end


--#region readers
-- This region is for the different readers for different option types.

local function flash(x, y, text, color, time)
  term.setCursorPos(x, y)
  local old_fg = term.getTextColor()
  term.setTextColor(color or old_fg)
  term.write(text .. (' '):rep(50 - #text))
  sleep(time or 1)
  term.setTextColor(old_fg)
  term.setCursorPos(x, y)
  term.write((' '):rep(#text))
  term.setCursorPos(x, y)
end



--- Creates a fancy lookin box
---@param self Tamperer The menu instance.
---@param x number The x position of the box.
---@param y number The y position of the box.
---@param w number The width of the box.
---@param h number The height of the box.
local function fancy_box(self, x, y, w, h)
  -- Draw all non-inverted characters first.
  term.setBackgroundColor(self.options.colors.popup_border.bg)
  term.setTextColor(self.options.colors.popup_border.fg)
  term.setCursorPos(x, y)
  term.write('\x9c') -- top left corner
  term.write(('\x8c'):rep(w - 2)) -- top row
  for i = y + 1, y + h - 2 do -- left column
    term.setCursorPos(x, i)
    term.write('\x95')
  end
  term.setCursorPos(2, y + h - 1)
  term.write('\x8d') -- bottom left corner
  term.write(('\x8c'):rep(w - 2)) -- bottom row
  term.write('\x8e') -- bottom right corner


  -- Draw all inverted characters next.
  term.setBackgroundColor(self.options.colors.popup_border.fg)
  term.setTextColor(self.options.colors.popup_border.bg)
  term.setCursorPos(x + w - 1, y)
  term.write('\x93') -- top right corner
  for i = y + 1, y + h - 2 do -- right column
    term.setCursorPos(x + w - 1, i)
    term.write('\x95')
  end
end



--- Reads a number.
---@param self Tamperer The menu instance.
---@param selection TampererSelection.Number The selection to read for.
---@return number value The read number.
local function read_number(self, selection)
  local x, y = term.getCursorPos()
  local out

  repeat
    local input = read(nil, nil, nil, tostring(selection.value)) --[[@as string]]
    out = tonumber(input)

    if not out then
      flash(x, y, "Not a number.", colors.red)
    end

    if out and out < selection.minimum then
      flash(x, y, ("Minimum: %d"):format(selection.minimum), colors.red)
      out = nil
    end

    if out and out > selection.maximum then
      flash(x, y, ("Maximum: %d"):format(selection.maximum), colors.red)
      out = nil
    end
  until out
  ---@cast out number

  return out
end



--- Reads a string.
---@param self Tamperer The menu instance.
---@param selection TampererSelection.String The selection to read for.
---@return string value The read string.
local function read_string(self, selection)
  local x, y = term.getCursorPos()
  local out

  repeat
    term.setTextColor(colors.white)
    out = read(nil, nil, nil, selection.value) --[[@as string]]

    if #out < selection.minimum_length then
      flash(x, y, ("Minimum length: %d"):format(selection.minimum_length), colors.red)
      out = nil
    elseif #out > selection.maximum_length then
      flash(x, y, ("Maximum length: %d"):format(selection.maximum_length), colors.red)
      out = nil
    end
  until out
  ---@cast out string

  return out
end



--- Reads a "long string"
--- This works by launching the builtin text editor with a temporary file.
---@param self Tamperer The menu instance.
---@param selection TampererSelection.String The selection to read for.
---@return string value The read string.
local function read_longstring(self, selection)
  fs.makeDir(TAMPERER_TEMP_DIR)
  local tmp_path = fs.combine(TAMPERER_TEMP_DIR, "longstring_" .. os.epoch("utc") .. "_" .. math.random(1000, 9999) .. ".txt")
  local file = fs.open(tmp_path, "w")
  if not file then
    error("Could not open temporary file for long string input.", 0)
  end
  file.write(selection.value)
  file.close()

  local x, y = term.getCursorPos()
  local w, h = term.getSize()
  local win = window.create(term.current(), 3, 3, w - 4, h - 4)

  -- Temporarily hide the ability to `run` programs within the `edit` program.
  -- Funnily enough, the check for this is just if `shell.openTab` exists.
  local old_open_tab = shell.openTab
  shell.openTab = nil

  -- Hide the ability to `print` as well.
  local old_find = peripheral.find
  ---@diagnostic disable-next-line: duplicate-set-field hehe i overwrited the function
  peripheral.find = function(_type)
    if _type == "printer" then
      return nil
    else
      return old_find(_type)
    end
  end



  local content
  repeat
    fancy_box(self, 2, 2, w - 2, h - 2)
    -- Run the editor.
    local old = term.redirect(win)
    shell.run("edit", tmp_path)
    term.redirect(old)

    local file = fs.open(tmp_path, "r")
    if not file then
      error("Could not open temporary file for long string input.", 0)
    end
    content = file.readAll() --[[@as string]]
    file.close()

    self:draw()
    if #content < selection.minimum_length then
      flash(x, y, ("Minimum length: %d"):format(selection.minimum_length), colors.red)
      content = nil
    elseif #content > selection.maximum_length then
      flash(x, y, ("Maximum length: %d"):format(selection.maximum_length), colors.red)
      content = nil
    end
  until content
  ---@cast content string

  -- Restore `shell.openTab` and `peripheral.find`.
  shell.openTab = old_open_tab
  peripheral.find = old_find

  fs.delete(TAMPERER_TEMP_DIR)

  return content
end



--- Read in a raw password.
---@param self Tamperer The menu instance.
---@param password_options TampererPasswordOptionsFilled The PBKDF2 options to use.
---@param confirm boolean If true, asks "Confirm password" instead of "Enter password".
---@return string password The entered password.
local function raw_password(self, password_options, confirm)
  expect(2, password_options, "table")
  if not password_options.requirements.min_length then error("Here!", 3) end
  local x, y = term.getCursorPos()
  term.setTextColor(colors.yellow)
  flash(x, y, confirm and "Confirm password" or "Enter password", colors.yellow)

  local password
  repeat
    password = read('\xb7') --[[@as string]]

    if #password < password_options.requirements.min_length then
      flash(x, y, ("Minimum length: %d"):format(password_options.requirements.min_length), colors.red)
      password = nil
    elseif #password > password_options.requirements.max_length then
      flash(x, y, ("Maximum length: %d"):format(password_options.requirements.max_length), colors.red)
      password = nil
    elseif password_options.requirements.require_uppercase and not password:find("%u") then
      flash(x, y, "Need uppercase", colors.red)
      password = nil
    elseif password_options.requirements.require_lowercase and not password:find("%l") then
      flash(x, y, "Need lowercase", colors.red)
      password = nil
    elseif password_options.requirements.require_number and not password:find("%d") then
      flash(x, y, "Need number", colors.red)
      password = nil
    elseif password_options.requirements.require_special and not password:find("%p") then
      flash(x, y, "Need special", colors.red)
      password = nil
    elseif password_options.requirements.disallowed_characters then
      local disallowed_found = false
      for i = 1, #password_options.requirements.disallowed_characters do
        local char = password_options.requirements.disallowed_characters:sub(i, i)
        if password:find(char, 1, true) then
          flash(x, y, ("Not allowed: %q"):format(char), colors.red)
          disallowed_found = true
          break
        end
      end
      if disallowed_found then
        password = nil
      end
    end
  until password
  ---@cast password string

  return password
end



--- Read in a password.
---@param self Tamperer The menu instance.
---@param password_options TampererPasswordOptionsFilled The PBKDF2 options to use.
---@return string? hash The hashed password.
---@return string? salt The salt used in hashing.
local function read_password(self, password_options)
  init_sha()

  local x, y = term.getCursorPos()
  local password = raw_password(self, password_options, false)
  term.setCursorPos(x, y)
  local confirm = raw_password(self, password_options, true)

  if password ~= confirm then
    flash(x, y, "Passwords do not match.", colors.red, 2)
    return
  end
  if password == "" then
    return
  end

  term.setCursorPos(x, y)
  term.write((' '):rep(#password))
  term.setCursorPos(x, y)
  term.write("Hashing...")
  return hash_password(password, password_options)
end



--- Compare a password against a stored hash. Used for password callbacks.
---@param self Tamperer The menu instance.
---@param selection TampererSelection.PasswordCallback The selection to compare against.
---@return boolean correct Whether the password was correct.
local function compare_password(self, selection)
  init_sha()

  local x, y = term.getCursorPos()
  term.setTextColor(self.options.colors.selected.fg)
  term.setBackgroundColor(self.options.colors.selected.bg)
  flash(x, y, "Enter password", colors.yellow)
  local password = raw_password(self, selection.password_options, false)
  local hash = sha256.pbkdf2(password, selection.value.salt, selection.password_options.hashing.iterations)

  if hash == selection.value.hash then
    flash(x, y, "Password correct.", colors.green)
    return true
  end
  flash(x, y, "Password incorrect.", colors.red, 2)
  return false
end



---@class TampererTreeNode
---@field value any The value at this node. Not necessarily required.
---@field display_value string The displayed value for this node.
---@field parent TampererTreeNode? The parent node.
---@field children TampererTreeNode[] The child nodes.


--- Reads in a value from a tree structure.
---@param self Tamperer The menu instance.
---@param root TampererTreeNode The root node of the tree.
---@param current TampererTreeNode? The current node within the tree. If nil, starts at the root.
---@return TampererTreeNode value The selected node.
local function read_tree(self, root, current)
  local node = current or root
  local selected = 1
  local scroll_offset = 0
  local w, h = term.getSize()
  local win = window.create(term.current(), 3, 3, w - 4, h - 4)
  local _w, _h = win.getSize()
  fancy_box(self, 2, 2, w - 2, h - 2)


  if #node.children == 0 then
    current = node
    node = node.parent
    if not node then
      error("Cannot read tree with no nodes.", 0)
    end

    -- Find the index of the child we just came from, so we can select it by default.
    for i, child in ipairs(node.children) do
      if child == current then
        scroll_offset = math.max(0, i - math.floor(_h / 2))
        selected = i - scroll_offset
        break
      end
    end
  end

  local function draw()
    win.setVisible(false)
    win.setBackgroundColor(self.options.colors.body_bg)
    win.clear()

    local function dotdotdotcut(value, width)
      local display = value:sub(1, width)
      if #display < #value then
        display = "..." .. display:sub(1, #display - 3)
      end
      return display
    end

    -- Draw the title (the current node's display name).
    win.setCursorPos(1, 1)
    win.setTextColor(self.options.colors.title.fg)
    win.setBackgroundColor(self.options.colors.title.bg)
    win.write(dotdotdotcut(node.display_value, _w))

    -- Draw the options (the child nodes).
    for i = 1, _h - 3 do
      if node.children[i + scroll_offset] then
        local child = node.children[i + scroll_offset]
        win.setCursorPos(1, i + 2)
        if i == selected then
          win.setBackgroundColor(self.options.colors.selection_arrow.bg)
          win.setTextColor(self.options.colors.selection_arrow.fg)
          win.write('>')
          win.setBackgroundColor(self.options.colors.selected.bg)
          win.setTextColor(self.options.colors.selected.fg)
        else
          win.write(' ')
          win.setBackgroundColor(self.options.colors.unselected.bg)
          win.setTextColor(self.options.colors.unselected.fg)
        end
        win.write(dotdotdotcut(child.display_value, _w - 2))

        if #child.children > 0 then
          win.setTextColor(self.options.colors.tree_view_deeper.fg)
          win.setBackgroundColor(self.options.colors.tree_view_deeper.bg)
          win.setCursorPos(_w, i + 2)
          win.write('\x10')
        end
      end
    end

    -- Draw scroll indicator arrows
    if scroll_offset > 0 then
      win.setCursorPos(1, 2)
      win.setTextColor(self.options.colors.arrows_on.fg)
      win.setBackgroundColor(self.options.colors.arrows_on.bg)
      win.write('\x1e')
    else
      win.setCursorPos(1, 2)
      win.setTextColor(self.options.colors.arrows_off.fg)
      win.setBackgroundColor(self.options.colors.arrows_off.bg)
      win.write('\x1e')
    end

    if scroll_offset + _h - 3 < #node.children then
      win.setCursorPos(1, _h)
      win.setTextColor(self.options.colors.arrows_on.fg)
      win.setBackgroundColor(self.options.colors.arrows_on.bg)
      win.write('\x1f')
    else
      win.setCursorPos(1, _h)
      win.setTextColor(self.options.colors.arrows_off.fg)
      win.setBackgroundColor(self.options.colors.arrows_off.bg)
      win.write('\x1f')
    end

    win.setVisible(true)
  end

  local key_callbacks = {
    [keys.up] = function()
      if selected > 1 then
        selected = selected - 1
      elseif scroll_offset > 0 then
        scroll_offset = scroll_offset - 1
      else
        -- At the top already, jump to the bottom.
        scroll_offset = math.max(0, #node.children - (_h - 3))
        selected = math.min(#node.children - scroll_offset, _h - 3)
      end
    end,
    [keys.down] = function()
      if selected < math.min(#node.children - scroll_offset, _h - 3) then
        selected = selected + 1
      elseif scroll_offset + _h - 3 < #node.children then
        scroll_offset = scroll_offset + 1
      else
        -- At the bottom already, jump to the top.
        scroll_offset = 0
        selected = 1
      end
    end,
    [keys.enter] = function()
      local child = node.children[selected + scroll_offset]
      return child
    end,
    [keys.right] = function()
      -- Descend into the selected node, if possible.
      local child = node.children[selected + scroll_offset]
      if #child.children > 0 then
        node = child
        selected = 1
        scroll_offset = 0
      end
    end,
    [keys.backspace] = function()
      if node.parent then
        node = node.parent
        selected = 1
        scroll_offset = 0
      end
    end,
  }
  key_callbacks[keys.left] = key_callbacks[keys.backspace]
  key_callbacks[keys.a] = key_callbacks[keys.backspace]
  key_callbacks[keys.q] = key_callbacks[keys.backspace]
  key_callbacks[keys.space] = key_callbacks[keys.enter]
  key_callbacks[keys.w] = key_callbacks[keys.up]
  key_callbacks[keys.s] = key_callbacks[keys.down]
  key_callbacks[keys.d] = key_callbacks[keys.right]

  local old = term.redirect(win)
  while true do
    draw()
    local _, key = os.pullEvent("key")

    if key_callbacks[key] then
      local result = key_callbacks[key]()
      if result then
        term.redirect(old)
        return result
      end
    end
  end
end



--- Read in a file path.
---@param self Tamperer The menu instance.
---@param current string The current value.
---@return string value The read file path.
local function read_file(self, current)
  -- Index the entire filesystem into nodes.
  ---@class TampererFileTreeNode : TampererTreeNode
  ---@field is_dir boolean Whether this node is a directory.
  ---@field children TampererFileTreeNode[] The child nodes.
  ---@field parent TampererFileTreeNode? The parent node.
  local root = {
    value = "/",
    display_value = "/",
    parent = nil,
    children = {},
    is_dir = true,
  }
  local current_node = root

  --- Index a single directory, add it to the given parent node.
  ---@param path string The path to index.
  ---@param parent TampererFileTreeNode The parent node to add to.
  local function index_dir(path, parent)
    local items = fs.list(path)
    for _, item in ipairs(items) do
      local full_path = fs.combine(path, item)
      local node = {
        value = full_path,
        display_value = item .. (fs.isDir(full_path) and "/" or ""),
        parent = parent,
        children = {},
        is_dir = fs.isDir(full_path),
      }
      table.insert(parent.children, node)
      if fs.isDir(full_path) then
        index_dir(full_path, node)
      end
      if full_path == current then
        current_node = node
      end
    end

    -- Sort the children by directories first, then alphabetically.
    table.sort(parent.children, function(a, b)
      if a.is_dir and not b.is_dir then
        return true
      elseif not a.is_dir and b.is_dir then
        return false
      else
        return a.display_value:lower() < b.display_value:lower()
      end
    end)
  end

  -- Start indexing from the root.
  local x, y = term.getCursorPos()
  flash(x, y, "Indexing filesystem...", colors.yellow)
  index_dir("/", root)

  -- Read the tree.
  local result = read_tree(self, root, current_node)
  return result.value
end



--- Read a color value.
---@param self Tamperer The menu instance.
---@param current integer The current color value.
---@return integer value The read color value.
local function read_color(self, current)
  local x, y = term.getCursorPos()
  local out
  term.setTextColor(self.options.colors.selected.fg)
  term.setBackgroundColor(self.options.colors.selected.bg)
  repeat
    local input = read(nil, nil, nil, tostring(current)) --[[@as string]]
    local color = tonumber(input)
    if color_lookup[color] then
      out = color
    elseif color_lookup[input:lower()] then
      out = color_lookup[input:lower()]
    else
      flash(x, y, "Invalid color.", colors.red)
    end
  until out
  ---@cast out integer

  return out
end


--- Read a list value.
---@param self Tamperer The menu instance.
---@param options string[] The list of options.
---@param current integer The current index of the selection.
---@return integer value The read index of the selection.
local function read_list(self, options, current)
  local x, y = term.getCursorPos()

  -- Convert the options into a single dimensional list of nodes for the tree reader.
  local root = {
    value = nil,
    display_value = "Options",
    parent = nil,
    children = {},
  }

  for i, option in ipairs(options) do
    table.insert(root.children, {
      value = i,
      display_value = option,
      parent = root,
      children = {},
    })
  end

  local result = read_tree(self, root, root.children[current])
  return result.value
end


--#endregion readers



--- Select the current option.
---@return boolean exit Whether the menu should exit. This is true if the selected option is of type "exit", false otherwise.
function Tamperer:select()
  local selected = self.selections[self.state.selected_index + self.state.scroll_offset]
  if not selected then
    error("No selection at index " .. tostring(self.state.selected_index) .. ". This is a bug.", 2)
  end

  -- The position on the screen where the selection input is.
  local w, h = term.getSize()
  local midpoint = math.ceil(w * 0.38)
  local x, y = midpoint, self.state.selected_index + 4
  term.setCursorPos(x, y)
  term.write((' '):rep(50))
  term.setCursorPos(x, y)

  if selected.type == "number" then
    ---@cast selected TampererSelection.Number
    selected.value = read_number(self, selected) or selected.value
  elseif selected.type == "string" then
    ---@cast selected TampererSelection.String
    selected.value = read_string(self, selected)
  elseif selected.type == "longstring" then
    ---@cast selected TampererSelection.String
    selected.value = read_longstring(self, selected) or selected.value
  elseif selected.type == "boolean" then
    ---@cast selected TampererSelection.Boolean
    selected.value = not selected.value
  elseif selected.type == "list" then
    ---@cast selected TampererSelection.List
    selected.value = read_list(self, selected.options, selected.value) or selected.value
  elseif selected.type == "password" then
    ---@cast selected TampererSelection.Password

    local hash, salt = read_password(self, selected.password_options)
    if not hash or not salt then
      return false
    end
    selected.value = {hash = hash, salt = salt}
  elseif selected.type == "passwordnohash" then
    ---@cast selected TampererSelection.PasswordNoHash
    local password = raw_password(self, selected.password_options, false)
    selected.value = password
  elseif selected.type == "passwordcallback" then
    ---@cast selected TampererSelection.PasswordCallback
    local correct = compare_password(self, selected)
    if correct then
      selected.callback()
    end
  elseif selected.type == "file" then
    ---@cast selected TampererSelection.File
    selected.value = read_file(self, selected.value) or selected.value
  elseif selected.type == "color" then
    ---@cast selected TampererSelection.Color
    selected.value = read_color(self, selected.value) or selected.value
  elseif selected.type == "callback" then
    ---@cast selected TampererSelection.Callback
    selected.value(self, selected)
    return false
  elseif selected.type == "submenu" then
    ---@cast selected TampererSelection.Submenu
    selected.value:run()
    return false
  elseif selected.type == "exit" then
    ---@cast selected TampererSelection.Exit
    -- Exit the current menu. This is handled by returning early and not calling on_change.
    return true
  else
    error("Invalid selection type: " .. tostring(selected.type), 2)
  end

  if self.on_change then
    self:on_change(selected)
  end

  return false
end



--- Runs the menu.
function Tamperer:run()
  if #self.selections == 0 then
    error("Cannot run menu with no selections.", 2)
  end

  local w, h = term.getSize()
  local max_selections = h - 9

  local key_callbacks = {
    [keys.up] = function()
      if self.state.selected_index > 1 then
        -- Select up one.
        self.state.selected_index = self.state.selected_index - 1
      elseif self.state.scroll_offset > 0 then
        -- Scroll up one.
        self.state.scroll_offset = self.state.scroll_offset - 1
      else
        -- Wrap to bottom
        if #self.selections > max_selections then
          self.state.scroll_offset = #self.selections - max_selections
          self.state.selected_index = max_selections
        else
          self.state.scroll_offset = 0
          self.state.selected_index = #self.selections
        end
      end
    end,
    [keys.down] = function()
      if self.state.selected_index < math.min(max_selections, #self.selections - self.state.scroll_offset) then
        -- Select down one.
        self.state.selected_index = self.state.selected_index + 1
      elseif self.state.scroll_offset + max_selections < #self.selections then
        -- Scroll down one.
        self.state.scroll_offset = self.state.scroll_offset + 1
      else
        -- Wrap to top
        self.state.scroll_offset = 0
        self.state.selected_index = 1
      end
    end,
    [keys.enter] = function()
      return self:select()
    end
  }
  key_callbacks[keys.w] = key_callbacks[keys.up]
  key_callbacks[keys.s] = key_callbacks[keys.down]
  key_callbacks[keys.space] = key_callbacks[keys.enter]


  self.state.selected_index = 1
  self.state.scroll_offset = 0
  while true do
    self:draw()
    local _, key = os.pullEvent("key")
    if key_callbacks[key] then
      if key_callbacks[key]() then
        break -- only break if the callback returns true, which only happens for "exit" type selections. This allows submenus to return here without exiting the entire menu.
      end
    end
  end
end



--- Adds a number input to the menu.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param value number? The initial value of the selection. Setting to `nil` will default to 0.
---@param minimum number? The minimum allowed value.
---@param maximum number? The maximum allowed value.
---@return TampererSelection.Number selection The newly added selection.
function Tamperer:add_number(i_label, display_label, description, value, minimum, maximum)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")
  expect(4, value, "number", "nil")

  ---@type TampererSelection.Number
  local selection = {
    type = "number",
    i_label = i_label,
    label = display_label,
    description = description,
    value = value or 0,
    display_value = "",
    minimum = minimum or -math.huge,
    maximum = maximum or math.huge,
  }
  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end


--- Adds a string input to the menu.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param value string? The initial value of the selection. Setting to `nil` will default to "".
---@param long boolean? Whether this is a "long string" input. Opens up an `edit` session when selected. Defaults to false.
---@param minimum_length number? The minimum allowed length of the string.
---@param maximum_length number? The maximum allowed length of the string.
---@return TampererSelection.String selection The newly added selection.
function Tamperer:add_string(i_label, display_label, description, value, long, minimum_length, maximum_length)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")
  expect(4, value, "string", "nil")
  expect(5, long, "boolean", "nil")

  ---@type TampererSelection.String
  local selection = {
    type = long and "longstring" or "string",
    i_label = i_label,
    label = display_label,
    description = description,
    value = value or "",
    display_value = "",
    minimum_length = minimum_length,
    maximum_length = maximum_length,
  }
  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end



--- Adds a boolean (true/false) toggle to the menu.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param value boolean? The initial value of the selection. Setting to `nil` will default to false.
---@return TampererSelection.Boolean selection The newly added selection.
function Tamperer:add_boolean(i_label, display_label, description, value)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")
  expect(4, value, "boolean", "nil")

  ---@type TampererSelection.Boolean
  local selection = {
    type = "boolean",
    i_label = i_label,
    label = display_label,
    description = description,
    value = value or false,
    display_value = "",
  }
  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end



--- Adds a list option to the menu. Selecting it prompts the user to select from a list of options.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param options string[] The list of options.
---@param value integer? The initial index of the selection. Setting to `nil` will default to 1.
---@return TampererSelection.List selection The newly added selection.
function Tamperer:add_list(i_label, display_label, description, options, value)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")
  expect(4, options, "table")
  expect(5, value, "number", "nil")

  for i, option in ipairs(options) do
    if type(option) ~= "string" then
      error(("Invalid option %d: expected string, got %s"):format(i, type(option)), 2)
    end
  end
  if #options == 0 then
    error("Lists must have at least one option.", 2)
  end

  ---@type TampererSelection.List
  local selection = {
    type = "list",
    i_label = i_label,
    label = display_label,
    description = description,
    value = value or 1,
    display_value = "",
    options = options,
  }
  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end



--- Adds a callback to the menu. Selecting it will run the given callback function.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param callback fun(self: Tamperer, selection: TampererSelection) The callback function to run when selected.
---@return TampererSelection.Callback selection The newly added selection.
function Tamperer:add_callback(i_label, display_label, description, callback)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")
  expect(4, callback, "function")

  ---@type TampererSelection.Callback
  local selection = {
    type = "callback",
    i_label = i_label,
    label = display_label,
    description = description,
    value = callback,
    display_value = "",
  }
  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end



--- Adds a submenu to the menu. Selecting it will call `:run()` on the given submenu.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param submenu Tamperer The submenu instance.
---@return TampererSelection.Submenu selection The newly added selection.
function Tamperer:add_submenu(i_label, display_label, description, submenu)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")
  expect(4, submenu, "table")

  ---@type TampererSelection.Submenu
  local selection = {
    type = "submenu",
    i_label = i_label,
    label = display_label,
    description = description,
    value = submenu,
    display_value = "",
  }
  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end



--- Pushes password options into a selection.
---@param selection TampererSelection.Password|TampererSelection.PasswordNoHash|TampererSelection.PasswordCallback The selection to push options into.
---@param password_options TampererPasswordOptions? The PBKDF2 options to use.
local function push_options(selection, password_options)
  if not password_options then
    return
  end
  selection.password_options.hashing.iterations = password_options.hashing and password_options.hashing.iterations or PBKDF2_ITERATIONS
  selection.password_options.hashing.salt_length = password_options.hashing and password_options.hashing.salt_length or PBKDF2_SALT_LENGTH
  selection.password_options.requirements.require_uppercase = password_options.requirements and password_options.requirements.require_uppercase or false
  selection.password_options.requirements.require_lowercase = password_options.requirements and password_options.requirements.require_lowercase or false
  selection.password_options.requirements.require_number = password_options.requirements and password_options.requirements.require_number or false
  selection.password_options.requirements.require_special = password_options.requirements and password_options.requirements.require_special or false
  selection.password_options.requirements.disallowed_characters = password_options.requirements and password_options.requirements.disallowed_characters or ""
  selection.password_options.requirements.min_length = password_options.requirements and password_options.requirements.min_length or -math.huge
  selection.password_options.requirements.max_length = password_options.requirements and password_options.requirements.max_length or math.huge
end



--- Adds a password-setting field to the menu.
--- If `no_hash` is true, the password will be stored in plaintext (not recommended), and only requested once.
--- If `no_hash` is false or nil, the password will be hashed using PBKDF2, and requested twice for confirmation.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param no_hash boolean? Whether to store the password without hashing it. Defaults to false.
---@param password_options TampererPasswordOptions? Options for PBKDF2 hashing.
---@return TampererSelection.Password|TampererSelection.PasswordNoHash selection The newly added selection.
function Tamperer:add_password(i_label, display_label, description, no_hash, password_options)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")
  expect(4, no_hash, "boolean", "nil")
  expect(5, password_options, "table", "nil")

  ---@type TampererSelection.Password|TampererSelection.PasswordNoHash
  local selection = {
    type = no_hash and "passwordnohash" or "password",
    i_label = i_label,
    label = display_label,
    description = description,
    value = no_hash and "" or {hash = "", salt = ""},
    display_value = "",
    password_options = {
      hashing = {
        iterations = PBKDF2_ITERATIONS,
        salt_length = PBKDF2_SALT_LENGTH,
      },
      requirements = {
        require_uppercase = false,
        require_lowercase = false,
        require_number = false,
        require_special = false,
        disallowed_characters = "",
      }
    }
  }

  push_options(selection, password_options)

  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end



--- Adds a callback that requires the user to enter a correct password before executing.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param callback fun(self: Tamperer) The callback function to run when the password is correct.
---@param password_options TampererPasswordOptions? The PBKDF2 options to use.
---@return TampererSelection.PasswordCallback selection The newly added selection.
function Tamperer:add_password_protected_callback(i_label, display_label, description, callback, password_options)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")
  expect(4, callback, "function")
  expect(5, password_options, "table", "nil")

  ---@type TampererSelection.PasswordCallback
  local selection = {
    type = "passwordcallback",
    i_label = i_label,
    label = display_label,
    description = description,
    value = {hash = "", salt = ""},
    callback = callback,
    display_value = "",
    password_options = {
      hashing = {
        iterations = PBKDF2_ITERATIONS,
        salt_length = PBKDF2_SALT_LENGTH,
      },
      requirements = {
        require_uppercase = false,
        require_lowercase = false,
        require_number = false,
        require_special = false,
        disallowed_characters = "",
      }
    }
  }

  push_options(selection, password_options)

  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end



--- Adds a file path input to the menu. Selecting it will open a file explorer.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param value string? The initial file path. Setting to `nil` will default to "" (root).
---@return TampererSelection.File selection The newly added selection.
function Tamperer:add_file(i_label, display_label, description, value)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")
  expect(4, value, "string", "nil")

  ---@type TampererSelection.File
  local selection = {
    type = "file",
    i_label = i_label,
    label = display_label,
    description = description,
    value = value or "",
    display_value = "",
  }
  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end



--- Adds a color input to the menu. Selecting it will prompt the user to enter a color value via its integer value or its name.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param value integer? The initial color value. Setting to `nil` will default to `0` (black).
---@return TampererSelection.Color selection The newly added selection.
function Tamperer:add_color(i_label, display_label, description, value)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")
  expect(4, value, "number", "nil")

  ---@type TampererSelection.Color
  local selection = {
    type = "color",
    i_label = i_label,
    label = display_label,
    description = description,
    value = value or colors.black,
    display_value = "",
  }
  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end



--- Adds an exit option to the menu. Selecting it will exit the menu. If this is a submenu, it will return to the parent menu.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param display_label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@return TampererSelection.Exit selection The newly added selection.
function Tamperer:add_exit(i_label, display_label, description)
  expect(1, i_label, "string")
  expect(2, display_label, "string", "function")
  expect(3, description, "string", "function")

  ---@type TampererSelection.Exit
  local selection = {
    type = "exit",
    i_label = i_label,
    label = display_label,
    description = description,
    display_value = "",
  }
  display_value(selection)
  table.insert(self.selections, selection)

  return selection
end



--- Sets the callback for when an option is changed.
---@param callback fun(self: Tamperer, selection: TampererSelection) The callback function.
---@return self self For method chaining.
function Tamperer:set_on_change(callback)
  expect(1, callback, "function")
  self.on_change = callback
  return self
end



return Tamperer