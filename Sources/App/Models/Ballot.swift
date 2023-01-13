import Fluent
import Vapor

/// Ballot model that conforms to `Model` and `Content` protocols
final class Ballot: Model, Content {
    /// Schema name for the ballots table
    static let schema = "ballots"

    /// ID property for the ballot, conforms to `ID` protocol
    @ID(key: .id)
    var id: UUID?

    /// Description property for the ballot
    @Field(key: "description")
    var description: String

    /// Parent relationship to the Election model
    @Parent(key: "election_id")
    var election: Election

    /// Children relationship to the BallotItem model
    @Children(for: \.$ballot)
    var items: [BallotItem]

    /// Initializer for creating a new Ballot instance
    init() { }

    /// Initializer for creating a new Ballot instance with an ID, description and election ID
    ///
    /// - Parameters:
    ///   - id: Optional UUID for the ballot
    ///   - description: Description of the ballot
    ///   - electionID: UUID for the associated election
    init(id: UUID? = nil, description: String, electionID: UUID) {
        self.id = id
        self.description = description
        self.$election.id = electionID
    }
}
