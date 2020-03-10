import Fluent

struct CreateSubmission: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("submissions")
            .id()
            .field("election_id", .uuid, .references("elections", .id))
            .field("item_id", .uuid, .references("ballot_items", .id))
            .field("selection_id", .uuid, .references("ballot_options", .id))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("submissions").delete()
    }
}

