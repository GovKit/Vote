import Fluent
import Vapor

final class Ballot: Model, Content {
    static let schema = "ballots"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "description")
    var description: String

    @Parent(key: "election_id")
    var election: Election

    @Children(for: \.$ballot)
    var items: [BallotItem]

    init() { }

    init(id: UUID? = nil, description: String, electionID: UUID) {
        self.id = id
        self.description = description
        self.$election.id = electionID
    }
}
