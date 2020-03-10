import Fluent
import Vapor

struct ElectionController {
    func create(_ req: Request) throws -> EventLoopFuture<Election> {
        // fetch auth'd user
        let user = try req.auth.require(User.self)

        let electionRequest = try req.content.decode(CreateElectionRequest.self)

        let election = try Election(description: electionRequest.description,
                                    userID: user.requireID())

        return election.save(on: req.db).map { election }
    }

    func createVoter(_ req: Request) throws -> EventLoopFuture<Voter> {
        // fetch auth'd user
        let user = try req.auth.require(User.self)

        let voterRequest = try req.content.decode(CreateVoterRequest.self)

        return try guardedElection(req, content: voterRequest).flatMap { election in
                do {
                    guard try election.$user.id == user.requireID() else {
                        throw Abort(.forbidden)
                    }
                    let voter = try Voter(votingKey: voterRequest.votingKey,
                                          name: voterRequest.name,
                                          hasVoted: false,
                                          electionID: election.requireID())
                    return voter.save(on: req.db).map { voter }
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
        }
    }

    func createBallot(_ req: Request) throws -> EventLoopFuture<Ballot> {
        // fetch auth'd user
        let user = try req.auth.require(User.self)

        let ballotRequest = try req.content.decode(CreateBallotRequest.self)

        return try guardedElection(req, content: ballotRequest).flatMap { election in
                do {
                    guard try election.$user.id == user.requireID() else {
                        throw Abort(.forbidden)
                    }
                    let ballot = try Ballot(description: ballotRequest.description,
                                            electionID: election.requireID())
                    return ballot.save(on: req.db).map { ballot }
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
        }
    }

    func createBallotItem(_ req: Request) throws -> EventLoopFuture<BallotItem> {
        let itemRequest = try req.content.decode(CreateBallotItemRequest.self)

        let election = try guardedElection(req, content: itemRequest)
        let ballot = Ballot.find(itemRequest.ballotID, on: req.db)
            .unwrap(or: Abort(.notFound))

        return ballot.and(election).flatMap { (ballot, election) in
            do {
                guard ballot.$election.id == election.id else {
                    throw Abort(.forbidden)
                }
                let ballotItem = try BallotItem(description: itemRequest.description,
                                                maxOptions: itemRequest.maxOptions,
                                                minOptions: itemRequest.minOptions,
                                                ballotID: ballot.requireID())
                return ballotItem.save(on: req.db).map { ballotItem }
            } catch {
                return req.eventLoop.makeFailedFuture(error)
            }
        }
    }

    func createBallotOption(_ req: Request) throws -> EventLoopFuture<BallotOption> {
        let optionRequest = try req.content.decode(CreateBallotOptionRequest.self)

        let election = try guardedElection(req, content: optionRequest)
        let ballotItem = BallotItem.find(optionRequest.itemID, on: req.db)
            .unwrap(or: Abort(.notFound))

        return election.and(ballotItem).flatMap { (election, ballotItem) in
            return ballotItem.$ballot.load(on: req.db).flatMap {
                do {
                    guard try ballotItem.ballot.$election.id == election.requireID() else {
                        throw Abort(.forbidden)
                    }
                    let option = try BallotOption(description: optionRequest.description,
                                                  value: optionRequest.value,
                                                  itemID: ballotItem.requireID())
                    return option.save(on: req.db).map { option }
                } catch  {
                    return req.eventLoop.makeFailedFuture(error)
                }
            }
        }
    }

    func submitVote(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let submissionRequest = try req.content.decode(SubmissionRequest.self)

        let voter = Voter.query(on: req.db).with(\.$election)
            .filter(\.$election.$id == submissionRequest.electionID)
            .filter(\.$votingKey == submissionRequest.voterKey)
            .filter(\.$hasVoted == false)
            .first().unwrap(or: Abort(.notFound))

        let submissions = submissionRequest.selectedOptionIDs.map { selectedID in
            return BallotOption.find(selectedID, on: req.db)
                .unwrap(or: Abort(.notFound)).flatMap { option in
                    return self.election(withID: submissionRequest.electionID,
                                    hasOption: option,
                                    db: req.db).flatMapThrowing { contains -> Submission in
                                        guard contains else {
                                            throw Abort(.forbidden)
                                        }
                                        return Submission(electionID: submissionRequest.electionID,
                                                          itemID: option.$parentItem.id,
                                                          selectionID: selectedID)

                    }

            }
        }.flatten(on: req.eventLoop)

        return voter.and(submissions).flatMap { (voter, submissions) in
            voter.hasVoted = true
            return voter.update(on: req.db).flatMap {
                return submissions.map { $0.save(on: req.db) }.flatten(on: req.eventLoop)
            }.transform(to: .ok)
        }
    }

    private func election(withID electionID: UUID, hasOption option: BallotOption, db: Database) -> EventLoopFuture<Bool> {
        return option.$parentItem.load(on: db).flatMap {
            return option.parentItem.$ballot.load(on: db).map {
                return option.parentItem.ballot.$election.id == electionID
            }
        }
    }

    private func guardedElection(_ req: Request, content: ElectionRequest) throws -> EventLoopFuture<Election> {
        // fetch auth'd user
        let user = try req.auth.require(User.self)

        return Election.find(content.electionID, on: req.db)
            .unwrap(or: Abort(.notFound)).flatMapThrowing { election in
                guard try election.$user.id == user.requireID() else {
                    throw Abort(.forbidden)
                }
                return election
        }
    }
}

// MARK: Content

struct CreateElectionRequest: Content {
    var description: String
}

protocol ElectionRequest {
    var electionID: UUID { get }
}

struct CreateVoterRequest: Content, ElectionRequest {
    var electionID: UUID

    var votingKey: String
    var name: String
}

struct CreateBallotRequest: Content, ElectionRequest {
    var electionID: UUID

    var description: String
}

struct CreateBallotItemRequest: Content, ElectionRequest {
    var electionID: UUID

    var ballotID: UUID
    var description: String
    var maxOptions: Int
    var minOptions: Int
}

struct CreateBallotOptionRequest: Content, ElectionRequest {
    var electionID: UUID

    var itemID: UUID
    var description: String
    var value: String
}

struct SubmissionRequest: Content {
    var voterKey: String
    var electionID: UUID

    var selectedOptionIDs: [UUID]
}
