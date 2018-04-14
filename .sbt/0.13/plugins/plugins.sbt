addSbtPlugin("org.ensime" % "sbt-ensime" % "2.5.2")

// 0.3.0 uses Java 7 https://github.com/rtimush/sbt-updates/issues/71
if (sys.props("java.version").startsWith("1.6"))
  addSbtPlugin("com.timushev.sbt" % "sbt-updates" % "0.2.0")
else
  addSbtPlugin("com.timushev.sbt" % "sbt-updates" % "0.3.3")

addSbtPlugin("net.virtual-void" % "sbt-dependency-graph" % "0.9.0")
