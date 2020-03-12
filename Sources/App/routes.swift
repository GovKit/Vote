import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    let userController = UserController()
    app.post("register", use: userController.create)

    let passwordProtected = app.grouped(User.authenticator().middleware())
    passwordProtected.post("login", use: userController.login)

    let tokenProtected = app.grouped(UserToken.authenticator().middleware())

    let electionController = ElectionController()
    let elections = app.grouped("elections")

    elections.post(":electionID", "vote",
             use: electionController.submitVote)

    elections.get("", use: electionController.index)
    elections.get(":electionID", "voters",
                  use: electionController.indexVoters)
    elections.get(":electionID", "ballots",
                   use: electionController.indexBallots)
    elections.get(":electionID", "ballots",
                   ":ballotID", "ballot_items",
                   use: electionController.indexBallotItems)
    elections.get(":electionID",
                   "ballots", ":ballotID",
                   "ballot_items", ":ballotItemID",
                   "ballot_options",
                   use: electionController.indexBallotOptions)
    elections.get(":electionID", "submissions",
                  use: electionController.indexSubmissions)

    let protectedElections = tokenProtected.grouped("elections")
    protectedElections.post("", use: electionController.create)
    protectedElections.post(":electionID", "voters",
                   use: electionController.createVoter)
    protectedElections.post(":electionID", "ballots",
                   use: electionController.createBallot)
    protectedElections.post(":electionID", "ballots",
                   ":ballotID", "ballot_items",
                   use: electionController.createBallotItem)
    protectedElections.post(":electionID",
                   "ballots", ":ballotID",
                   "ballot_items", ":ballotItemID",
                   "ballot_options",
                   use: electionController.createBallotOption)
}
