local programs = {}

programs.terminal = "kitty"
programs.fileManager = "nautilus --new-window"
programs.menu = "wofi --show drun --no-actions"
programs.browser = "zen-browser"
programs.codeEditor = "code"
programs.messagingApp = "beeper"
programs.musicPlayer = "spotify"
programs.notificationPanel = "swaync-client -t"
programs.reloadMybar = "systemctl --user restart mybar.service"

return programs