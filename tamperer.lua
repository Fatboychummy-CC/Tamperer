--- Mini Menu Library
--- Provides a simple menu system for user interaction.

local expect, field = (function()
  local e = require "cc.expect"
  return e.expect, e.field
end)()
local strings = require "cc.strings"
local sha256, random
local PBKDF2_ITERATIONS = 500
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
---@field options string[]? The list of options if type is 'list' or 'selection'.

---@class TampererListSelection : TampererSelection
---@field type "list"
---@field options string[] The list of options.



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
  if selection.type == "number" or selection.type == "string" or selection.type == "longstring" then
    selection.display_value = tostring(selection.value)
  elseif selection.type == "list" then
    selection.display_value = selection.options[selection.value] or "Invalid Option"
  elseif selection.type == "boolean" then
    selection.display_value = selection.value and "[ true ] false" or "  true [ false ]"
  elseif selection.type == "password" then
    selection.display_value = "pbkdf2"
  elseif selection.type == "file" then
    selection.display_value = selection.value or "No file selected"
  elseif selection.type == "color" then
    local color_code, color_name
    if type(selection.value) == "string" then
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
  else
    selection.display_value = ""
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
  random.initWithTiming()
end

--- Hash a password using SHA-256.
---@param password string The password to hash.
---@return string hash The hashed password.
---@return string salt The salt used in hashing.
local function hash_password(password)
  init_sha()

  local salt = random.random(8)
  local hash = sha256.pbkdf2(password, salt, PBKDF2_ITERATIONS)

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
---@param current number The current value.
---@return number value The read number.
local function read_number(self, current)
  local x, y = term.getCursorPos()
  local out

  repeat
    local input = read(nil, nil, nil, tostring(current)) --[[@as string]]
    out = tonumber(input)
    if not out then
      flash(x, y, "Not a number.", colors.red)
    end
  until out
  ---@cast out number

  return out
end



--- Reads a "long string"
--- This works by launching the builtin text editor with a temporary file.
---@param self Tamperer The menu instance.
---@param current string The current value.
---@return string value The read string.
local function read_longstring(self, current)
  fs.makeDir(TAMPERER_TEMP_DIR)
  local tmp_path = fs.combine(TAMPERER_TEMP_DIR, "longstring_" .. os.epoch("utc") .. "_" .. math.random(1000, 9999) .. ".txt")
  local file = fs.open(tmp_path, "w")
  if not file then
    error("Could not open temporary file for long string input.", 0)
  end
  file.write(current)
  file.close()

  local w, h = term.getSize()
  local win = window.create(term.current(), 3, 3, w - 4, h - 4)

  fancy_box(self, 2, 2, w - 2, h - 2)

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

  -- Run the editor.
  local old = term.redirect(win)
  shell.run("edit", tmp_path)
  term.redirect(old)

  -- Restore `shell.openTab` and `peripheral.find`.
  shell.openTab = old_open_tab
  peripheral.find = old_find

  local file = fs.open(tmp_path, "r")
  if not file then
    error("Could not open temporary file for long string input.", 0)
  end
  local content = file.readAll() --[[@as string]]
  file.close()

  fs.delete(TAMPERER_TEMP_DIR)

  return content
end



--- Read in a password.
---@param self Tamperer The menu instance.
---@return string? hash The hashed password.
---@return string? salt The salt used in hashing.
local function read_password(self)
  init_sha()

  local x, y = term.getCursorPos()
  term.setTextColor(colors.yellow)
  flash(x, y, "Enter password", colors.yellow)
  local password = read('\xb7') --[[@as string]]
  flash(x, y, "Confirm password", colors.yellow, 1.5)
  local confirm = read('\xb7') --[[@as string]]

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
  return hash_password(password)
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
  local x, y = 15, self.state.selected_index + 4
  term.setCursorPos(x, y)
  term.write((' '):rep(50))
  term.setCursorPos(x, y)

  if selected.type == "number" then
    selected.value = read_number(self, selected.value) or selected.value
  elseif selected.type == "string" then
    selected.value = read(nil, nil, nil, selected.value) or selected.value
  elseif selected.type == "longstring" then
    selected.value = read_longstring(self, selected.value) or selected.value
  elseif selected.type == "boolean" then
    selected.value = not selected.value
  elseif selected.type == "list" then
    selected.value = read_list(self, selected.options, selected.value) or selected.value
  elseif selected.type == "password" then
    local hash, salt = read_password(self)
    hash, salt = hash or selected.value and selected.value.hash, salt or selected.value and selected.value.salt
    selected.value = {hash = hash, salt = salt}
  elseif selected.type == "file" then
    selected.value = read_file(self, selected.value) or selected.value
  elseif selected.type == "color" then
    selected.value = read_color(self, selected.value) or selected.value
  elseif selected.type == "callback" then
    selected.value(self, selected)
    return false
  elseif selected.type == "submenu" then
    selected.value:run()
    return false
  elseif selected.type == "exit" then
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



local default_values = {
  number = 0,
  string = "",
  longstring = "",
  password = nil,
  boolean = false,
  list = 1,
  callback = function() end,
  submenu = nil,
  file = "",
  color = colors.white,
}

--- Add a selection to the menu.
---@param _type TampererTypes The type of the selection.
---@param i_label string The internal label for the selection. This label is meant for identifying the selection programmatically, and should be something easy to code around.
---@param label string|fun(self: TampererSelection): string The displayed label for the selection, or a function that returns it based off of the current state.
---@param description string|fun(self: TampererSelection): string The description for the selection, or a function that returns it based off of the current state.
---@param value any The initial value of the selection. Setting to `nil` will default to type-specific defaults.
---@param options string[]? The list of options if type is 'list'.
---@return self self For method chaining.
function Tamperer:add_selection(_type, i_label, label, description, value, options)
  value = value or default_values[_type]
  expect(1, _type, "string")
  expect(2, i_label, "string")
  expect(3, label, "string", "function")
  expect(4, description, "string", "function")
  -- expect(5, nuh uh)
  expect(5, options, "table", "nil")

  if _type == "list" then
    expect(6, options, "table")
    ---@cast options string[]
    for i, option in ipairs(options) do
      if type(option) ~= "string" then
        error(("Invalid option %d: expected string, got %s"):format(i, type(option)), 2)
      end
    end
    if #options == 0 then
      error("Lists must have at least one option.", 2)
    end
  elseif _type == "callback" then
    expect(5, value, "function")
  elseif _type == "submenu" then
    expect(5, value, "table", "nil")
  elseif _type == "number" then
    expect(5, value, "number")
  elseif _type == "string" then
    expect(5, value, "string")
  elseif _type == "boolean" then
    expect(5, value, "boolean")
  elseif _type == "longstring" then
    expect(5, value, "string")
  elseif _type == "password" then
    expect(5, value, "nil") -- Previous password should not be passed back to the reader in any way.
  elseif _type == "file" then
    expect(5, value, "string", "nil")
  elseif _type == "color" then
    expect(5, value, "number", "nil")
  elseif _type == "exit" then
    -- Do nothing, exit type doesn't need a value or options.
  else
    error("Invalid selection type: " .. tostring(_type), 2)
  end

  local selection = {
    type = _type,
    i_label = i_label,
    label = label,
    description = description,
    value = value or default_values[_type],
    display_value = "",
    options = options,
  }
  display_value(selection)
  table.insert(self.selections, selection)

  return self
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