package actors

import models._

/**
  * Object that houses all messages passed among actors
  */
object ActorsProtocol {
  case object InitLoop
  case object StopLoop
  case object StartLoop
  case object PauseLoop
  case object PauseStatusReader
  case object ResumeStatusReader
  case object StopStatusReader
  case object ReadStatus
  case class StatusResponse(proc: ProcessInfo)
}
