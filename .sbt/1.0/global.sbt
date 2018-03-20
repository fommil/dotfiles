cancelable in Global := true
shellPrompt := { state => "> " }
SettingKey[Boolean]("autoStartServer") := false

ensimeIgnoreMissingDirectories in ThisBuild := true
ensimeJavaFlags ++= Seq("-Xmx4g", "-XX:+PerfDisableSharedMem")

ensimeJavaFlags ++= {
  if (name.value == "ensime") Nil
  else Seq("-Densime.index.no.reverse.lookups=true")
}
