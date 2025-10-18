import Foundation
import Network

final class NetworkWatcher {
    private let monitor = NWPathMonitor()
    func start() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied { print("Network OK") }
            else { print("Network lost") }
        }
        monitor.start(queue: DispatchQueue(label: "net"))
    }
}