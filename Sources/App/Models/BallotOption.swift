import Fluent
import Vapor

final class BallotOption: Model, Content {
    static let schema = "ballot_options"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "description")
    var description: String

    @Field(key: "value")
    var value: String

    @Parent(key: "item_id")
    var parentItem: BallotItem

    init() { }

    init(id: UUID? = nil, description: String, value: String, itemID: UUID) {
        self.id = id
        self.description = description
        self.value = value
        self.$parentItem.id = itemID
    }
}
