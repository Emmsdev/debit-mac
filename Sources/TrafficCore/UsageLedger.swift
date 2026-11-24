import Foundation

public struct UsageLedger: Codable, Sendable {
    private var days: [String: TrafficBytes] = [:]

    public init() {}

    public mutating func record(_ bytes: TrafficBytes, on date: Date, calendar: Calendar) {
        guard bytes.received != 0 || bytes.sent != 0 else { return }
        days[Self.dayKey(for: date, calendar: calendar), default: TrafficBytes()].add(bytes)
    }

    public func today(on date: Date, calendar: Calendar) -> TrafficBytes {
        days[Self.dayKey(for: date, calendar: calendar), default: TrafficBytes()]
    }

    public func month(on date: Date, calendar: Calendar) -> TrafficBytes {
        let monthPrefix = Self.dayKey(for: date, calendar: calendar).prefix(8)
        return days.reduce(into: TrafficBytes()) { total, entry in
            if entry.key.hasPrefix(monthPrefix) {
                total.add(entry.value)
            }
        }
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0, components.month ?? 0, components.day ?? 0
        )
    }
}
