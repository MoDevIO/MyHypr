import { createPoll } from "ags/time"

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
  1000,
  ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
  (out) => {
    const match = out.match(/Volume:\s+([\d.]+)/)
    const pct = match ? Math.round(parseFloat(match[1]) * 100) : 0
    const muted = out.includes("[MUTED]")
    const icon = muted ? "󰝟" : pct > 60 ? "󰕾" : pct > 30 ? "󰖀" : "󰕿"
    return `${icon} ${pct}%`
  },
)

export default function SysInfo() {
  return (
    <box spacing={4}>
      <label cssClasses={["sys-label"]} label={cpu} />
      <label cssClasses={["sys-label"]} label={mem} />
      <label cssClasses={["sys-label"]} label={vol} />
    </box>
  )
}
