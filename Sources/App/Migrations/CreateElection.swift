import Fluent

struct CreateElection: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("elections")
            .id()
            .field("description", .string)
            .field("user_id", .uuid, .references("users", .id))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("elections").delete()
    }
}

