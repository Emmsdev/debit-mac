import Foundation
import Testing
import TrafficCore

@Test func addsBothDirectionsAcrossInterfacesWithoutChargingExistingCounters() {
    var accumulator = TrafficAccumulator()
    #expect(accumulator.ingest([
        "en0": .init(received: 100, sent: 20), "en1": .init(received: 30, sent: 50),
    ]) == .init())

    let delta = accumulator.ingest([
        "en0": .init(received: 160, sent: 22), "en1": .init(received: 31, sent: 52),
        "en2": .init(received: 1000, sent: 500),
    ])
    #expect(delta == .init(received: 61, sent: 4))
}

@Test func counterResetsAndReconnectsStartANewBaseline() {
    var accumulator = TrafficAccumulator()
    _ = accumulator.ingest(["en0": .init(received: 900, sent: 10)])
    #expect(accumulator.ingest(["en0": .init(received: 20, sent: 30)]) == .init(received: 0, sent: 20))
    #expect(accumulator.ingest([:]) == .init())
    #expect(accumulator.ingest(["en0": .init(received: 500, sent: 500)]) == .init())
}

@Test func ratesUseElapsedTimeAndDecimalMegabits() {
    #expect(TrafficRate(bytes: .init(received: 1_000_000, sent: 250_000), elapsed: 2).received == 4)
    #expect(TrafficRate(bytes: .init(received: 1_000_000, sent: 250_000), elapsed: 2).sent == 1)
}

@Test func ledgerPersistsAndRespectsLocalDayAndMonthBoundaries() throws {
    let before = try #require(ISO8601DateFormatter().date(from: "2026-11-30T22:59:59Z"))
    let after = before.addingTimeInterval(2)
    let nextDay = after.addingTimeInterval(86_400)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "Africa/Douala"))
    var ledger = UsageLedger()
    ledger.record(.init(received: 500, sent: 100), on: before, calendar: calendar)
    ledger.record(.init(received: 50, sent: 20), on: after, calendar: calendar)
    ledger.record(.init(received: 10, sent: 3), on: nextDay, calendar: calendar)
    let restored = try JSONDecoder().decode(UsageLedger.self, from: JSONEncoder().encode(ledger))
    #expect(restored.month(on: before, calendar: calendar) == .init(received: 500, sent: 100))
    #expect(restored.today(on: after, calendar: calendar) == .init(received: 50, sent: 20))
    #expect(restored.today(on: nextDay, calendar: calendar) == .init(received: 10, sent: 3))
    #expect(restored.month(on: nextDay, calendar: calendar) == .init(received: 60, sent: 23))
}

@Test func systemProviderReturnsOnlyPhysicalInterfaceKeys() throws {
    let interfaces = try DarwinTraffic.read()
    #expect(interfaces.keys.allSatisfy { $0.hasPrefix("en") && $0.contains("#") })
}

@Test func resetRequiresThreeClicksEveryTime() {
    var confirmation = UsageResetConfirmation()
    for _ in 0..<2 {
        let firstClick = confirmation.recordClick()
        #expect(!firstClick)
        #expect(confirmation.clicks == 1)

        let secondClick = confirmation.recordClick()
        #expect(!secondClick)
        #expect(confirmation.clicks == 2)

        let thirdClick = confirmation.recordClick()
        #expect(thirdClick)
        #expect(confirmation.clicks == 0)
    }
}
