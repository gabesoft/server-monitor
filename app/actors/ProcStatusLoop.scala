package actors

import scala.concurrent.duration._

import actors.ActorsProtocol._
import akka.actor.{Actor, ActorLogging, ActorRef, Props}
import models._

object ProcStatusLoop {
  case object RunLoop

  def props(procs: Seq[ProcessInfo], interval: FiniteDuration): Props =
    Props(new ProcStatusLoop(procs, interval))
}

/**
  * Actor that checks processes status periodically
  * @param procs The list of processes to monitor
  * @param interval The repeat interval
  */
class ProcStatusLoop(procs: Seq[ProcessInfo], interval: FiniteDuration) extends Actor with ActorLogging {
  import context.dispatcher
  import ProcStatusLoop._

  var readers: Seq[ActorRef] = Nil;
  var count = 0
  var scheduled = false

  def receive: PartialFunction[Any, Unit] = {
    case InitLoop => initLoop
    case StopLoop => stopLoop
    case StartLoop => startLoop
    case PauseLoop => pauseLoop
    case RunLoop => runLoop
    case ReadStatus => readStatus
  }

  private def initLoop(): Unit = {
    readers = initializeStatusReaders()
    log.info("Proc status loop initialized")
  }

  private def stopLoop(): Unit = {
    readers.foreach(reader => reader ! StopStatusReader)
    context.stop(self)
  }

  private def initializeStatusReaders(): Seq[ActorRef] = {
    procs.map(proc => context.actorOf(ProcStatusReader.props(proc), proc.name))
  }

  private def readStatus(): Unit = {
    readers.foreach(reader => reader ! ReadStatus)
  }

  private def runLoop(): Unit = {
    scheduled = false
    readStatus()
    reschedule()
  }

  private def reschedule(): Unit = {
    if (!scheduled && count > 0) {
      log.debug(s"Rescheduling task loop $count")
      context.system.scheduler.scheduleOnce(interval, self, RunLoop)
      scheduled = true
    }
  }

  private def startLoop(): Unit = {
    count = count + 1
    log.debug(s"Start loop $count")
    readers.foreach(reader => reader ! ResumeStatusReader)
    reschedule()
  }

  private def pauseLoop(): Unit = {
    count = Math.max(0, count - 1)
    log.debug(s"Pause loop $count")
    if (count == 0) {
      readers.foreach(reader => reader ! PauseStatusReader)
    }
  }
}
