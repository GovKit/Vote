import Fluent
import Vapor

final class Voter: Model, Content {
    static let schema = "voters"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "voting_key")
    var votingKey: String

    @Field(key: "name")
    var name: String

    @Field(key: "has_voted")
    var hasVoted: Bool

    @Parent(key: "election_id")
    var election: Election

    init() { }

    init(id: UUID? = nil,
         votingKey: String,
         name: String,
         hasVoted: Bool,
         electionID: UUID) {
        self.id = id
        self.votingKey = votingKey
        self.name = name
        self.hasVoted = hasVoted
        self.$election.id = electionID
    }
}
