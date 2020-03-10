import Fluent

struct CreateBallotOption: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("ballot_options")
            .id()
            .field("description", .string)
            .field("value", .string)
            .field("item_id", .uuid, .references("ballot_items", .id))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("ballot_options").delete()
    }
}

