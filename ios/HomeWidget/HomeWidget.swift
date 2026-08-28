import WidgetKit
import SwiftUI
import AppIntents
import CoreBluetooth

class DelegateTester: NSObject, CBCentralManagerDelegate {
    var manager: CBCentralManager!
    var continuation: CheckedContinuation<String, Never>?

    func waitForState() async -> String {
        return await withCheckedContinuation { cont in
            self.continuation = cont
            self.manager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        continuation?.resume(returning: "Delegate calisti! State: \(central.state.rawValue)")
        continuation = nil
    }
}

struct SimpleTestIntent: AppIntent {
    static var title: LocalizedStringResource = "Basit Test"

    func perform() async throws -> some IntentResult {
        let currentCount = UserDefaults.standard.integer(forKey: "tapCount")
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: "tapCount")
        UserDefaults.standard.set("Delegate bekleniyor...", forKey: "managerInfo")
        WidgetCenter.shared.reloadAllTimelines()

        let tester = DelegateTester()

        let result = await withTaskGroup(of: String.self) { group in
            group.addTask { await tester.waitForState() }
            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                return "TIMEOUT - delegate 5 saniyede calismadi"
            }
            let first = await group.next() ?? "Hata"
            group.cancelAll()
            return first
        }

        UserDefaults.standard.set(result, forKey: "managerInfo")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), count: 0, info: "-")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let count = UserDefaults.standard.integer(forKey: "tapCount")
        let info = UserDefaults.standard.string(forKey: "managerInfo") ?? "-"
        completion(SimpleEntry(date: Date(), count: count, info: info))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let count = UserDefaults.standard.integer(forKey: "tapCount")
        let info = UserDefaults.standard.string(forKey: "managerInfo") ?? "-"
        let entry = SimpleEntry(date: Date(), count: count, info: info)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let count: Int
    let info: String
}

struct HomeWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 10) {
            Text("V11 - Delegate Testi")
                .font(.headline)

            Text("Sayac: \(entry.count)")
                .font(.title)
                .fontWeight(.bold)

            Text(entry.info)
                .font(.caption)
                .multilineTextAlignment(.center)

            Button(intent: SimpleTestIntent()) {
                Text("ARTTIR")
                    .font(.headline)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct HomeWidget: Widget {
    let kind: String = "HomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HomeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("BLE V11 Delegate Test")
        .description("Delegate callback bekleniyor.")
        .supportedFamilies([.systemLarge])
    }
}
