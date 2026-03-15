import Foundation

struct Preset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var iconSystemName: String
    var appsToLaunch: [String]
    var checklistItems: [ChecklistItem]
    var showsOverlay: Bool

    static let samples: [Preset] = [
        Preset(
            id: UUID(uuidString: "0E9D6B47-9348-4E28-A2A7-225C5F611001") ?? UUID(),
            name: "Client Call",
            iconSystemName: "person.2.fill",
            appsToLaunch: ["Calendar", "Notes", "Safari"],
            checklistItems: [
                ChecklistItem(title: "Open call brief"),
                ChecklistItem(title: "Check microphone"),
                ChecklistItem(title: "Close private tabs", isRequired: false),
            ],
            showsOverlay: true
        ),
        Preset(
            id: UUID(uuidString: "0E9D6B47-9348-4E28-A2A7-225C5F611002") ?? UUID(),
            name: "Product Demo",
            iconSystemName: "play.rectangle.fill",
            appsToLaunch: ["Xcode", "Safari", "Keynote"],
            checklistItems: [
                ChecklistItem(title: "Build latest demo"),
                ChecklistItem(title: "Prepare fallback browser tab"),
            ],
            showsOverlay: false
        ),
    ]
}
