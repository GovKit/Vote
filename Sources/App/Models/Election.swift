import FluentSQLite
import Vapor

final class Election: SQLiteModel {
    var id: Int?
    var description: String

    init(id: Int? = nil, description: String) {
        self.id = id
        self.description = description
    }
}

extension Election {
    var ballots: Children<Election, Ballot> {
        return children(\.electionID)
    }

    var voters: Children<Election, Voter> {
        return children(\.electionID)
    }
}

extension Election: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(Ballot.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.description)
        }
    }
}

extension Election: Content { }
extension Election: Parameter { }
