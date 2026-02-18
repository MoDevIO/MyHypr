import { createPoll } from "ags/time"

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
  return <label cssClasses={["music-label"]} label={musicInfo} />
}
