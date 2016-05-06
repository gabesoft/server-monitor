package actors

import scala.concurrent.duration._

import actors.ActorsProtocol._
import akka.actor.{Actor, ActorLogging, ActorRef, Props}
import models._

object ProcStatusLoop {
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

  var readers: Seq[ActorRef] = Nil;

  def receive = {
    case StartLoop => startLoop
    case StopLoop => stopLoop
    case RunLoop => runLoop
    case ReadStatus => readStatus
  }

  def startLoop(): Unit = {
    if (readers == Nil) {
      readers = initializeStatusReaders()
      log.info("Starting task loop")
      reschedule()
    }
  }

  def initializeStatusReaders(): Seq[ActorRef] = {
    procs.map(
      proc => {
        context.actorOf(
          Props(classOf[ProcStatusReader], proc),
          proc.name)
      })
  }

  def readStatus(): Unit = {
    readers.foreach(reader => reader ! ReadStatus)
  }

  def runLoop(): Unit = {
    readStatus()
    reschedule()
  }

  def reschedule(): Unit = {
    log.info("Rescheduling task loop")
    context.system.scheduler.scheduleOnce(interval, self, RunLoop)
  }

  def stopLoop(): Unit = {
    readers.foreach(reader => reader ! StopStatusReader)
    readers = Nil
    context.stop(self)
  }
}
