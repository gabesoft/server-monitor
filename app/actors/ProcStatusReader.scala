package actors

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

import actors.ActorsProtocol._
import akka.actor.{Props, Actor, ActorLogging, ActorRef, ActorSystem}
import akka.stream.ActorMaterializer
import models._
import play.api.libs.ws.ahc.AhcWSClient

object ProcStatusReader {
  def props(proc: Proc): Props = Props(new ProcStatusReader(proc))
}

/**
  * Actor that reads the status for a process
  * @param proc The process for which to read the status
  */
class ProcStatusReader(proc: Proc) extends Actor with ActorLogging {
  var paused = false
  var running = false
  var stopped = false

  implicit val materializer = ActorMaterializer()
  implicit val system = ActorSystem("main-actor-system")

  def receive = {
    case ReadStatus =>
      if(!paused) readStatus()
    case PauseStatusReader =>
      paused = true
    case ResumeStatusReader =>
      paused = false
    case StopStatusReader =>
      stopped = true
      if (!running) context.stop(self)
  }

  def publish(data: String): Unit = {
    val status = StatusResponse(Proc.withStatus(proc, data))
    context.system.eventStream.publish(status)
  }

  def readStatus(): Unit = {

    running = true

    val ws = AhcWSClient()
    val url = "http://" + proc.host + proc.statusPath

    ws.url(url).get().onComplete { res =>
      res match {
        case Success(response) =>
          publish(response.body)
        case Failure(ex) =>
          val data = s"""{"error":"${ex.toString()}"}"""
          publish(data)
      }

      ws.close()
      running = false

      if (stopped) {
        context.stop(self)
      }
    }
  }
}
