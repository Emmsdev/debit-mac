import SwiftUI
import TrafficCore

struct UsageResetControl: View {
    let reset: () -> Void

    @State private var confirmation = UsageResetConfirmation()
    @State private var didReset = false

    private var buttonTitle: String {
        confirmation.clicks == 0 ? "Réinitialiser les cumuls" : "Confirmer la remise à zéro"
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                didReset = confirmation.recordClick()
                if didReset { reset() }
            } label: {
                Label(buttonTitle, systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier("reset-usage")
            .accessibilityValue(accessibilityStatus)

            Spacer(minLength: 0)
            Text(progress)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .onDisappear {
            confirmation = UsageResetConfirmation()
            didReset = false
        }
    }

    private var progress: String {
        if didReset { return "Cumuls réinitialisés" }
        if confirmation.clicks == 0 { return "\(UsageResetConfirmation.requiredClicks) clics" }
        return "\(confirmation.clicks)/\(UsageResetConfirmation.requiredClicks)"
    }

    private var accessibilityStatus: String {
        if didReset { return "Cumuls réinitialisés" }
        return "\(confirmation.clicks) sur \(UsageResetConfirmation.requiredClicks) clics"
    }
}
