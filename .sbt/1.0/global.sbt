cancelable in Global := true
shellPrompt := { state => "> " }

ensimeIgnoreMissingDirectories in ThisBuild := true
ensimeJavaFlags ++= Seq("-Xmx4g", "-XX:+PerfDisableSharedMem")
