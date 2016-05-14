package actors

import actors.ActorsProtocol._
import akka.actor._
import akka.event.LoggingReceive
import java.util.Date
import javax.inject.Inject
import models._
import play.api.libs.json.{JsValue, Json, Writes}

object ClientConnection {
  trait Factory {
    def apply(out: ActorRef, statusReader: ActorRef): Actor
  }

  def props(out: ActorRef, statusReader: ActorRef): Props = Props(new ClientConnection(out, statusReader))

  case class ProcStatusMessage(proc: ProcessInfo)

  object ProcStatusMessage {
    implicit val procStatusMessageWrites = new Writes[ProcStatusMessage] {
      def writes(message: ProcStatusMessage): JsValue = {
        val proc = message.proc

        proc.status match {
          case Running() =>
            Json.obj(
              "name" -> proc.name,
              "host" -> proc.host,
              "status" -> "running",
              "cpu" -> proc.cpu.get,
              "memory" -> proc.memory.get,
              "pid" -> proc.pid.get,
              "startDate" -> new Date(proc.startDate.get),
              "currentDate" -> new Date()
            )
          case Down(reason) =>
            Json.obj(
              "name" -> proc.name,
              "host" -> proc.host,
              "status" -> "down",
              "reason" -> reason
            )
        }
      }
    }
  }
}

/**
  * Actor that facilitates passing and receiving messages via web sockets
  */
class ClientConnection @Inject() (out: ActorRef, statusReader: ActorRef) extends Actor with ActorLogging {
  import ClientConnection._

  override def preStart = {
    context.system.eventStream.subscribe(self, classOf[StatusResponse])
    log.info("Start loop")
    statusReader ! StartLoop
  }

  def receive = LoggingReceive {
    case StatusResponse(proc: ProcessInfo) =>
      out ! Json.toJson(ProcStatusMessage(proc))
    case js: JsValue =>
      ((js \ "type").as[String]) match {
        case "readStatus" =>
          log.info("Read status")
          statusReader ! ReadStatus
      }
  }

  override def postStop = {
    context.system.eventStream.unsubscribe(self, classOf[ProcStatusReader])
    log.info("Pause loop")
    statusReader ! PauseLoop
  }
}
