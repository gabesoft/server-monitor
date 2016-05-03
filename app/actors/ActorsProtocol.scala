package actors

object ActorsProtocol {
  case object RunLoop
  case object StartLoop
  case object StopLoop
  case object StopStatusReader
  case object ReadStatus
  case class StatusResponse(json: String)
}