import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"

const time = createPoll("", 1000, "date '+%H:%M:%S'")
const dateStr = createPoll("", 60000, "date '+%a %b %d'")

export default function Clock() {
  return (
    <box halign={Gtk.Align.START} spacing={8}>
      <label cssClasses={["clock"]} label={time} />
      <label cssClasses={["date"]} label={dateStr} />
    </box>
  )
}
