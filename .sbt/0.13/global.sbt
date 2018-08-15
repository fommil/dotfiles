//import org.ensime.EnsimeKeys._

// WORKAROUND https://github.com/rtimush/sbt-updates/issues/10
addCommandAlias("dependencyUpdatesProject", ";reload plugins ;dependencyUpdates ;reload return")

cancelable in Global := true

// ensimeIgnoreMissingDirectories in ThisBuild := true
// ensimeJavaFlags ++= Seq("-Xmx4g", "-XX:+PerfDisableSharedMem")

// causes weird problems with clean
//historyPath := Some((baseDirectory in ThisBuild).value / ".history")
