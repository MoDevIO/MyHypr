import { Gdk, Gtk } from "ags/gtk4"
import GioUnix from "gi://GioUnix"
import { createPoll } from "ags/time"
import { exec } from "ags/process"

// ── Icon resolution ──────────────────────────────────────

/** Fallback icon when nothing else matches */
const FALLBACK_ICON = "application-x-executable"

/** Cache so we only resolve each window class once */
const iconCache = new Map<string, string>()

/**
 * Resolve a Hyprland window class to the application's own icon.
 *
 * Lookup chain:
 *   1. .desktop file Icon= field (the actual app icon)
 *   2. Window class name as icon (sometimes works)
 *   3. Generic fallback
 */
function resolveIcon(windowClass: string): string {
  if (iconCache.has(windowClass)) return iconCache.get(windowClass)!

  let result = FALLBACK_ICON

  try {
    const appInfo = GioUnix.DesktopAppInfo.new(`${windowClass}.desktop`)
    if (appInfo) {
      const icon = appInfo.get_string("Icon")
      result = icon ?? (windowClass || FALLBACK_ICON)
    } else {
      // No .desktop found – try class name directly (works for many apps)
      result = windowClass.toLowerCase() || FALLBACK_ICON
    }
  } catch {
    result = windowClass.toLowerCase() || FALLBACK_ICON
  }

  iconCache.set(windowClass, result)
  return result
}

// ── Workspace data types ─────────────────────────────────

interface WsState {
  actives: number[]
  occupied: number[]
  /** Map from workspace id -> symbolic icon name of the largest window */
  icons: Record<number, string>
}

// ── Polling ──────────────────────────────────────────────

const EMPTY_STATE: WsState = { actives: [1], occupied: [], icons: {} }

const wsData = createPoll<string>(
  JSON.stringify(EMPTY_STATE),
  100,
  [
    "bash",
    "-c",
    // Outputs three JSON blobs separated by a unique delimiter
    "echo \"$(hyprctl monitors -j)\"; echo '%%SPLIT%%'; echo \"$(hyprctl clients -j)\"; echo '%%SPLIT%%'; echo \"$(hyprctl workspaces -j)\"",
  ],
  (out) => {
    try {
      const parts = out.split("%%SPLIT%%")
      if (parts.length < 3) return JSON.stringify(EMPTY_STATE)

      const monitors: { activeWorkspace: { id: number } }[] = JSON.parse(parts[0].trim())
      const clients: { workspace: { id: number }; class: string; size: number[] }[] =
        JSON.parse(parts[1].trim())
      const workspaces: { id: number }[] = JSON.parse(parts[2].trim())

      const actives = monitors.map((m) => m.activeWorkspace.id)
      const occupied = workspaces.map((w) => w.id)

      // For each occupied workspace, find the largest window (by pixel area)
      const icons: Record<number, string> = {}
      for (const wsId of occupied) {
        const wsClients = clients.filter((c) => c.workspace.id === wsId)
        if (wsClients.length === 0) continue

        // Largest window = max width * height
        let largest = wsClients[0]
        let largestArea = largest.size[0] * largest.size[1]
        for (let i = 1; i < wsClients.length; i++) {
          const area = wsClients[i].size[0] * wsClients[i].size[1]
          if (area > largestArea) {
            largest = wsClients[i]
            largestArea = area
          }
        }

        icons[wsId] = resolveIcon(largest.class)
      }

      return JSON.stringify({ actives, occupied, icons } satisfies WsState)
    } catch (e) {
      console.error("[Workspaces] poll parse error:", e)
      return JSON.stringify(EMPTY_STATE)
    }
  },
)

// ── Widget ───────────────────────────────────────────────

function WsButton({ realId, displayId }: { realId: number; displayId: number }) {
  return (
    <button
      cursor={Gdk.Cursor.new_from_name("pointer", null)}
      cssClasses={wsData((ws) => {
        try {
          const d: WsState = JSON.parse(ws)
          if (d.actives.includes(realId)) return ["ws-btn", "ws-active"]
          if (d.occupied.includes(realId)) return ["ws-btn", "ws-occupied"]
          return ["ws-btn", "ws-empty"]
        } catch {
          return ["ws-btn", "ws-empty"]
        }
      })}
      onClicked={() => {
        try {
          exec(["hyprctl", "dispatch", "workspace", `${realId}`])
        } catch {}
      }}
    >
      <box cssClasses={["ws-inner"]} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        {/* App icon: shown on any workspace that has windows */}
        <image
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          pixelSize={22}
          iconName={wsData((ws) => {
            try {
              const d: WsState = JSON.parse(ws)
              return d.icons[realId] ?? FALLBACK_ICON
            } catch {
              return FALLBACK_ICON
            }
          })}
          visible={wsData((ws) => {
            try {
              const d: WsState = JSON.parse(ws)
              return !!d.icons[realId]
            } catch {
              return false
            }
          })}
        />
        {/* Workspace number: shown only on empty workspaces */}
        <label
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          label={`${displayId}`}
          cssClasses={["ws-number"]}
          visible={wsData((ws) => {
            try {
              const d: WsState = JSON.parse(ws)
              return !d.icons[realId]
            } catch {
              return true
            }
          })}
        />
      </box>
    </button>
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
