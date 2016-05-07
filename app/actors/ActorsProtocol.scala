package actors

import models._

/**
  * Object that houses all messages passed among actors
  */
object ActorsProtocol {
  case object RunLoop
  case object StartLoop
  case object StopLoop
  case object ResumeLoop
  case object PauseLoop
  case object PauseStatusReader
  case object ResumeStatusReader
  case object StopStatusReader
  case object ReadStatus
  case class StatusResponse(proc: Proc)
}
