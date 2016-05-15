name := """server-monitor"""

version := "1.1"

lazy val root = (project in file("."))
  .enablePlugins(PlayScala)
  .enablePlugins(SbtWeb)

lazy val elm = taskKey[Unit]("Compiles elm files")

elm := {
  "make elm-build" !
}

excludeFilter in (Assets, JshintKeys.jshint) := {
  val elm = (baseDirectory.value / "app/assets/javascripts/main-elm.js").getCanonicalPath
  new SimpleFileFilter(_.getCanonicalPath equals elm)
}

pipelineStages := Seq(rjs, uglify, digest, gzip)

scalaVersion := "2.11.7"

val akkaVersion = "2.4.4"

libraryDependencies ++= Seq(
  jdbc,
  cache,
  ws,
  "org.scalatestplus.play" %% "scalatestplus-play" % "1.5.1" % Test,
  "com.typesafe.akka" %% "akka-testkit" % akkaVersion % "test",
  "com.typesafe.akka" %% "akka-contrib" % akkaVersion
  )

resolvers += "scalaz-bintray" at "http://dl.bintray.com/scalaz/releases"
