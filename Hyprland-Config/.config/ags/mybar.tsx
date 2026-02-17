import app from "ags/gtk4/app";
import { Astal, Gtk, Gdk } from "ags/gtk4";
import { createPoll } from "ags/time";
import { exec } from "ags/process";


app.start({
  css: `
    .bar {
      background: alpha(#181818, 0.9);
      color: #d4d4d4;
      font-family: "JetBrainsMono Nerd Font", "Symbols Nerd Font", monospace;
      font-size: 13px;
      padding: 4px 12px;
      min-height: 32px;
    }

    .bar-section { padding: 0 4px; }

    .ws-btn {
      min-width: 28px;
      min-height: 24px;
      border-radius: 6px;
      margin: 2px 2px;
      padding: 0 6px;
      background: alpha(#555555, 0.3);
      color: #888888;
      font-weight: bold;
    }
    .ws-btn:hover { background: alpha(#cccccc, 0.25); }
    .ws-active {
      background: #d4d4d4;
      color: #181818;
    }
    .ws-active:hover {
      background: #ffffff;
      color: #181818;
    }
    .ws-occupied {
      background: alpha(#aaaaaa, 0.3);
      color: #cccccc;
    }
    .ws-empty {
      background: alpha(#444444, 0.2);
      color: #555555;
    }

    .clock {
      font-weight: bold;
      font-size: 14px;
      color: #e0e0e0;
    }
    .date {
      color: #999999;
      font-size: 12px;
      margin-left: 8px;
    }

    .sys-label {
      margin: 0 6px;
      font-size: 12px;
      color: #bbbbbb;
    }

    .music-label {
      color: #cccccc;
      font-size: 12px;
      margin: 0 6px;
    }

    .music-btn {
      min-width: 24px;
      min-height: 24px;
      border-radius: 6px;
      margin: 0 2px;
      padding: 0 4px;
      background: alpha(#555555, 0.3);
      color: #cccccc;
      font-size: 14px;
    }
    .music-btn:hover { background: alpha(#cccccc, 0.2); }
  `,

  main() {
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor;

    // ── Clock & Date ──────────────────────────────────────
    const clock = createPoll("", 1000, "date '+%H:%M:%S'");
    const date = createPoll("", 60000, "date '+%a %b %d'");

    // ── Workspaces ────────────────────────────────────────
    // Poll returns JSON: { actives: number[], occupied: number[] }
    // actives = workspace that is active on EACH monitor (not just the focused one)
    const wsData = createPoll("{\"actives\":[1],\"occupied\":[]}", 100,
      ["bash", "-c", "echo \"$(hyprctl monitors -j | tr -d '\\n' | grep -oP '\"activeWorkspace\":\\s*\\{[^}]*\\}' | grep -oP '\"id\":\\s*\\K[0-9]+' | tr '\\n' ','):$(hyprctl workspaces -j | grep -o '\"id\": *[0-9]*' | grep -o '[0-9]*' | tr '\\n' ',')\""],
      (out) => {
        try {
          const [activesStr, occupiedStr] = out.split(":");
          const actives = activesStr.split(",").filter(Boolean).map(Number);
          const occupied = occupiedStr.split(",").filter(Boolean).map(Number);
          return JSON.stringify({ actives, occupied });
        } catch {
          return JSON.stringify({ actives: [1], occupied: [] });
        }
      },
    );

    // ── CPU ───────────────────────────────────────────────
    const cpu = createPoll("CPU: 0%", 2000,
      ["bash", "-c", "top -bn1 | grep '%Cpu' | awk '{print $2}'"],
      (out) => {
        const val = parseFloat(out) || 0;
        return `CPU: ${val.toFixed(0)}%`;
      },
    );

    // ── Memory ────────────────────────────────────────────
    const mem = createPoll("MEM: 0%", 3000,
      ["bash", "-c", "free -m | awk '/Mem:/{printf \"%.0f\", $3/$2*100}'"],
      (out) => {
        const val = parseFloat(out) || 0;
        return `MEM: ${val}%`;
      },
    );

    // ── Volume ────────────────────────────────────────────
    const vol = createPoll("", 1000,
      ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
      (out) => {
        const match = out.match(/Volume:\s+([\d.]+)/);
        const pct = match ? Math.round(parseFloat(match[1]) * 100) : 0;
        const muted = out.includes("[MUTED]");
        const icon = muted ? "󰝟" : pct > 60 ? "󰕾" : pct > 30 ? "󰖀" : "󰕿";
        return `VOL: ${icon} ${pct}%`;
      },
    );

    // ── Music (playerctl) ─────────────────────────────────
    const musicInfo = createPoll("", 2000,
      ["bash", "-c", "playerctl metadata --format '{{artist}} — {{title}}' 2>/dev/null || echo ''"],
      (out) => {
        if (!out || out.includes("No players found")) return "";
        // Strip unsupported symbols: keep letters, digits, spaces, basic punctuation
        const clean = out.replace(/[^\p{L}\p{N}\s\-—–_.,:;!?'"()&/\\@#]/gu, "").trim();
        if (!clean) return "";
        const track = clean.length > 40 ? clean.slice(0, 37) + "…" : clean;
        return `${track}`;
      },
    );

    // ── Assemble the bar ──────────────────────────────────

    // Helper: create workspace buttons for a given range
    function makeWsButtons(realIds: number[], displayOffset: number) {
      return realIds.map((realId) => {
        const displayId = realId - displayOffset;
        return (
          <button
            cursor={Gdk.Cursor.new_from_name("pointer", null)}
            cssClasses={wsData((ws) => {
              try {
                const d = JSON.parse(ws);
                if (d.actives.includes(realId)) return ["ws-btn", "ws-active"];
                if (d.occupied.includes(realId)) return ["ws-btn", "ws-occupied"];
                return ["ws-btn", "ws-empty"];
              } catch {
                return ["ws-btn", "ws-empty"];
              }
            })}
            label={`${displayId}`}
            onClicked={() => {
              try { exec(["hyprctl", "dispatch", "workspace", `${realId}`]); } catch {}
            }}
          />
        );
      });
    }

    // Monitor 1 (DP-1): workspaces 1-10
    const wsButtonsM1 = makeWsButtons([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 0);
    // Monitor 2 (HDMI-A-1): workspaces 11-20, displayed as 1-10
    const wsButtonsM2 = makeWsButtons([11, 12, 13, 14, 15, 16, 17, 18, 19, 20], 10);

    // ── Main bar (DP-1, monitor 1) ────────────────────────
    const left = (
      <box halign={Gtk.Align.START} spacing={8}>
        <label cssClasses={["clock"]} label={clock} />
        <label cssClasses={["date"]} label={date} />
        <label cssClasses={["music-label"]} label={musicInfo} />
      </box>
    );

    const center = (
      <box spacing={4}>
        {...wsButtonsM1}
      </box>
    );

    const right = (
      <box halign={Gtk.Align.END} spacing={4}>
        <label cssClasses={["sys-label"]} label={cpu} />
        <label cssClasses={["sys-label"]} label={mem} />
        <label cssClasses={["sys-label"]} label={vol} />
      </box>
    );

    // ── Secondary bar (HDMI-A-1, monitor 0) ───────────────
    const m2Center = (
      <box spacing={4}>
        {...wsButtonsM2}
      </box>
    );

    // Main bar on DP-1
    <window
      visible
      monitor={1}
      anchor={TOP | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      layer={Astal.Layer.TOP}
      cssClasses={["bar"]}
    >
      <centerbox
        startWidget={left}
        centerWidget={center}
        endWidget={right}
      />
    </window>;

    // Secondary bar on HDMI-A-1 (workspaces only)
    <window
      visible
      monitor={0}
      anchor={TOP | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      layer={Astal.Layer.TOP}
      cssClasses={["bar"]}
    >
      <centerbox
        centerWidget={m2Center}
      />
    </window>;
  },
});
