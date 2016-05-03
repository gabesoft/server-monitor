package controllers

import scala.collection.JavaConverters._

import javax.inject._
import models._
import play._
import play.api.mvc._

/**
  * This controller creates an `Action` to handle HTTP requests to the
  * application's home page.
  */
@Singleton
class HomeController @Inject() extends Controller {

  /**
    * Create an Action to render an HTML page with a welcome message.
    * The configuration in the `routes` file means that this method
    * will be called when the application receives a `GET` request with
    * a path of `/`.
    */
  def index = Action {
    val procsList = Play.application.configuration.getConfigList("procs").asScala
    val procs = procsList map { p => Proc(p.getString("name"), p.getString("host"), p.getString("statusPath"), None) }

    Ok(views.html.index(procs.seq))
  }
}
