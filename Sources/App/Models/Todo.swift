import Fluent
import Vapor

/// Todo model that conforms to `Model` and `Content` protocols
final class Todo: Model, Content {
    /// Schema name for the todos table
    static let schema = "todos"

    /// ID property for the todo, conforms to `ID` protocol
    @ID(key: .id)
    var id: UUID?

    /// Title property for the todo, conforms to `Field` protocol
    @Field(key: "title")
    var title: String

    /// Initializer for creating a new Todo instance
    init() { }

    /// Initializer for creating a new Todo instance with an ID and title
    ///
    /// - Parameters:
    ///   - id: Optional UUID for the todo
    ///   - title: Title of the todo
    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}
