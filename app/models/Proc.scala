package models

object Proc {
  def withStatus(proc: Proc, status: String): Proc = {
    Proc(proc.name, proc.host, proc.statusPath, Some(status))
  }
}

case class Proc(
  name: String,
  host: String,
  statusPath: String,
  status: Option[String])
