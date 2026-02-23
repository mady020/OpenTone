import Foundation
internal import PostgREST
import Supabase

@MainActor
class CallRecordDataModel {

    static let shared: CallRecordDataModel = CallRecordDataModel()

    private var callRecords: [CallRecord] = []

    private init() {
        Task {
            await loadCallRecords()
        }
    }

    /// Clears in-memory data and reloads for the current user.
    func reloadForCurrentUser() {
        callRecords = []
        Task {
            await loadCallRecords()
        }
    }

    // MARK: - Read

    func getAllCallRecords() -> [CallRecord] {
        return callRecords
    }

    func getCallRecord(by id: UUID) -> CallRecord? {
        return callRecords.first { $0.id == id }
    }

    // MARK: - Write

    func addCallRecord(_ record: CallRecord) {
        callRecords.append(record)

        Task {
            await insertCallRecordInSupabase(record)
        }
    }

    func deleteCallRecord(by id: UUID) {
        callRecords.removeAll { $0.id == id }

        Task {
            await deleteCallRecordFromSupabase(id)
        }
    }

    // MARK: - Supabase Operations

    private func loadCallRecords() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }

        do {
            let rows: [CallRecordRow] = try await supabase
                .from(SupabaseTable.callRecords)
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("call_date", ascending: false)
                .execute()
                .value
            callRecords = rows.map { $0.toCallRecord() }
        } catch {
            print("❌ Failed to load call records: \(error.localizedDescription)")
            callRecords = []
        }
    }

    private func insertCallRecordInSupabase(_ record: CallRecord) async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }

        do {
            let row = CallRecordRow(from: record, userId: userId)
            try await supabase
                .from(SupabaseTable.callRecords)
                .insert(row)
                .execute()
        } catch {
            print("❌ Failed to insert call record: \(error.localizedDescription)")
        }
    }

    private func deleteCallRecordFromSupabase(_ id: UUID) async {
        do {
            try await supabase
                .from(SupabaseTable.callRecords)
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            print("❌ Failed to delete call record: \(error.localizedDescription)")
        }
    }
}
