import FluentSQLite
import Vapor

final class BallotOption: SQLiteModel {
    var id: Int?
    var description: String
    var value: String

    var itemID: BallotItem.ID

    init(id: Int? = nil, description: String, value: String, itemID: BallotItem.ID) {
        self.id = id
        self.description = description
        self.value = value
        self.itemID = itemID
    }
}

extension BallotOption: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(BallotOption.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.description)
            builder.field(for: \.value)
            builder.reference(from: \.itemID, to: \BallotItem.id)
        }
    }
}

extension BallotOption: Content { }
extension BallotOption: Parameter { }
