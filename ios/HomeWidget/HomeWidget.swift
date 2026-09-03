import WidgetKit
import SwiftUI
import AppIntents

let appGroupId = "group.com.example.helloIosApp.shared"
let targetDeviceId = "9490AA29-9EDB-DDA0-B0DD-D9394D31FBF8"

func findTargetDevice() -> String? {
    let defaults = UserDefaults(suiteName: appGroupId)
    guard let devices = defaults?.stringArray(forKey: "deviceList") else { return nil }
    for device in devices {
        if device.contains(targetDeviceId) {
            return device
        }
    }
    return nil
}

struct CheckAndCopyIntent: AppIntent {
    static var title: LocalizedStringResource = "Cihazi Kontrol Et ve Kopyala"

    func perform() async throws -> some IntentResult {
        if let found = findTargetDevice() {
            UIPasteboard.general.string = found
        }
        return .result()
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), status: "Kontrol ediliyor...")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let status = findTargetDevice() ?? "Hedef cihaz yakinda degil"
        completion(SimpleEntry(date: Date(), status: status))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let status = findTargetDevice() ?? "Hedef cihaz yakinda degil"
        let entry = SimpleEntry(date: Date(), status: status)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let status: String
}

struct HomeWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 10) {
            Text("Hedef Cihaz")
                .font(.headline)

            Text(entry.status)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Button(intent: CheckAndCopyIntent()) {
                Text("Kontrol Et ve Kopyala")
                    .font(.subheadline)
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
        .configurationDisplayName("Hedef Cihaz Takip")
        .description("Hedef cihaz yakindaysa bilgisini kopyalar.")
        .supportedFamilies([.systemLarge])
    }
}
