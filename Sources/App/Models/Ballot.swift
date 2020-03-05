import FluentSQLite
import Vapor

final class Ballot: SQLiteModel {
    var id: Int?
    var description: String

    var electionID: Election.ID

    init(id: Int? = nil, description: String, electionID: Election.ID) {
        self.id = id
        self.description = description
        self.electionID = electionID
    }
}

extension Ballot {
    var options: Children<Ballot, BallotItem> {
        return children(\.ballotID)
    }
}

extension Ballot: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(Ballot.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.description)
            builder.reference(from: \.electionID, to: \Election.id)
        }
    }
}

extension Ballot: Content { }
extension Ballot: Parameter { }
