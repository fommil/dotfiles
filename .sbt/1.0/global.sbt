cancelable in Global := true
shellPrompt := { state => "> " }
SettingKey[Boolean]("autoStartServer") := false

ensimeIgnoreMissingDirectories in ThisBuild := true
ensimeJavaFlags ++= Seq("-Xmx4g", "-XX:+PerfDisableSharedMem")
//ensimeServerVersion in ThisBuild := "2.0.1"
