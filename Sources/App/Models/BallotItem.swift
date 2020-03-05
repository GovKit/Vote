import FluentSQLite
import Vapor

final class BallotItem: SQLiteModel {
    var id: Int?
    var description: String
    var maxOptions: Int
    var minOptions: Int

    var ballotID: Ballot.ID

    init(id: Int? = nil, description: String, maxOptions: Int, minOptions: Int, ballotID: Ballot.ID) {
        self.id = id
        self.description = description
        self.maxOptions = maxOptions
        self.minOptions = minOptions
        self.ballotID = ballotID
    }
}

extension BallotItem {
    var options: Children<BallotItem, BallotOption> {
        return children(\.itemID)
    }
}

extension BallotItem: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(BallotItem.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.description)
            builder.field(for: \.maxOptions)
            builder.field(for: \.minOptions)
            builder.reference(from: \.ballotID, to: \Ballot.id)
        }
    }
}

extension BallotItem: Content { }
extension BallotItem: Parameter { }
