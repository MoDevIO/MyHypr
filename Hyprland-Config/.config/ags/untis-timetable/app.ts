import app from "ags/gtk4/app"
import style from "./style.scss"
import TimetablePopup from "./widget/TimetablePopup"

app.start({
  instanceName: "untis-timetable",
  css: style,
  main() {
    TimetablePopup()
  },
})
