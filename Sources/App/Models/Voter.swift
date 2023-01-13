import Fluent
import Vapor

/// Voter model that conforms to `Model` and `Content` protocols
final class Voter: Model, Content {
    /// Schema name for the voters table
    static let schema = "voters"

    /// ID property for the voter, conforms to `ID` protocol
    @ID(key: .id)
    var id: UUID?

    /// Voting key property for the voter
    @Field(key: "voting_key")
    var votingKey: String

    /// Name property for the voter
    @Field(key: "name")
    var name: String

    /// HasVoted property for the voter
    @Field(key: "has_voted")
    var hasVoted: Bool

    /// Parent relationship to the Election model
    @Parent(key: "election_id")
    var election: Election

    /// Initializer for creating a new Voter instance
    init() { }

    /// Initializer for creating a new Voter instance with an ID, voting key, name, hasVoted and election ID
    ///
    /// - Parameters:
    ///   - id: Optional UUID for the voter
    ///   - votingKey: voting key of the voter
    ///   - name: Name of the voter
    ///   - hasVoted: Boolean indicating if the voter has voted or not
    ///   - electionID: UUID for the associated election
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
