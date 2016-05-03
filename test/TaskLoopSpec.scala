import actors.TaskLoop
import akka.actor.ActorSystem
import org.scalatestplus.play._
import play.api.test._
import play.api.test.Helpers._
import akka.testkit.TestActorRef

class TaskLoopSpec extends PlaySpec with OneAppPerTest {
  implicit val system = ActorSystem()

  val actorRef = TestActorRef(new TaskLoop())
  val actor = actorRef.underlyingActor

  "readProcsFromConfig" should {
    "read all processes from config" in {
      actor.readProcsFromConfig().size mustBe 2
    }

    "the processes must contain the correct names" in {

    }
  }
}
