package actors

import scala.concurrent.ExecutionContext.Implicits.global

import actors.ActorsProtocol._
import akka.actor.{Actor, ActorRef, ActorLogging, ActorSystem}
import akka.stream.ActorMaterializer
import models._
import play.api.libs.ws.ahc.AhcWSClient
import scala.util.{ Failure, Success }

/**
  * Actor that reads the status for a process
  * @param client The client to call with the new status
  * @param proc The process for which to read the status
  */
class ProcStatusReader(proc: Proc, client: ActorRef) extends Actor with ActorLogging {
  def receive = {
    case ReadStatus => readStatus()
    case StopStatusReader => context.stop(self)
  }

  def readStatus(): Unit = {
    implicit val materializer = ActorMaterializer()
    implicit val system = ActorSystem()

    val ws = AhcWSClient()
    val url = "http://" + proc.host + proc.statusPath

    ws.url(url).get().onComplete { res =>
      log.info(s"Reading status for ${proc.name} complete")

      res match {
        case Success(response) => client ! StatusResponse(response.body)
        case Failure(ex) => log.error(ex.toString())
      }

      ws.close()
    }
  }
}
