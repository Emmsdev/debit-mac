import Foundation

public struct TrafficBytes: Codable, Equatable, Sendable {
    public var received: UInt64
    public var sent: UInt64

    public init(received: UInt64 = 0, sent: UInt64 = 0) {
        self.received = received
        self.sent = sent
    }

    public var total: UInt64 {
        received + sent
    }

    public mutating func add(_ other: Self) {
        received += other.received
        sent += other.sent
    }

    public func increase(since previous: Self) -> Self {
        Self(
            received: received >= previous.received ? received - previous.received : 0,
            sent: sent >= previous.sent ? sent - previous.sent : 0
        )
    }
}

public struct TrafficRate: Equatable, Sendable {
    public let received: Double
    public let sent: Double

    public init(bytes: TrafficBytes, elapsed: TimeInterval) {
        received = Double(bytes.received) * 8 / elapsed / 1_000_000
        sent = Double(bytes.sent) * 8 / elapsed / 1_000_000
    }
}

public struct TrafficAccumulator: Sendable {
    private var previous: [String: TrafficBytes] = [:]

    public init() {}

    public mutating func ingest(_ interfaces: [String: TrafficBytes]) -> TrafficBytes {
        var delta = TrafficBytes()
        for (name, counters) in interfaces {
            if let last = previous[name] {
                delta.add(counters.increase(since: last))
            }
        }
        previous = interfaces
        return delta
    }
}
