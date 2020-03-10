import Fluent
import Vapor

final class Election: Model, Content {
    static let schema = "elections"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "description")
    var description: String

    @Parent(key: "user_id")
    var user: User

    @Children(for: \.$election)
    var ballots: [Ballot]

    @Children(for: \.$election)
    var voters: [Voter]

    @Children(for: \.$election)
    var submissions: [Submission]

    init() { }

    init(id: UUID? = nil, description: String, userID: UUID) {
        self.id = id
        self.description = description
        self.$user.id = userID
    }
}
