import Fluent
import Vapor

final class Submission: Model, Content {
    static let schema = "submissions"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "election_id")
    var election: Election

    @Parent(key: "item_id")
    var item: BallotItem

    @Parent(key: "selection_id")
    var selection: BallotOption

    init() { }

    init(id: UUID? = nil,
         electionID: UUID,
         itemID: UUID,
         selectionID: UUID) {
        self.id = id
        self.$election.id = electionID
        self.$item.id = itemID
        self.$selection.id = selectionID
    }
}
