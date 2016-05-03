package models

case class Proc(
  name: String,
  host: String,
  statusPath: String,
  status: Option[String])
