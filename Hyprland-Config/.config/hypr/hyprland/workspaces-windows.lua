-- Config: Workspaces --
for i = 1, 5 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = "DP-1",
    })
end
for i = 6, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = "HDMI-A-1",
    })
end

hl.workspace_rule({
    workspace = "special:spotify",
    gaps_out = 100,
    gaps_in = 20,
})
hl.workspace_rule({
    workspace = "special:beeper",
    gaps_out = 100,
    gaps_in = 20,
})

hl.workspace_rule({
    workspace = "50",
    monitor = "sunshine-mon",
})

-- Config: Windowrules --
hl.window_rule({
    match = {
        class = "zen"
    },
    workspace = "1",
})
hl.window_rule({
    match = {
        class = "code"
    },
    workspace = "2",
})
hl.window_rule({ --Rocket League
    match = {
        class = "steam_app_252950"
    },
    workspace = "3",
})

hl.window_rule({
    match = {
        class = "Spotify"
    },
    workspace = "special:spotify",
    opacity = "0.9 override",
})

hl.window_rule({
    match = {
        class = "beepertexts"
    },
    workspace = "special:beeper",
    opacity = "0.9 override",
})