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
    app.post("vote", use: electionController.submitVote)

    let elections = tokenProtected.grouped("elections")
    elections.post("", use: electionController.create)
    elections.post("voters", use: electionController.createVoter)
    elections.post("ballots", use: electionController.createBallot)
    elections.post("ballot_items", use: electionController.createBallotItem)
    elections.post("ballot_options", use: electionController.createBallotOption)

}
