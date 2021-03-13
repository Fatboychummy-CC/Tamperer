# Tamperer has been marked for rewrite.
I like a lot of things about Tamperer, but I extremely dislike a lot more things about it. A large amount of things have been just "bodged" into place, whilst other things are a lot better. Error checking the files is also a hastle, and I feel I could have done that much better.

I also wish to add a way to build pages at runtime a lot more easily. For example, using methods such as:

```lua
local setting = Page:AddSetting("setting.subsetting.name", "Display Name", "Long Info", "Setting Type", function() someCallbackOnSettingChange() end)
local selection = Page:AddSelection("Display Name", "Info", "Big Info")
local subPage = Page:AddSubPage("Display Name", "Info", "Big Info")
local button = Page:AddButton("Display Name", "Info", "Big Info", function() someCallbackOnPressed() end)
Page:Final("Exit", "Go back to the previous page"
```

The code is also generally just a mess.

# Tamperer
Tamperer allows you to make quick settings menus with support for strings, numbers, booleans, and colors.  Supports subpages as well.

Hop over to the [wiki](https://github.com/Fatboychummy-CC/Tamperer/wiki) to get started!

# Credits:
* Anavrins
  * Created the sha256 api I used for storing passwords.
* Dan200/Squiddev
  * Creator, and current maintainer of Computercraft.  Thanks for your hard work!
