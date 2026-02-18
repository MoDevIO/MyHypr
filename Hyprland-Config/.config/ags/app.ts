import app from "ags/gtk4/app"
import style from "./style.scss"
import { MainBar, SecondaryBar } from "./widget/Bar"

app.start({
  css: style,
  main() {
    MainBar()
    SecondaryBar()
  },
})
