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

## Installation
Run the installer script to download Tamperer and its dependencies.

> [!IMPORTANT]
> Tamperer 2.0 requires `ccryptolib` for password hashing functionality. The
> installer will ask if you want to install it alongside Tamperer. If you choose
> not to install it, password-related features will not work.

**Installation Command**
```
wget run https://raw.githubusercontent.com/Fatboychummy-CC/Tamperer/refs/heads/better/installer.lua
```

**Forgot CCryptolib? Install manually with**
```
wget run https://raw.githubusercontent.com/Fatboychummy-CC/etc-programs/refs/heads/main/installers/ccryptolib.lua
```

## Usage
To use Tamperer in your ComputerCraft program, simply require the
`tamperer` module and create a new menu instance. You can then add settings
to the menu and display it to the user.

In order to catch changes to values, you can provide a callback function that
will be called whenever a value is changed.

> [!WARNING]
> If you are planning to use this library in its current state, please be aware
> that it is still in active development, and `menu:add_selection` wil likely
> be replaced with a more robust and specific system (i.e: `menu:add_boolean`,
> `menu:add_number`, etc). The current system is a placeholder to allow for
> quick testing without needing the entire backend to be finished first.

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
  - Pressing enter opens the builtin `edit` program for multi-line string input.
  - You must *save* and *exit* the editor for the value to be accepted.
- `list`
  - Pressing enter opens a list browser.
  - Controls:
    - Up/Down arrows or W/S to navigate the list.
    - Enter/spacebar to select an item.
- `file`
  - Pressing enter opens a file picker.
  - Up/Down arrows or W/S to navigate the list.
  - Enter/spacebar to select an item.
  - Backspace/a/q/left-arrow to go back to the previous menu.
  - d/right-arrow to descend into a submenu if the item has one.
    - Only directories can be descended into, they are marked by an arrow at the
      right.
- `color`
  - Pressing enter allows the user to input a color value by name or by its
    integer code.
  - You can use any of the standard ComputerCraft color names or codes.
    - For example, `lightgray` or `8` for light gray.
- `submenu`
  - Pressing enter opens a submenu.
  - Ensure this submenu has an `exit` type selection to allow the user to go
    back.
- `password`
  - Pressing enter allows the user to input a string that is masked for privacy.
  - The value is requested twice, and must match both times.
  - The value is passed to `sha256.pbkdf2` before being emitted to `on_change`
    as a table of `{salt = <salt>, hash = <hash>}`.
  - 500 iterations are used for the PBKDF2 function, and a random 16-byte salt
  - is generated for each password input.
  - This method requires `ccryptolib` to be installed.
- `passwordnohash`
  - Pressing enter allows the user to input a string that is masked for privacy.
  - The value is requested twice, and must match both times.
  - The raw string value is emitted to `on_change`.
  - This is not recommended unless you have a specific reason to avoid hashing.
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
    - This method requires `ccryptolib` to be installed.

