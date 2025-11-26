import Foundation

@MainActor
class CallRecordDataModel {

    static let shared: CallRecordDataModel = CallRecordDataModel()

    private let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!

    private let archiveURL: URL

    private var callRecords: [CallRecord] = []

    private init() {
        archiveURL =
            documentsDirectory
            .appendingPathComponent("callRecords")
            .appendingPathExtension("json")

        loadCallRecords()
    }

    func getAllCallRecords() -> [CallRecord] {
        return callRecords
    }

    func addCallRecord(_ record: CallRecord) {
        callRecords.append(record)
        saveCallRecords()
    }

    func deleteCallRecord(by id: UUID) {
        callRecords.removeAll { $0.id == id }
        saveCallRecords()
    }

    func getCallRecord(by id: UUID) -> CallRecord? {
        return callRecords.first { $0.id == id }
    }

    private func loadCallRecords() {
        if let saved = try? Data(contentsOf: archiveURL) {
            let decoder = JSONDecoder()
            callRecords = (try? decoder.decode([CallRecord].self, from: saved)) ?? []
        } else {
            callRecords = []
        }
    }

    private func saveCallRecords() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(callRecords) {
            try? data.write(to: archiveURL)
        }
    }
}
