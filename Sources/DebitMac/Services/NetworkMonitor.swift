import Foundation
import Observation
import TrafficCore

@MainActor
@Observable
final class NetworkMonitor {
    enum State {
        case warmingUp
        case online
        case noInterface
        case unavailable

        var label: String {
            switch self {
            case .warmingUp: "Mesure en cours"
            case .online: "En direct"
            case .noInterface: "Aucune interface"
            case .unavailable: "Mesure indisponible"
            }
        }
    }

    private(set) var state: State = .warmingUp
    private(set) var rate: TrafficRate?
    private(set) var today = TrafficBytes()
    private(set) var month = TrafficBytes()
    private(set) var history: [TrafficRate] = []
    @ObservationIgnored private var interfaceCount = 0

    @ObservationIgnored private var accumulator = TrafficAccumulator()
    @ObservationIgnored private var ledger: UsageLedger
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var lastSample: ContinuousClock.Instant?
    @ObservationIgnored private var lastSave = ContinuousClock.now
    @ObservationIgnored private var unsaved = false
    private static let storageKey = "usage-ledger-v1"

    init() {
        ledger = UserDefaults.standard.data(forKey: Self.storageKey)
            .flatMap { try? JSONDecoder().decode(UsageLedger.self, from: $0) }
            ?? UsageLedger()
        updateTotals(at: Date(), calendar: localCalendar)
    }

    func start() {
        guard task == nil else { return }
        sample()
        task = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    break
                }
                guard let self else { break }
                self.sample()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        save()
    }

    func resetUsage() {
        ledger = UsageLedger()
        accumulator = TrafficAccumulator()
        lastSample = nil
        history.removeAll()
        unsaved = true
        sample()
        save()
    }

    private func sample() {
        let clock = ContinuousClock.now
        let date = Date()
        let calendar = localCalendar
        defer {
            updateTotals(at: date, calendar: calendar)
            if lastSave.duration(to: clock) >= .seconds(5) { save() }
        }

        let interfaces: [String: TrafficBytes]
        do {
            interfaces = try DarwinTraffic.read()
        } catch {
            state = .unavailable
            rate = nil
            history.removeAll()
            return
        }

        let hadInterfaces = interfaceCount > 0
        interfaceCount = interfaces.count
        let delta = accumulator.ingest(interfaces)
        if delta.total > 0 {
            ledger.record(delta, on: date, calendar: calendar)
            unsaved = true
        }
        let last = lastSample
        lastSample = clock

        guard !interfaces.isEmpty else {
            state = .noInterface
            rate = nil
            history.removeAll()
            return
        }
        guard hadInterfaces, let last else {
            state = .warmingUp
            rate = nil
            return
        }
        let interval = last.duration(to: clock)
        guard interval > .zero, interval <= .seconds(3) else {
            state = .warmingUp
            rate = nil
            history.removeAll()
            return
        }

        let parts = interval.components
        let elapsed = Double(parts.seconds) + Double(parts.attoseconds) / 1e18
        let current = TrafficRate(bytes: delta, elapsed: elapsed)
        rate = current
        state = .online
        history.append(current)
        if history.count > 45 { history.removeFirst() }
    }

    private var localCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    private func updateTotals(at date: Date, calendar: Calendar) {
        today = ledger.today(on: date, calendar: calendar)
        month = ledger.month(on: date, calendar: calendar)
    }

    private func save() {
        lastSave = .now
        guard unsaved, let data = try? JSONEncoder().encode(ledger) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
        unsaved = false
    }
}
