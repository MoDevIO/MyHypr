import { createPoll } from "ags/time"
import { Gtk } from "ags/gtk4"
import { exec } from "ags/process"

const cpu = createPoll(
  " 0%",
  2000,
  ["bash", "-c", "top -bn1 | grep '%Cpu' | awk '{print $2}'"],
  (out) => {
    const val = parseFloat(out) || 0
    return ` ${val.toFixed(0)}%`
  },
)

const mem = createPoll(
  " 0%",
  3000,
  ["bash", "-c", "free -m | awk '/Mem:/{printf \"%.0f\", $3/$2*100}'"],
  (out) => {
    const val = parseFloat(out) || 0
    return ` ${val}%`
  },
)

const vol = createPoll(
  "󰕾 0%",
  300,
  ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
  (out) => {
    const match = out.match(/Volume:\s+([\d.]+)/)
    const pct = match ? Math.round(parseFloat(match[1]) * 100) : 0
    const muted = out.includes("[MUTED]")
    const icon = muted ? "󰝟" : pct > 60 ? "󰕾" : pct > 30 ? "󰖀" : "󰕿"
    return `${icon} ${pct}%`
  },
)

// Animated sys-info label: gentle pulse on value change
function SysLabel({ binding }: { binding: any }) {
  return (
    <label
      cssClasses={["sys-label"]}
      label={binding}
      $={(self) => {
        let animating = false
        self.connect("notify::label", () => {
          if (animating) return
          animating = true
          const duration = 400
          const fps = 60
          const stepTime = 1000 / fps
          const totalSteps = Math.ceil(duration / stepTime)
          let step = 0
          const timer = setInterval(() => {
            step++
            const t = Math.min(step / totalSteps, 1)
            self.opacity = 1 - 0.3 * Math.sin(t * Math.PI)
            if (t >= 1) {
              clearInterval(timer)
              animating = false
            }
          }, stepTime)
        })
      }}
    />
  )
}

// Volume section with slider on hover
function VolumeControl() {
  return (
    <box
      spacing={0}
      valign={Gtk.Align.CENTER}
      $={(self) => {
        const hover = new Gtk.EventControllerMotion()
        let rev: Gtk.Revealer | null = null

        const findRevealer = () => {
          if (rev) return rev
          let child = self.get_first_child()
          while (child) {
            if (child instanceof Gtk.Revealer) {
              rev = child as Gtk.Revealer
              return rev
            }
            child = child.get_next_sibling()
          }
          return null
        }

        hover.connect("enter", () => {
          const r = findRevealer()
          if (r) r.revealChild = true
        })
        hover.connect("leave", () => {
          const r = findRevealer()
          if (r) r.revealChild = false
        })
        self.add_controller(hover)
      }}
    >
      <SysLabel binding={vol} />
      <revealer
        revealChild={false}
        transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
        transitionDuration={250}
      >
        <slider
          cssClasses={["vol-slider"]}
          valign={Gtk.Align.CENTER}
          hexpand={false}
          widthRequest={100}
          value={vol((v) => {
            const match = v.match(/(\d+)%/)
            return match ? parseInt(match[1]) / 100 : 0
          })}
          $={(self) => {
            self.connect("notify::value", () => {
              const pct = Math.round(self.get_value() * 100)
              try {
                exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", `${pct}%`])
              } catch {}
            })
          }}
        />
      </revealer>
    </box>
  )
}

export default function SysInfo() {
  return (
    <box spacing={4} valign={Gtk.Align.CENTER}>
      <SysLabel binding={cpu} />
      <box cssClasses={["bar-sep"]} valign={Gtk.Align.CENTER} />
      <SysLabel binding={mem} />
      <box cssClasses={["bar-sep"]} valign={Gtk.Align.CENTER} />
      <VolumeControl />
    </box>
  )
}
