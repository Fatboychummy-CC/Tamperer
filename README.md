# Tamperer 2.0
Tamperer is a menu driver for ComputerCraft that allows you to create
interactive settings menus for your programs with ease.

> [!NOTE]
> This is a complete rewrite of the original Tamperer and as such is not
> compatible with the original version's table loading system.
>
> If you need the original version, you can find it
> [here](https://github.com/Fatboychummy-CC/Tamperer/tree/master).

## Features
- Easy to use API for creating menus and settings.
- Support for various input types (boolean, number, string, lists, files, and
  more).
- Customizable appearance.
- Navigation using keyboard.

## Usage
To use Tamperer in your ComputerCraft program, simply require the
`tamperer` module and create a new menu instance. You can then add settings
to the menu and display it to the user.

In order to catch changes to values, you can provide a callback function that
will be called whenever a value is changed.

```lua
local tamperer = require("tamperer")
local menu = tamperer.new("Main Menu")

menu:add_selection(
  "type_name",
  "internal_label",
  "Display Label",
  "Description of the setting.",
  "Default value"
)

menu:set_on_change(function(menu, selection)
  print("selection " .. selection.i_label .. " changed to " .. tostring(selection.value))
  print("selection is part of menu " .. menu.options.title)
end)

menu:run()
```

Valid types for `type_name` include:
- `boolean`
  - Pressing enter toggles the value between true and false.
- `number`
  - Pressing enter allows the user to input a number.
- `string`
  - Pressing enter allows the user to input a string.
- `longstring`
  - Pressing enter opens an editor for multi-line string input.
- `list`
  - Pressing enter opens a list browser.
- `file`
  - Pressing enter opens a file picker.
- `color`
  - Pressing enter allows the user to input a color value by name or by its
    integer code.
- `submenu`
  - Pressing enter opens a submenu.
- `password`
  - Pressing enter allows the user to input a string that is masked for privacy.
  - The value is requested twice, and must match both times.
  - The value is passed to `sha256.pbkdf2` before being emitted to `on_change`
    as a table of `{salt = <salt>, hash = <hash>}`.
  - 500 iterations are used for the PBKDF2 function, and a random 16-byte salt
  - is generated for each password input.
- `callback`
  - Pressing enter calls a callback function that you provide.
- `passwordcallback`
  - Pressing enter allows the user to input a string that is masked for privacy.
  - This is like `password`, but does not request it twice.
  - Upon a successful match, the callback is called.
  - This can be useful for making password-protected submenus.
  - The `on_change` callback is called *after* the user exits the submenu, so it
    can be used to detect when the user is leaving the elevated submenu. It is
    also called immediately after a failed input.

