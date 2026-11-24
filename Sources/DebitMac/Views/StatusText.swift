import Foundation
import TrafficCore

enum StatusText {
    private static let locale = Locale(identifier: "fr_FR")

    static func menuLabel(rate: TrafficRate?, total: UInt64) -> String {
        let down = rate.map { speed($0.received) } ?? "–"
        let up = rate.map { speed($0.sent) } ?? "–"
        return "↓\(down) ↑\(up) Mb/s · \(volume(total))"
    }

    static func accessibilityLabel(rate: TrafficRate?, total: UInt64) -> String {
        guard let rate else { return "Débit Mac, mesure en attente, \(volume(total)) aujourd’hui" }
        return "Débit Mac, réception \(speed(rate.received)) mégabits par seconde, envoi \(speed(rate.sent)) mégabits par seconde, \(volume(total)) aujourd’hui"
    }

    static func speed(_ value: Double) -> String {
        let decimals = value >= 100 || value == 0 ? 0 : (value < 1 ? 2 : 1)
        return number(value, decimals: decimals)
    }

    static func volume(_ bytes: UInt64) -> String {
        let sizes = ["o", "Ko", "Mo", "Go", "To", "Po", "Eo"]
        var amount = Double(bytes)
        var index = 0
        while amount >= 1_000 && index < sizes.count - 1 {
            amount /= 1_000
            index += 1
        }
        let decimals = index == 0 || amount >= 100 ? 0 : 1
        return "\(number(amount, decimals: decimals)) \(sizes[index])"
    }

    private static func number(_ value: Double, decimals: Int) -> String {
        value.formatted(
            .number.locale(locale).grouping(.never).precision(.fractionLength(0...decimals))
        )
    }
}
