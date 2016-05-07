package actors

import actors.ActorsProtocol._
import akka.actor._
import akka.event.LoggingReceive
import javax.inject.Inject
import models._
import play.api.libs.json.{JsValue, Json, Writes}

object ClientConnection {
  trait Factory {
    def apply(out: ActorRef, statusReader: ActorRef): Actor
  }

  def props(out: ActorRef, statusReader: ActorRef): Props = Props(new ClientConnection(out, statusReader))

  case class ProcStatusMessage(proc: Proc)

  object ProcStatusMessage {
    implicit val procStatusMessageWrites = new Writes[ProcStatusMessage] {
      def writes(message: ProcStatusMessage): JsValue = {
        Json.obj(
          "type" -> "process",
          "name" -> message.proc.name,
          "status" -> message.proc.status
        )
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
    statusReader ! ResumeLoop
  }

  def receive = LoggingReceive {
    case StatusResponse(proc: Proc) =>
      out ! Json.toJson(ProcStatusMessage(proc))
    case js: JsValue =>
      ((js \ "type").as[String]) match {
        case "readStatus" =>
          statusReader ! ReadStatus
      }
  }

  override def postStop = {
    context.system.eventStream.unsubscribe(self, classOf[ProcStatusReader])
    statusReader ! PauseLoop
  }
}
