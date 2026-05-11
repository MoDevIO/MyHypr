-- HYPRLAND CONFIG --



-- Config: ENV --
require("hyprland/environment")

-- Config: Monitors --
require("hyprland/monitors")

-- Config: Workspaces/Windows --
require("hyprland/workspaces-windows")

-- Config: Autostart --
require("hyprland/autostart")

--Config: Programs --
local programs = require("hyprland/programs")

-- Config: Keybinds --
require("hyprland/keybinds")(programs)

-- Config: Appearance --
require("hyprland/appearance")

-- Config: Input --
require("hyprland/input")