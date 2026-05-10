import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import Clock from "./Clock"
import Music from "./Music"
import Workspaces from "./Workspaces"
import SysInfo from "./SysInfo"

const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

// ── Intro animation ─────────────────────────────────────
// Islands start invisible and pushed toward center, then
// animate outward smoothly using programmatic property changes.

function introSetup(self: Gtk.Widget, direction?: "left" | "right") {
  const startMargin = 800
  const duration = 500
  const fps = 60
  const stepTime = 1000 / fps
  const totalSteps = Math.ceil(duration / stepTime)

  // Set initial hidden state
  self.opacity = 0
  if (direction === "left") self.marginStart = startMargin
  if (direction === "right") self.marginEnd = startMargin

  // Side islands start immediately, center island starts slightly later
  const delay = direction ? 100 : 250

  // Wait for widget to be painted, then animate
  setTimeout(() => {
    let step = 0
    const timer = setInterval(() => {
      step++
      const t = Math.min(step / totalSteps, 1)
      // Ease-out cubic: fast start, gentle end
      const eased = 1 - Math.pow(1 - t, 3)

      self.opacity = eased
      if (direction === "left")
        self.marginStart = Math.round(startMargin * (1 - eased))
      if (direction === "right")
        self.marginEnd = Math.round(startMargin * (1 - eased))

      if (t >= 1) clearInterval(timer)
    }, stepTime)
  }, delay)
}

// Monitor 1 (DP-1): workspaces 1–5
const M1_IDS = [1, 2, 3, 4, 5]

// Monitor 2 (HDMI-A-1): workspaces 6–10, displayed as 1–5
const M2_IDS = [6, 7, 8, 9, 10]

function getMonitorByConnector(connector: string) {
  return app.monitors.find((monitor) => monitor.get_connector() === connector)
}

function getSecondaryMonitors() {
  return app.monitors.filter((monitor) => monitor.get_connector() !== "DP-1")
}

export function MainBar() {
  const mainMonitor = getMonitorByConnector("DP-1")
  if (!mainMonitor) return null

  return (
    <window
      visible
      gdkmonitor={mainMonitor}
      anchor={TOP | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      layer={Astal.Layer.TOP}
      marginTop={10}
      marginBottom={0}
      cssClasses={["bar"]}
      application={app}
    >
      <centerbox
        startWidget={
          <box
            halign={Gtk.Align.START}
            cssClasses={["bar-island"]}
            $={(self) => introSetup(self, "left")}
          >
            <Workspaces ids={M1_IDS} />
            <Music />
          </box>
        }
        centerWidget={
          <box cssClasses={["bar-island"]} $={(self) => introSetup(self)}>
            <Clock />
          </box>
        }
        endWidget={
          <box
            halign={Gtk.Align.END}
            cssClasses={["bar-island"]}
            $={(self) => introSetup(self, "right")}
          >
            <SysInfo />
          </box>
        }
      />
    </window>
  )
}

export function SecondaryBar() {
  const secondaryMonitor = getMonitorByConnector("HDMI-A-1")
  if (!secondaryMonitor) return null

  return (
    <window
      visible
      gdkmonitor={secondaryMonitor}
      anchor={TOP | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      layer={Astal.Layer.TOP}
      marginTop={10}
      marginBottom={0}
      cssClasses={["bar"]}
      application={app}
    >
      <centerbox
        startWidget={
          <box
            halign={Gtk.Align.START}
            cssClasses={["bar-island"]}
            $={(self) => introSetup(self, "left")}
          >
            <Workspaces ids={M2_IDS} displayOffset={5} />
          </box>
        }
      />
    </window>
  )
}
