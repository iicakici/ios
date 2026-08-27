import WidgetKit
import SwiftUI
import AppIntents
import CoreBluetooth

class BLEDeviceReader: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var manager: CBCentralManager!
    private var continuation: CheckedContinuation<String, Never>?
    private var foundPeripherals: [(peripheral: CBPeripheral, rssi: Int)] = []
    private var targetPeripheral: CBPeripheral?

    func readDeviceName() async -> String {
        return await withCheckedContinuation { cont in
            self.continuation = cont
            self.foundPeripherals = []
            self.manager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                central.stopScan()
                self.connectToClosestDevice()
            }
        } else {
            finish(with: "Bluetooth kapali")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        foundPeripherals.append((peripheral, RSSI.intValue))
    }

    private func connectToClosestDevice() {
        guard !foundPeripherals.isEmpty else {
            finish(with: "Cihaz bulunamadi")
            return
        }
        let closest = foundPeripherals.max(by: { $0.rssi < $1.rssi })!
        targetPeripheral = closest.peripheral
        targetPeripheral?.delegate = self
        manager.connect(targetPeripheral!, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([CBUUID(string: "1800")])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        finish(with: "Baglanilamadi")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first else {
            finish(with: "Servis bulunamadi")
            return
        }
        peripheral.discoverCharacteristics([CBUUID(string: "2A00")], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristic = service.characteristics?.first else {
            finish(with: "Isim okunamadi")
            return
        }
        peripheral.readValue(for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value, let name = String(data: data, encoding: .utf8) {
            finish(with: name)
        } else {
            finish(with: "Isim okunamadi")
        }
    }

    private func finish(with result: String) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}

struct ReadDeviceNameIntent: AppIntent {
    static var title: LocalizedStringResource = "Cihaz Adini Oku"

    func perform() async throws -> some IntentResult {
        let reader = BLEDeviceReader()

        let result = await withTaskGroup(of: String.self) { group in
            group.addTask { await reader.readDeviceName() }
            group.addTask {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                return "Zaman asimi"
            }
            let first = await group.next() ?? "Hata"
            group.cancelAll()
            return first
        }

        UIPasteboard.general.string = result
        UserDefaults.standard.set(result, forKey: "lastDeviceName")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), deviceName: "Henuz okunmadi")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let name = UserDefaults.standard.string(forKey: "lastDeviceName") ?? "Henuz okunmadi"
        completion(SimpleEntry(date: Date(), deviceName: name))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let name = UserDefaults.standard.string(forKey: "lastDeviceName") ?? "Henuz okunmadi"
        let entry = SimpleEntry(date: Date(), deviceName: name)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let deviceName: String
}

struct HomeWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 6) {
            Text(entry.deviceName)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Button(intent: ReadDeviceNameIntent()) {
                Text("R")
                    .font(.headline)
                    .frame(width: 32, height: 32)
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
        .configurationDisplayName("BLE Cihaz Okuyucu")
        .description("En yakin Bluetooth cihazinin adini okuyup kopyalar.")
    }
}
