import FluentSQLite
import Vapor

/// A voter
final class Voter: SQLiteModel {
    var id: Int?
    var name: String
    var hasVoted: Bool

    var electionID: Election.ID

    init(id: Int? = nil, name: String, hasVoted: Bool, electionID: Election.ID) {
        self.id = id
        self.name = name
        self.hasVoted = hasVoted
        self.electionID = electionID
    }
}

extension Voter: Migration {
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(Voter.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.name)
            builder.reference(from: \.electionID, to: \Election.id)
        }
    }
}

extension Voter: Content { }
extension Voter: Parameter { }
