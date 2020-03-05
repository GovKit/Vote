import FluentSQLite
import Vapor

final class Submission: SQLiteModel {
    var id: Int?

    var itemID: BallotItem.ID
    var selectionID: BallotOption.ID

    init(id: Int? = nil, itemID: BallotItem.ID, selectionID: BallotOption.ID) {
        self.id = id
        self.itemID = itemID
        self.selectionID = selectionID
    }
}

extension Submission {
    var item: Parent<Submission, BallotItem> {
        return parent(\.itemID)
    }

    var selection: Parent<Submission, BallotOption> {
        return parent(\.selectionID)
    }
}

extension Submission: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(Submission.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.reference(from: \.itemID, to: \BallotItem.id)
            builder.reference(from: \.selectionID, to: \BallotOption.id)

        }
    }
}

extension Submission: Content { }
extension Submission: Parameter { }
