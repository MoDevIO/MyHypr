import { Gdk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { exec } from "ags/process"

// Poll returns colon-separated string: "activeIds:occupiedIds"
// actives = workspace active on EACH monitor (not just the focused one)
const wsData = createPoll(
  '{"actives":[1],"occupied":[]}',
  100,
  [
    "bash",
    "-c",
    "echo \"$(hyprctl monitors -j | tr -d '\\n' | grep -oP '\"activeWorkspace\":\\s*\\{[^}]*\\}' | grep -oP '\"id\":\\s*\\K[0-9]+' | tr '\\n' ','):$(hyprctl workspaces -j | grep -o '\"id\": *[0-9]*' | grep -o '[0-9]*' | tr '\\n' ',')\"",
  ],
  (out) => {
    try {
      const [activesStr, occupiedStr] = out.split(":")
      const actives = activesStr.split(",").filter(Boolean).map(Number)
      const occupied = occupiedStr.split(",").filter(Boolean).map(Number)
      return JSON.stringify({ actives, occupied })
    } catch {
      return JSON.stringify({ actives: [1], occupied: [] })
    }
  },
)

function WsButton({ realId, displayId }: { realId: number; displayId: number }) {
  return (
    <button
      cursor={Gdk.Cursor.new_from_name("pointer", null)}
      cssClasses={wsData((ws) => {
        try {
          const d = JSON.parse(ws)
          if (d.actives.includes(realId)) return ["ws-btn", "ws-active"]
          if (d.occupied.includes(realId)) return ["ws-btn", "ws-occupied"]
          return ["ws-btn", "ws-empty"]
        } catch {
          return ["ws-btn", "ws-empty"]
        }
      })}
      label={`${displayId}`}
      onClicked={() => {
        try {
          exec(["hyprctl", "dispatch", "workspace", `${realId}`])
        } catch {}
      }}
    />
  )
}

export default function Workspaces({
  ids,
  displayOffset = 0,
}: {
  ids: number[]
  displayOffset?: number
}) {
  return (
    <box spacing={4}>
      {ids.map((realId) => (
        <WsButton realId={realId} displayId={realId - displayOffset} />
      ))}
    </box>
  )
}
