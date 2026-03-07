import { createPoll } from "ags/time"
import { Gtk, Gdk } from "ags/gtk4"
import { exec } from "ags/process"

const musicInfo = createPoll(
  "",
  2000,
  [
    "bash",
    "-c",
    "playerctl metadata --format '{{artist}} — {{title}}' 2>/dev/null || echo ''",
  ],
  (out) => {
    if (!out || out.includes("No players found")) return ""
    const clean = out
      .replace(/[^\p{L}\p{N}\s\-—–_.,:;!?'"()&/\\@#]/gu, "")
      .trim()
    if (!clean) return ""
    const track = clean.length > 40 ? clean.slice(0, 37) + "…" : clean
    return `${track}`
  },
)

export default function Music() {
  return (
    <box spacing={0} valign={Gtk.Align.CENTER}>
      {/* Separator */}
      <box
        cssClasses={["bar-sep"]}
        valign={Gtk.Align.CENTER}
        visible={musicInfo((m) => m.length > 0)}
      />
      {/* Music label — left-click: play/pause, right-click: next, middle-click: previous */}
      <label
        cssClasses={["music-label"]}
        label={musicInfo}
        visible={musicInfo((m) => m.length > 0)}
        cursor={Gdk.Cursor.new_from_name("pointer", null)}
        $={(self) => {
          // Click gesture for left / middle / right
          const click = new Gtk.GestureClick()
          click.set_button(0) // listen to all buttons
          click.connect(
            "released",
            (_gesture: Gtk.GestureClick, _n: number) => {
              const btn = click.get_current_button()
              try {
                if (btn === 1)
                  exec(["playerctl", "play-pause"]) // Left click
                else if (btn === 2)
                  exec(["playerctl", "previous"]) // Middle click
                else if (btn === 3) exec(["playerctl", "next"]) // Right click
              } catch {}
            },
          )
          self.add_controller(click)

          // Track-change pulse animation
          let animating = false
          self.connect("notify::label", () => {
            if (animating) return
            animating = true
            const duration = 600
            const fps = 60
            const stepTime = 1000 / fps
            const totalSteps = Math.ceil(duration / stepTime)
            let step = 0
            const timer = setInterval(() => {
              step++
              const t = Math.min(step / totalSteps, 1)
              self.opacity = 1 - 0.4 * Math.sin(t * Math.PI)
              if (t >= 1) {
                clearInterval(timer)
                animating = false
              }
            }, stepTime)
          })
        }}
      />
    </box>
  )
}
