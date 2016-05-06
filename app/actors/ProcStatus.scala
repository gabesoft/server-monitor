package actors

import akka.actor.{ Actor, ActorLogging, ActorRef, ActorSystem }
import play.api.libs.ws.WS
// import scalaj.http.Http
import play.api.libs.json._
import scala.concurrent.duration._

class ProcStatus(subscriber: ActorRef) extends Actor with ActorLogging {
  import context.dispatcher

  override def preStart(): Unit = {
    self ! "Run"
  }

  def receive = {
    case "Run" =>
      println("Running")
      context.system.scheduler.scheduleOnce(15.seconds, self, "Run")
  }

  def doWork = {
    import play.api.Play.current

    // TODO use play.api.lib.ws for http requests
    // val response = Http("http://localhost:8006/pstatus").asString
    WS.url("http://localhost:8006/pstatus").get().map {
      response => println(response.body)
    }
  }
}
