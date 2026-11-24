import ServiceManagement
import SwiftUI

struct LoginItemControl: View {
    @State private var status: SMAppService.Status = .notRegistered
    @State private var changeFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Toggle("Ouvrir à la connexion", isOn: Binding(
                get: { status == .enabled || status == .requiresApproval },
                set: { requested in setEnabled(requested) }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .accessibilityIdentifier("launch-at-login")

            if status == .requiresApproval {
                Button("Autoriser dans Réglages Système") {
                    SMAppService.openSystemSettingsLoginItems()
                }
                .buttonStyle(.link)
                .font(.caption)
            }
            if changeFailed {
                Text("macOS a refusé la modification de l’ouverture automatique.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { status = SMAppService.mainApp.status }
    }

    private func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            changeFailed = false
        } catch {
            changeFailed = true
        }
        status = SMAppService.mainApp.status
    }
}
