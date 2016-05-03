package actors

import scala.concurrent.duration._

import actors.ActorsProtocol._
import akka.actor.{ActorRef, Actor, ActorLogging, Props}
import models._

/**
  * Actor that runs the status reader actors in a loop according to the specified interval
  * @param procs The list of processes to monitor
  * @param interval The repeat interval
  */
class TaskLoop(procs: Seq[Proc], interval: FiniteDuration) extends Actor with ActorLogging {
  import context.dispatcher

  var readers: Seq[ActorRef] = Nil;

  def receive = {
    case StartLoop => startLoop
    case StopLoop => stopLoop
    case RunLoop => runLoop
    case StatusResponse(json) => println(json)
  }

  def startLoop(): Unit = {
    readers = initializeStatusReaders()
    log.info("Starting task loop")
    runLoop()
  }

  def initializeStatusReaders(): Seq[ActorRef] = {
    procs.map(
      proc => {
        context.actorOf(
          Props(classOf[ProcStatusReader], proc, self),
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
    context.stop(self)
  }
}
