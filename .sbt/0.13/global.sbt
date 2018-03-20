import org.ensime.EnsimeKeys._

// WORKAROUND https://github.com/rtimush/sbt-updates/issues/10
addCommandAlias("dependencyUpdatesProject", ";reload plugins ;dependencyUpdates ;reload return")

cancelable in Global := true

// for 2.0-graph
ensimeIgnoreMissingDirectories in ThisBuild := true
ensimeJavaFlags ++= Seq("-Xmx4g", "-XX:+PerfDisableSharedMem")

// causes weird problems with clean
//historyPath := Some((baseDirectory in ThisBuild).value / ".history")

ensimeJavaFlags ++= {
  if (name.value == "ensime") Nil
  else Seq("-Densime.index.no.reverse.lookups=true")
}
