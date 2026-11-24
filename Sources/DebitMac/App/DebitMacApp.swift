import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let monitor = NetworkMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}

@main
struct DebitMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            TrafficPanel(monitor: delegate.monitor)
        } label: {
            MonitorStatusLabel(monitor: delegate.monitor)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MonitorStatusLabel: View {
    let monitor: NetworkMonitor

    var body: some View {
        Text(StatusText.menuLabel(rate: monitor.rate, total: monitor.today.total))
            .accessibilityLabel(StatusText.accessibilityLabel(rate: monitor.rate, total: monitor.today.total))
    }
}
