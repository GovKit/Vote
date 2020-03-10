import Fluent

struct CreateBallotItem: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("ballot_items")
            .id()
            .field("description", .string)
            .field("max_options", .int)
            .field("min_options", .int)
            .field("ballot_id", .uuid, .references("ballots", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("ballot_items").delete()
    }
}
