import { Gdk, Gtk } from "ags/gtk4"
import Gio from "gi://Gio"
import GioUnix from "gi://GioUnix"
import { createPoll } from "ags/time"
import { exec } from "ags/process"

// ── Icon resolution ──────────────────────────────────────

/** Fallback icon when nothing else matches */
const FALLBACK_ICON = "application-x-executable"

/** Cache so we only resolve each window class once */
const iconCache = new Map<string, string>()

/** Extract the Icon= value from a DesktopAppInfo, or null */
function getDesktopIcon(appInfo: GioUnix.DesktopAppInfo | null): string | null {
  if (!appInfo) return null
  try {
    return appInfo.get_string("Icon") || null
  } catch {
    return null
  }
}

/** Try to load a DesktopAppInfo by its desktop-id and return its icon */
function tryDesktopId(id: string): string | null {
  try {
    return getDesktopIcon(GioUnix.DesktopAppInfo.new(id))
  } catch {
    return null
  }
}

/**
 * Resolve a Hyprland window to the best matching icon.
 *
 * Lookup chain (mirrors what rofi / app launchers do):
 *   0. User-defined overrides (ICON_OVERRIDES map)
 *   1. Exact .desktop file by class name (+ lowercase variant)
 *   2. DesktopAppInfo.search()  — same fuzzy engine rofi uses
 *   3. Scan all desktop files for a matching StartupWMClass
 *   4. Check if the class name itself is a valid icon-theme name
 *   5. Generic fallback
 *
 * The function tries every identifier (class, initialClass, title)
 * until one succeeds.
 */

/**
 * Manual overrides: map a Hyprland window class (lowercase) → icon name.
 * Use this for apps whose window class can't be resolved automatically
 * (e.g. Chromium web-app shortcuts that all share the "chromium" class).
 *
 * Example:  "chromium" → "youtube"  (if you only run one Chromium web app)
 *
 * For multiple Chromium web apps, set --class=<name> in the .desktop Exec
 * line so each app gets its own WM class.
 */
const ICON_OVERRIDES: Record<string, string> = {
  // "chromium": "youtube",
}

function resolveIcon(windowClass: string, initialClass?: string, title?: string): string {
  // Build a cache key from all identifiers
  const cacheKey = `${windowClass}|${initialClass ?? ""}|${title ?? ""}`
  if (iconCache.has(cacheKey)) return iconCache.get(cacheKey)!

  // Check user overrides first (by class, then initialClass)
  const lcClass = windowClass.toLowerCase()
  if (ICON_OVERRIDES[lcClass]) {
    iconCache.set(cacheKey, ICON_OVERRIDES[lcClass])
    return ICON_OVERRIDES[lcClass]
  }
  if (initialClass && ICON_OVERRIDES[initialClass.toLowerCase()]) {
    const ov = ICON_OVERRIDES[initialClass.toLowerCase()]
    iconCache.set(cacheKey, ov)
    return ov
  }

  // Collect candidate identifiers to try (most specific first)
  // Chromium/Chrome web-app windows have classes like "chrome-www.youtube.com__-Default"
  // or "chromium-browser". For web-apps (class contains a URL), try the title first
  // so we match the app's own .desktop file instead of the generic browser icon.
  const isWebApp = /^chrom(e|ium)-.*\..*__/.test(windowClass)

  const candidates: string[] = []
  if (isWebApp && title) {
    // For web apps, title is the best identifier (e.g. "YouTube")
    candidates.push(title)
  }
  candidates.push(windowClass)
  if (initialClass && initialClass !== windowClass) candidates.push(initialClass)
  if (!isWebApp && title) candidates.push(title)

  for (const candidate of candidates) {
    if (!candidate) continue
    const lc = candidate.toLowerCase()
    let icon: string | null = null

    // 1. Direct desktop-id lookup (exact + lowercase)
    icon = tryDesktopId(`${candidate}.desktop`)
      ?? tryDesktopId(`${lc}.desktop`)

    // 2. DesktopAppInfo.search() – the same engine rofi uses for fuzzy matching
    if (!icon) {
      try {
        const results = GioUnix.DesktopAppInfo.search(candidate)
        if (results && results.length > 0) {
          // Only take the top (best-scoring) group
          for (const id of results[0]) {
            icon = tryDesktopId(id)
            if (icon) break
          }
        }
      } catch {}
    }

    // 3. Scan all installed apps for a matching StartupWMClass
    if (!icon) {
      try {
        const allApps = Gio.AppInfo.get_all()
        for (const app of allApps) {
          try {
            const dApp = app as unknown as GioUnix.DesktopAppInfo
            const wmClass = dApp.get_string("StartupWMClass")
            if (wmClass && wmClass.toLowerCase() === lc) {
              icon = getDesktopIcon(dApp)
              if (icon) break
            }
          } catch {}
        }
      } catch {}
    }

    // 4. Try the candidate name directly as an icon-theme name
    if (!icon) {
      try {
        const display = Gdk.Display.get_default()
        if (display) {
          const theme = Gtk.IconTheme.get_for_display(display)
          if (theme.has_icon(lc)) icon = lc
          else if (theme.has_icon(candidate)) icon = candidate
        }
      } catch {}
    }

    if (icon) {
      iconCache.set(cacheKey, icon)
      return icon
    }
  }

  iconCache.set(cacheKey, FALLBACK_ICON)
  return FALLBACK_ICON
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
      const clients: {
        workspace: { id: number }
        class: string
        initialClass: string
        title: string
        size: number[]
      }[] = JSON.parse(parts[1].trim())
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

        icons[wsId] = resolveIcon(largest.class, largest.initialClass, largest.title)
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
