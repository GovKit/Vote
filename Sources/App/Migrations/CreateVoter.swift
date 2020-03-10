import Fluent

struct CreateVoter: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("voters")
            .id()
            .field("voting_key", .string)
            .field("name", .string)
            .field("has_voted", .bool)
            .field("election_id", .uuid, .references("elections", .id))
            .unique(on: "voting_key")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("voters").delete()
    }
}
