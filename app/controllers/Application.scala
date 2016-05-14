package controllers

import scala.collection.JavaConverters._
import scala.concurrent.Future
import scala.concurrent.duration._
import scala.util.Right

import actors.{ClientConnection, ProcStatusLoop}
import actors.ActorsProtocol._
import akka.actor.{ActorSystem, Props}
import akka.stream.Materializer
import com.typesafe.config.{Config, ConfigFactory}
import javax.inject._
import models._
import play.api.Play.current
import play.api.libs.json.JsValue
import play.api.libs.streams.ActorFlow
import play.api.mvc._

@Singleton
class Application @Inject() (implicit system: ActorSystem, materializer: Materializer) extends Controller {
  val procs = readProcsFromConfig()
  val interval = readDurationFromConfig("status.interval")
  val statusLoop = system.actorOf(ProcStatusLoop.props(procs, interval), "statusLoop")

  statusLoop ! InitLoop

  def index : Action[AnyContent] = Action { implicit request =>
    Ok(views.html.index(procs))
  }

  def stream : WebSocket = WebSocket.acceptOrResult[JsValue, JsValue] { request =>
    val actor = ActorFlow.actorRef(out => ClientConnection.props(out, statusLoop))
    Future.successful(Right(actor))
  }

  private def readDurationFromConfig(name: String): FiniteDuration = {
    val d = ConfigFactory.load().getDuration(name)
    d.toNanos nanoseconds
  }

  private def readProcsFromConfig(): Seq[ProcessInfo] = {
    def makeProc(config: Config): ProcessInfo = {
      ProcessInfo.make(
        config.getString("name"),
        config.getString("host"),
        config.getString("statusPath"))
    }

    ConfigFactory.load()
      .getConfigList("status.procs")
      .asScala
      .map(makeProc)
  }
}
