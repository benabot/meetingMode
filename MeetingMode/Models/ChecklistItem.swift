import Foundation

struct ChecklistItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isRequired: Bool

    init(id: UUID = UUID(), title: String, isRequired: Bool = true) {
        self.id = id
        self.title = title
        self.isRequired = isRequired
    }
}
