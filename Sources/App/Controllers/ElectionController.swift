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

    func index(_ req: Request) throws -> EventLoopFuture<[Election]> {
        return Election.query(on: req.db).all()
    }

    func createVoter(_ req: Request) throws -> EventLoopFuture<Voter> {
        guard let electionID = req.parameters.get("electionID", as: UUID.self) else {
            throw Abort(.notFound)
        }
        let user = try req.auth.require(User.self)

        let voterRequest = try req.content.decode(CreateVoterRequest.self)

        return try guardedElection(req, id: electionID).flatMap { election in
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

    func indexVoters(_ req: Request) throws -> EventLoopFuture<[Voter]> {
        guard let electionID = req.parameters.get("electionID", as: UUID.self) else {
            throw Abort(.notFound)
        }

        return Voter.query(on: req.db)
            .filter(\.$election.$id == electionID).all()
    }

    func createBallot(_ req: Request) throws -> EventLoopFuture<Ballot> {
        guard let electionID = req.parameters.get("electionID", as: UUID.self) else {
            throw Abort(.notFound)
        }
        let user = try req.auth.require(User.self)

        let ballotRequest = try req.content.decode(CreateBallotRequest.self)

        return try guardedElection(req, id: electionID).flatMap { election in
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

    func indexBallots(_ req: Request) throws -> EventLoopFuture<[Ballot]> {
        guard let electionID = req.parameters.get("electionID", as: UUID.self) else {
            throw Abort(.notFound)
        }

        return Ballot.query(on: req.db)
            .filter(\.$election.$id == electionID).all()
    }

    func indexSubmissions(_ req: Request) throws -> EventLoopFuture<[Submission]> {
        guard let electionID = req.parameters.get("electionID", as: UUID.self) else {
            throw Abort(.notFound)
        }

        return Submission.query(on: req.db)
            .filter(\.$election.$id == electionID).all()
    }

    func createBallotItem(_ req: Request) throws -> EventLoopFuture<BallotItem> {
        guard let electionID = req.parameters.get("electionID", as: UUID.self),
            let ballotID = req.parameters.get("ballotID", as: UUID.self) else {
                throw Abort(.notFound)
        }

        let itemRequest = try req.content.decode(CreateBallotItemRequest.self)

        let election = try guardedElection(req, id: electionID)
        let ballot = Ballot.find(ballotID, on: req.db)
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

    func indexBallotItems(_ req: Request) throws -> EventLoopFuture<[BallotItem]> {
        guard let ballotID = req.parameters.get("ballotID", as: UUID.self) else {
            throw Abort(.notFound)
        }

        return BallotItem.query(on: req.db)
            .filter(\.$ballot.$id == ballotID).all()
    }

    func createBallotOption(_ req: Request) throws -> EventLoopFuture<BallotOption> {
        guard let electionID = req.parameters.get("electionID", as: UUID.self),
            let itemID = req.parameters.get("ballotItemID", as: UUID.self) else {
                throw Abort(.notFound)
        }
        let optionRequest = try req.content.decode(CreateBallotOptionRequest.self)

        let election = try guardedElection(req, id: electionID)
        let ballotItem = BallotItem.find(itemID, on: req.db)
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

    func indexBallotOptions(_ req: Request) throws -> EventLoopFuture<[BallotOption]> {
        guard let ballotItemID = req.parameters.get("ballotItemID", as: UUID.self) else {
            throw Abort(.notFound)
        }

        return BallotOption.query(on: req.db)
            .filter(\.$parentItem.$id == ballotItemID).all()
    }

    func submitVote(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let electionID = req.parameters.get("electionID", as: UUID.self) else {
                throw Abort(.notFound)
        }
        let submissionRequest = try req.content.decode(SubmissionRequest.self)

        let voter = Voter.query(on: req.db).with(\.$election)
            .filter(\.$election.$id == electionID)
            .filter(\.$votingKey == submissionRequest.voterKey)
            .filter(\.$hasVoted == false)
            .first().unwrap(or: Abort(.notFound))

        let submissions = submissionRequest.selectedOptionIDs.map { selectedID in
            return BallotOption.find(selectedID, on: req.db)
                .unwrap(or: Abort(.notFound)).flatMap { option in
                    return self.election(withID: electionID,
                                    hasOption: option,
                                    db: req.db).flatMapThrowing { contains -> Submission in
                                        guard contains else {
                                            throw Abort(.forbidden)
                                        }
                                        return Submission(electionID: electionID,
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

    private func guardedElection(_ req: Request, id: UUID) throws -> EventLoopFuture<Election> {
        // fetch auth'd user
        let user = try req.auth.require(User.self)

        return Election.find(id, on: req.db)
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

struct CreateVoterRequest: Content {
    var votingKey: String
    var name: String
}

struct CreateBallotRequest: Content {
    var description: String
}

struct CreateBallotItemRequest: Content {
    var description: String
    var maxOptions: Int
    var minOptions: Int
}

struct CreateBallotOptionRequest: Content {
    var description: String
    var value: String
}

struct SubmissionRequest: Content {
    var voterKey: String
    var selectedOptionIDs: [UUID]
}
