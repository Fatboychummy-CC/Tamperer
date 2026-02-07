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
To use Tamperer in your program, simply require the
`tamperer` module and create a new menu instance. You can then add settings
to the menu and display it to the user.

In order to catch changes to values, you can provide a callback function that
will be called whenever a value is changed.

```lua
local tamperer = require("tamperer")
local menu = tamperer.new("Main Menu")

menu:add_number("volume", "Volume", "Volume of the music", 50, 0, 100)
menu:add_boolean("fullscreen", "Fullscreen", "Enable fullscreen mode", false)
-- ...

menu:set_on_change(function(menu, selection)
  print("selection " .. selection.i_label .. " changed to " .. tostring(selection.value))
  print("selection is part of menu " .. menu.options.title)
end)

menu:run()
```

See the [wiki](https://github.com/Fatboychummy-CC/Tamperer/wiki/) for detailed
documentation and guides on using Tamperer. The wiki is still under construction,
but contains a full reference page for all Tamperer methods and objects.

