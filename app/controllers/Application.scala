package controllers

import scala.collection.JavaConverters._
import scala.concurrent.duration._

import actors.{ClientConnection, ProcStatusLoop}
import actors.ActorsProtocol._
import akka.actor.{ActorSystem, Props}
import akka.stream.Materializer
import com.typesafe.config.{Config, ConfigFactory}
import javax.inject._
import models._
import play.api.Play.current
import play.api.libs.json.JsValue
import play.api.mvc._

@Singleton
class Application @Inject() (implicit system: ActorSystem, materializer: Materializer) extends Controller {
  val procs = readProcsFromConfig()
  val interval = readDurationFromConfig("status.interval")
  val statusLoop = system.actorOf(ProcStatusLoop.props(procs, interval), "statusLoop")

  statusLoop ! StartLoop

  def index = Action { implicit request =>
    Ok(views.html.index(procs))
  }

  def stream = WebSocket.acceptWithActor[JsValue, JsValue] { request =>
    out => ClientConnection.props(out, statusLoop)
  }

  def readDurationFromConfig(name: String): FiniteDuration = {
    val d = ConfigFactory.load().getDuration(name)
    d.toNanos nanoseconds
  }

  def readProcsFromConfig(): Seq[Proc] = {
    def makeProc(config: Config): Proc = {
      Proc(config.getString("name"),
           config.getString("host"),
           config.getString("statusPath"),
           None)
    }

    ConfigFactory.load()
      .getConfigList("status.procs")
      .asScala
      .map(makeProc)
  }
}
