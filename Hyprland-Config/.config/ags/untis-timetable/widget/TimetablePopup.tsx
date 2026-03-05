import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { exec } from "ags/process"

function getFocusedMonitor(): Gdk.Monitor {
  try {
    const out = exec(["hyprctl", "activeworkspace", "-j"])
    const ws = JSON.parse(out)
    const name = ws.monitor as string
    const found = app.monitors.find((m) => m.get_connector() === name)
    if (found) return found
  } catch (_) {
    // fallback below
  }
  return app.monitors[0]
}

export default function TimetablePopup() {
  const keyCtrl = new Gtk.EventControllerKey()
  keyCtrl.connect(
    "key-pressed",
    (_ctrl: Gtk.EventControllerKey, keyval: number) => {
      if (keyval === Gdk.KEY_Escape) app.quit()
      return false
    },
  )

  const gdkmonitor = getFocusedMonitor()

  return (
    <window
      visible
      cssClasses={["TimetablePopup"]}
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.ON_DEMAND}
      $={(self) => self.add_controller(keyCtrl)}
    >
      <Astal.Box
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
        cssClasses={["popup-container"]}
        vertical
      >
        {/* Header */}
        <Astal.Box cssClasses={["popup-header"]}>
          <label
            label="📅 Untis Timetable"
            cssClasses={["popup-title"]}
            hexpand
            halign={Gtk.Align.START}
          />
          <button cssClasses={["popup-close"]} onClicked={() => app.quit()}>
            <label label="✕" />
          </button>
        </Astal.Box>

        {/* Placeholder content */}
        <Astal.Box cssClasses={["popup-body"]} vertical hexpand vexpand>
          <label
            label="Your timetable will appear here."
            cssClasses={["popup-placeholder"]}
            vexpand
            valign={Gtk.Align.CENTER}
            halign={Gtk.Align.CENTER}
          />
        </Astal.Box>
      </Astal.Box>
    </window>
  )
}
