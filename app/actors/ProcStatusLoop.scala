package actors

import scala.concurrent.duration._

import actors.ActorsProtocol._
import akka.actor.{Actor, ActorLogging, ActorRef, Props}
import models._

object ProcStatusLoop {
  case object RunLoop

  def props(procs: Seq[Proc], interval: FiniteDuration): Props =
    Props(new ProcStatusLoop(procs, interval))
}

/**
  * Actor that checks processes status periodically
  * @param procs The list of processes to monitor
  * @param interval The repeat interval
  */
class ProcStatusLoop(procs: Seq[Proc], interval: FiniteDuration) extends Actor with ActorLogging {
  import context.dispatcher
  import ProcStatusLoop._

  var readers: Seq[ActorRef] = Nil;
  var count = 0

  def receive = {
    case InitLoop => initLoop
    case StopLoop => stopLoop
    case StartLoop => startLoop
    case PauseLoop => pauseLoop
    case RunLoop => runLoop
    case ReadStatus => readStatus
  }

  def initLoop(): Unit = {
    readers = initializeStatusReaders()
    log.info("Proc status loop initialized")
  }

  def stopLoop(): Unit = {
    readers.foreach(reader => reader ! StopStatusReader)
    context.stop(self)
  }

  def initializeStatusReaders(): Seq[ActorRef] = {
    procs.map(proc => context.actorOf(ProcStatusReader.props(proc), proc.name))
  }

  def readStatus(): Unit = {
    readers.foreach(reader => reader ! ReadStatus)
  }

  def runLoop(): Unit = {
    readStatus()
    reschedule()
  }

  def reschedule(force: Boolean = false): Unit = {
    if (count > 0 || force) {
      log.info(s"Rescheduling task loop $count")
      context.system.scheduler.scheduleOnce(interval, self, RunLoop)
    }
  }

  def startLoop(): Unit = {
    count = count + 1
    log.info(s"Start loop $count")
    readers.foreach(reader => reader ! ResumeStatusReader)
    if (count == 1) {
      reschedule()
    }
  }

  def pauseLoop(): Unit = {
    count = Math.max(0, count - 1)
    log.info(s"Pause loop $count")
    if (count == 0) {
      readers.foreach(reader => reader ! PauseStatusReader)
    }
  }
}
