import AppKit
import SwiftUI
import TrafficCore

private enum Palette {
    static let ember = Color(red: 0.74, green: 0.27, blue: 0.08)
    static let apricot = Color(red: 1.0, green: 0.57, blue: 0.32)
    static let amber = Color(red: 1.0, green: 0.79, blue: 0.54)
}

struct TrafficPanel: View {
    let monitor: NetworkMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(alignment: .leading, spacing: 8) {
                Text("Débit instantané")
                    .font(.subheadline.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                rateCards
                if monitor.history.count >= 2 {
                    RateChart(rates: monitor.history)
                        .frame(height: 47)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Consommation")
                    .font(.subheadline.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                usage
                UsageResetControl { monitor.resetUsage() }
            }

            LoginItemControl()

            HStack(spacing: 8) {
                Text("Wi-Fi et Ethernet de ce Mac")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quitter", systemImage: "power")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding(18)
        .frame(width: 372)
        .preferredColorScheme(.dark)
        .background(alignment: .topLeading) {
            RadialGradient(
                colors: [Palette.ember.opacity(0.32), Palette.ember.opacity(0.07), .clear],
                center: .topLeading, startRadius: 0, endRadius: 330
            )
            .allowsHitTesting(false)
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            Image(systemName: "waveform.path")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.amber)
                .frame(width: 42, height: 42)
                .monitorGlass(tint: Palette.ember, radius: 14)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Débit Mac")
                    .font(.system(size: 21, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Label(monitor.state.label, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(monitor.state == .online ? Palette.amber : .secondary)
                    .labelStyle(IndicatorLabel())
            }
        }
    }

    @ViewBuilder private var rateCards: some View {
        if #available(macOS 26, *) {
            GlassEffectContainer(spacing: 10) {
                ratePair
            }
        } else {
            ratePair
        }
    }

    private var ratePair: some View {
        HStack(spacing: 9) {
            rateCard("Réception", icon: "arrow.down", speed: monitor.rate?.received, tint: Palette.apricot)
            rateCard("Envoi", icon: "arrow.up", speed: monitor.rate?.sent, tint: Palette.amber)
        }
    }

    private func rateCard(_ title: String, icon: String, speed: Double?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(speed.map { StatusText.speed($0) } ?? "–")
                    .font(.system(size: 25, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text("Mb/s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .monitorGlass(tint: Palette.ember, radius: 17)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(speed.map { "\(StatusText.speed($0)) mégabits par seconde" } ?? "Mesure en attente")
    }

    private var usage: some View {
        VStack(spacing: 8) {
            usageRow("Aujourd’hui", bytes: monitor.today)
            Divider().overlay(Palette.amber.opacity(0.11))
            usageRow("Ce mois-ci", bytes: monitor.month)
        }
        .padding(11)
        .monitorGlass(tint: Palette.ember.opacity(0.6), radius: 17)
    }

    private func usageRow(_ period: String, bytes: TrafficBytes) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(period).font(.callout.weight(.semibold))
                Text("↓ \(StatusText.volume(bytes.received))  ↑ \(StatusText.volume(bytes.sent))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
            Text(StatusText.volume(bytes.total))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(period)
        .accessibilityValue("\(StatusText.volume(bytes.total)) au total, \(StatusText.volume(bytes.received)) reçus, \(StatusText.volume(bytes.sent)) envoyés")
    }
}

private struct IndicatorLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon.font(.system(size: 6))
                .accessibilityHidden(true)
            configuration.title
        }
    }
}

private struct RateChart: View {
    let rates: [TrafficRate]

    var body: some View {
        Canvas { context, size in
            let maximum = max(0.01, rates.map { max($0.received, $0.sent) }.max() ?? 0)
            let height = size.height - 5
            let width = size.width - 8
            var baseline = Path()
            baseline.move(to: CGPoint(x: 4, y: height))
            baseline.addLine(to: CGPoint(x: size.width - 4, y: height))
            context.stroke(baseline, with: .color(.white.opacity(0.12)))

            for (key, color) in [(\TrafficRate.received, Palette.apricot), (\TrafficRate.sent, Palette.amber)] {
                let points = rates.enumerated().map { index, sample in
                    CGPoint(
                        x: 4 + width * Double(index) / Double(rates.count - 1),
                        y: height - (height - 4) * sample[keyPath: key] / maximum
                    )
                }
                var line = Path()
                line.addLines(points)
                context.stroke(line, with: .color(color.opacity(0.85)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            }
        }
        .padding(.horizontal, 6)
    }
}

private extension View {
    @ViewBuilder func monitorGlass(tint: Color, radius: CGFloat) -> some View {
        if #available(macOS 26, *) {
            glassEffect(.regular.tint(tint.opacity(0.30)), in: .rect(cornerRadius: radius))
        } else {
            background(.regularMaterial, in: .rect(cornerRadius: radius))
                .overlay {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(tint.opacity(0.13))
                        .allowsHitTesting(false)
                }
        }
    }
}
