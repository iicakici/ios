import WidgetKit
import SwiftUI
import AppIntents
import CoreBluetooth

class BLEListScanner: NSObject, CBCentralManagerDelegate {
    private var manager: CBCentralManager!
    private var continuation: CheckedContinuation<[String], Never>?
    private var foundDevices: [String: Int] = [:]

    func scanDevices() async -> [String] {
        return await withCheckedContinuation { cont in
            self.continuation = cont
            self.foundDevices = [:]
            self.manager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                central.stopScan()
                self.finishScan()
            }
        } else {
            continuation?.resume(returning: ["Bluetooth durumu: \(central.state.rawValue)"])
            continuation = nil
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        foundDevices[peripheral.identifier.uuidString] = RSSI.intValue
    }

    private func finishScan() {
        if foundDevices.isEmpty {
            continuation?.resume(returning: ["Cihaz bulunamadi (tarama tamamlandi)"])
        } else {
            let sorted = foundDevices.sorted { $0.value > $1.value }
                .prefix(8)
                .map { "\($0.key) (\($0.value) dBm)" }
            continuation?.resume(returning: Array(sorted))
        }
        continuation = nil
    }
}

struct ScanBLEIntent: AppIntent {
    static var title: LocalizedStringResource = "BLE Tara"

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(["V7 - Basildi - taraniyor..."], forKey: "deviceList")
        WidgetCenter.shared.reloadAllTimelines()

        let scanner = BLEListScanner()
        let result = await scanner.scanDevices()

        UserDefaults.standard.set(result, forKey: "deviceList")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct CopyDeviceInfoIntent: AppIntent {
    static var title: LocalizedStringResource = "Cihaz Bilgisini Kopyala"

    @Parameter(title: "Cihaz Bilgisi")
    var deviceInfo: String

    init() {}
    init(deviceInfo: String) {
        self.deviceInfo = deviceInfo
    }

    func perform() async throws -> some IntentResult {
        UIPasteboard.general.string = deviceInfo
        return .result()
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), devices: ["V7 - Kod Surumu: 2026-08-27-16:50"])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let devices = UserDefaults.standard.stringArray(forKey:"deviceList") ?? ["V7 - Kod Surumu: 2026-08-27-16:50"]
        completion(SimpleEntry(date: Date(), devices: devices))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let devices = UserDefaults.standard.stringArray(forKey:"deviceList") ?? ["V7 - Kod Surumu: 2026-08-27-16:50"]
        let entry = SimpleEntry(date: Date(), devices: devices)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let devices: [String]
}

struct HomeWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("BLE V7")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Button(intent: ScanBLEIntent()) {
                    Text("Tara")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            ForEach(entry.devices, id: \.self) { device in
                Button(intent: CopyDeviceInfoIntent(deviceInfo: device)) {
                    Text(device)
                        .font(.system(size: 9))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
    }
}

struct HomeWidget: Widget {
    let kind: String = "HomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HomeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("BLE V7")
        .description("Surum 7 - test.")
        .supportedFamilies([.systemLarge])
    }
}
