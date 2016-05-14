package models

import java.util.Date
import play.api.libs.json._


sealed trait ProcessStatus
case class Running() extends ProcessStatus
case class Down(reason: String = "Unknown") extends ProcessStatus

/**
  *  Model that contains information about a process expected to be running
  */
object ProcessInfo {
  def make(name: String, host: String, pingPath: String): ProcessInfo = {
    new ProcessInfo(name, host, pingPath, Down(), None, None, None, None)
  }

  def parseRunning(proc: ProcessInfo, json: String): ProcessInfo = {
    val data = Json.parse(json)
    val cpu = (data \ "cpu").as[Double]
    val mem = (data \ "mem").as[Double]
    val pid = (data \ "pid").as[String]
    val stime = (data \ "stime").as[Long]

    new ProcessInfo(
      proc.name,
      proc.host,
      proc.pingPath,
      Running(),
      Some(cpu),
      Some(mem),
      Some(pid),
      Some(stime))
  }

  def parseFailed(proc: ProcessInfo, error: String): ProcessInfo = {
    new ProcessInfo(proc.name, proc.host, proc.pingPath, Down(error), None, None, None, None)
  }

  def stringify(proc: ProcessInfo): JsValue = {
    proc.status match {
      case Running() =>
        Json.obj(
          "name" -> proc.name,
          "host" -> proc.host,
          "status" -> "running",
          "cpu" -> proc.cpu.get,
          "memory" -> proc.memory.get,
          "pid" -> proc.pid.get,
          "startDate" -> new Date(proc.startDate.get),
          "currentDate" -> new Date()
        )
      case Down(reason) =>
        Json.obj(
          "name" -> proc.name,
          "host" -> proc.host,
          "status" -> "down",
          "reason" -> reason
        )
    }
  }

  def stringify(procs: Seq[ProcessInfo]): JsArray = {
    JsArray(procs.map(stringify(_)))
  }
}

case class ProcessInfo (
  name: String,
  host: String,
  pingPath: String,
  status: ProcessStatus,
  cpu: Option[Double],
  memory: Option[Double],
  pid: Option[String],
  startDate: Option[Long]
) {
  def pingUrl: String = s"http://${this.host}${this.pingPath}"
}
