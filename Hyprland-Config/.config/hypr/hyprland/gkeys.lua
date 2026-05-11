local keyboard_G1 = "code:191" -- G1 key on Logitech G-keys
local keyboard_G2 = "code:192" -- G2 key on Logitech G-keys
local keyboard_G3 = "code:193" -- G3 key on Logitech G-keys
local keyboard_G4 = "code:194" -- G4 key on Logitech G-keys
local keyboard_G5 = "code:195" -- G5 key on Logitech G-keys

local mouse_G1 = "code:196" -- Top mouse button
local mouse_G2 = "code:197" -- DPI-Shift button
local mouse_G3 = "code:200" -- Front side mouse button
local mouse_G4 = "code:199" -- Back side mouse button


local gkey_actions = {
    default = {
        MG2 = "super+r",
    },

    ["zen"] = {
        G1 = "ctrl+t",
        G2 = "ctrl+w",
        G3 = "ctrl+shift+t",
        G4 = "ctrl+shift+tab",
        G5 = "ctrl+tab",

        MG3 = "alt+right",
        MG4 = "alt+left",
    },
    ["org.gnome.Nautilus"] = {
        MG3 = "alt+right",
        MG4 = "alt+left",
    },
    ["code"] = {
        G1 = "ctrl+b",
        G2 = "ctrl+j",
        G5 = "ctrl+alt+shift+p",
    },
    ["kitty"] = {
        G1 = "ctrl+shift+t",
        G2 = "ctrl+shift+w",
    },
}




local function custom_gkey_action(gkey)
    return function()
        local window_class = hl.get_active_window().class

        local action = nil

        if gkey_actions[window_class] and gkey_actions[window_class][gkey] then
            action = gkey_actions[window_class][gkey]

        else if gkey_actions["default"] and gkey_actions["default"][gkey] then
            action = gkey_actions["default"][gkey] end
        end

        if action then
            hl.dispatch(hl.dsp.exec_cmd("echo key '" .. action .. "' | dotoolc"))
        end
    end
end

hl.bind(keyboard_G1, custom_gkey_action("G1"))
hl.bind(keyboard_G2, custom_gkey_action("G2"))
hl.bind(keyboard_G3, custom_gkey_action("G3"))
hl.bind(keyboard_G4, custom_gkey_action("G4"))
hl.bind(keyboard_G5, custom_gkey_action("G5"))
hl.bind(mouse_G1, custom_gkey_action("MG1"))
hl.bind(mouse_G2, custom_gkey_action("MG2"))
hl.bind(mouse_G3, custom_gkey_action("MG3"))
hl.bind(mouse_G4, custom_gkey_action("MG4"))