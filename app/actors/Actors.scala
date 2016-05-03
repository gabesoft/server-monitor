package actors

import scala.collection.JavaConverters._
import scala.concurrent.duration._

import actors.ActorsProtocol._
import akka.actor.{ActorSystem, Props}
import com.google.inject.AbstractModule
import com.typesafe.config.{ConfigFactory, Config}
import models._
import play.api.libs.concurrent.AkkaGuiceSupport

case class ProcStatusData(pid: String, command: String, raw: String)

/**
 * Class that initializes the task loop actor
 */
class Actors extends AbstractModule with AkkaGuiceSupport {
  def configure() = {
    val system = ActorSystem("Actors")
    val procs = readProcsFromConfig()
    val interval = 5 minutes
    val taskLoop = system.actorOf(Props(classOf[TaskLoop], procs, interval), "TaskLoop")

    taskLoop ! StartLoop
  }

  def readProcsFromConfig(): Seq[Proc] = {
    def makeProc(config: Config): Proc = {
      Proc(config.getString("name"),
           config.getString("host"),
           config.getString("statusPath"),
           None)
    }

    ConfigFactory.load()
      .getConfigList("procs")
      .asScala
      .map(makeProc)
  }
}
