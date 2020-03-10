import Fluent
import Vapor

final class BallotItem: Model, Content {
    static let schema = "ballot_items"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "description")
    var description: String

    @Field(key: "max_options")
    var maxOptions: Int

    @Field(key: "min_options")
    var minOptions: Int

    @Parent(key: "ballot_id")
    var ballot: Ballot

    @Children(for: \.$parentItem)
    var options: [BallotOption]

    init() { }
    
    init(id: UUID? = nil, description: String, maxOptions: Int, minOptions: Int, ballotID: UUID) {
        self.id = id
        self.description = description
        self.maxOptions = maxOptions
        self.minOptions = minOptions
        self.$ballot.id = ballotID
    }
}
