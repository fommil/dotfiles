import org.ensime.EnsimeKeys._
import org.ensime.EnsimeCoursierKeys._

ensimeJavaHome in ThisBuild := file("/usr/lib/jvm/java-8-openjdk")
ensimeCachePrefix in ThisBuild := Some(file("/tmp/fommil-ensime"))
ensimeJavaFlags += "-javaagent:/home/fommil/.sbt/class-monkey-1.7.1-assembly.jar"

// be careful when using the agent if other apps use port 10001
ensimeJavaFlags += s"""-agentpath:${sys.env("YOURKIT_AGENT")}=quiet"""

//ensimeJavaFlags ++= Seq("-XX:+UseConcMarkSweepGC", "-Xms4g", "-XX:NewSize=2g")
ensimeJavaFlags += "-XX:+UseG1GC"
