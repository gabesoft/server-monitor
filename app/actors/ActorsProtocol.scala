package actors

import models._

object ActorsProtocol {
  case object RunLoop
  case object StartLoop
  case object StopLoop
  case object StopStatusReader
  case object ReadStatus
  case class StatusResponse(proc: Proc)
}
