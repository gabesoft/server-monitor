package actors

import scala.concurrent.ExecutionContext.Implicits.global
import scala.util.{Failure, Success}

import actors.ActorsProtocol._
import akka.actor.{Props, Actor, ActorLogging, ActorRef, ActorSystem}
import akka.stream.ActorMaterializer
import models._
import play.api.libs.ws.ahc.AhcWSClient

object ProcStatusReader {
  def props(procInfo: ProcessInfo): Props = Props(new ProcStatusReader(procInfo))
}

/**
  * Actor that reads the status for a process
  * @param proc The process for which to read the status
  */
class ProcStatusReader(procInfo: ProcessInfo) extends Actor with ActorLogging {
  var paused = false
  var running = false
  var stopped = false

  implicit val system = context.system
  implicit val materializer = ActorMaterializer()(system)

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

  def publish(proc: ProcessInfo): Unit = {
    context.system.eventStream.publish(StatusResponse(proc))
  }

  def readStatus(): Unit = {

    running = true

    val ws = AhcWSClient()

    ws.url(procInfo.pingUrl).get().onComplete { res =>
      res match {
        case Success(response) =>
          publish(ProcessInfo.parseRunning(procInfo, response.body))
        case Failure(ex) =>
          publish(ProcessInfo.parseFailed(procInfo, ex.toString()))
      }

      ws.close()
      running = false

      if (stopped) {
        context.stop(self)
      }
    }
  }
}
