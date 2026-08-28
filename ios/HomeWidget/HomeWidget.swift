import WidgetKit
import SwiftUI
import AppIntents
import CoreBluetooth

struct SimpleTestIntent: AppIntent {
    static var title: LocalizedStringResource = "Basit Test"

    func perform() async throws -> some IntentResult {
        let currentCount = UserDefaults.standard.integer(forKey: "tapCount")
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: "tapCount")

        // CBCentralManager olusturuyoruz ama hicbir sey yapmiyoruz
        let manager = CBCentralManager()
        UserDefaults.standard.set("Manager state: \(manager.state.rawValue)", forKey: "managerInfo")

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
            Text("V10 - CBCentralManager Testi")
                .font(.headline)

            Text("Sayac: \(entry.count)")
                .font(.title)
                .fontWeight(.bold)

            Text(entry.info)
                .font(.caption)

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
        .configurationDisplayName("BLE V10 Manager Test")
        .description("CBCentralManager olusturuluyor.")
        .supportedFamilies([.systemLarge])
    }
}
