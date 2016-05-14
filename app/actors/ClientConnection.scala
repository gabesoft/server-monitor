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
        ProcessInfo.stringify(message.proc)
      }
    }
  }
}

/**
  * Actor that facilitates passing and receiving messages via web sockets
  */
class ClientConnection @Inject() (out: ActorRef, statusReader: ActorRef) extends Actor with ActorLogging {
  import ClientConnection._

  override def preStart: Unit = {
    context.system.eventStream.subscribe(self, classOf[StatusResponse])
    log.info("Start loop")
    statusReader ! StartLoop
  }

  def receive: PartialFunction[Any, Unit] = LoggingReceive {
    case StatusResponse(proc: ProcessInfo) =>
      out ! Json.toJson(ProcStatusMessage(proc))
    case js: JsValue =>
      ((js \ "type").as[String]) match {
        case "readStatus" =>
          log.info("Read status")
          statusReader ! ReadStatus
      }
  }

  override def postStop: Unit = {
    context.system.eventStream.unsubscribe(self, classOf[ProcStatusReader])
    log.info("Pause loop")
    statusReader ! PauseLoop
  }
}
