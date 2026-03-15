import SwiftUI

struct SettingsView: View {
    @ObservedObject var permissionService: PermissionService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Project Status") {
                    Text("Technical scaffold only. Launch, overlay, restore, permissions, and persistence remain intentionally minimal.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Permissions") {
                    VStack(alignment: .leading, spacing: 12) {
                        permissionRow(
                            title: "Accessibility",
                            status: permissionService.accessibilityStatus,
                            note: "Needed later to drive app visibility and focused restore flows."
                        )
                        permissionRow(
                            title: "Automation",
                            status: permissionService.automationStatus,
                            note: "Reserved for future app launch and control logic."
                        )
                        permissionRow(
                            title: "Screen Recording",
                            status: permissionService.screenRecordingStatus,
                            note: "May be required later if overlay or capture-related behavior needs it."
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Scope Guardrails") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("One active session at a time.")
                        Text("No persistence layer yet.")
                        Text("No app automation beyond stubs.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 480, minHeight: 340)
        .onAppear {
            permissionService.refreshStatuses()
        }
    }

    private func permissionRow(title: String, status: PermissionStatus, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Text(status.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(note)
                .foregroundStyle(.secondary)

            Text(status.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView(permissionService: PermissionService())
}
