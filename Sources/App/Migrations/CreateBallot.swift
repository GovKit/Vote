import Fluent

struct CreateBallot: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("ballots")
            .id()
            .field("description", .string)
            .field("election_id", .uuid, .references("elections", .id))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("ballots").delete()
    }
}
