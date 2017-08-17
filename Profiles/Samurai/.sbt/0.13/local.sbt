import org.ensime.EnsimeKeys._
import org.ensime.EnsimeCoursierKeys._

ensimeJavaHome in ThisBuild := file("/usr/lib/jvm/java-8-openjdk")
ensimeCachePrefix in ThisBuild := Some(file("/tmp/fommil-ensime"))
ensimeJavaFlags += "-javaagent:/home/fommil/.sbt/class-monkey-1.7.1-assembly.jar"
