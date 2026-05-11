local function keybinds(programs)

    -- Config: Keybinds --
    hl.bind("SUPER + C", hl.dsp.window.close())
    hl.bind("SUPER + Q", hl.dsp.exec_cmd(programs.terminal))
    hl.bind("SUPER + E", hl.dsp.exec_cmd(programs.fileManager))
    hl.bind("SUPER + R", hl.dsp.exec_cmd(programs.menu))
    hl.bind("SUPER + B", hl.dsp.exec_cmd(programs.browser))
    hl.bind("SUPER + G", hl.dsp.exec_cmd(programs.codeEditor))
    hl.bind("SUPER + N", hl.dsp.exec_cmd(programs.notificationPanel))

    hl.bind("SUPER + S", function ()
        hl.dispatch(hl.dsp.exec_cmd(programs.musicPlayer))
        hl.dispatch(hl.dsp.workspace.toggle_special("spotify"))
    end)
    hl.bind("SUPER + T", function ()
        hl.dispatch(hl.dsp.exec_cmd(programs.messagingApp))
        hl.dispatch(hl.dsp.workspace.toggle_special("beeper"))
    end)


    hl.bind("SUPER + M", hl.dsp.exit())
    hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd(programs.reloadMybar))
    hl.bind("SUPER + ALT + SPACE" , hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/movewindowtomouse.sh"))

    hl.bind("SUPER + left",  hl.dsp.focus({ direction = "left" }))
    hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
    hl.bind("SUPER + up",    hl.dsp.focus({ direction = "up" }))
    hl.bind("SUPER + down",  hl.dsp.focus({ direction = "down" }))
    hl.bind("SUPER + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
    hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
    hl.bind("SUPER + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
    hl.bind("SUPER + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

    hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
    hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
    hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

    for i = 1, 5 do
        hl.bind("SUPER + " .. tostring(i), hl.dsp.focus({ workspace = tonumber(i) }))
        hl.bind("SUPER + SHIFT + " .. tostring(i), hl.dsp.window.move({ workspace = tonumber(i) }))

        hl.bind("SUPER + CONTROL + " .. tostring(i), hl.dsp.focus({ workspace = tonumber(i)+5 }))
        hl.bind("SUPER + CONTROL + SHIFT + " .. tostring(i), hl.dsp.window.move({ workspace = tonumber(i)+5 }))
    end
    hl.bind("SUPER + 0", hl.dsp.focus({ workspace = 50 }))
    hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = 50 }))


    require("hyprland/gkeys")

end

return keybinds