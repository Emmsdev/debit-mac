public struct UsageResetConfirmation: Sendable {
    public static let requiredClicks = 3
    public private(set) var clicks = 0

    public init() {}

    public mutating func recordClick() -> Bool {
        clicks += 1
        if clicks == Self.requiredClicks {
            clicks = 0
            return true
        }
        return false
    }
}
