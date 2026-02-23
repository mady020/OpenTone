import Foundation
internal import PostgREST
import Supabase
@MainActor
class ReportDataModel {

    static let shared = ReportDataModel()

    private var reports: [Report] = []

    private init() {
        Task {
            await loadReports()
        }
    }

    // MARK: - Read

    func getAllReports() -> [Report] {
        return reports
    }

    func getReport(by id: String) -> Report? {
        return reports.first(where: { $0.id == id })
    }

    func getReports(byReporterUserID reporterUserID: String) -> [Report] {
        return reports.filter { $0.reporterUserID == reporterUserID }
    }

    func getReports(byReportedEntityID reportedEntityID: String) -> [Report] {
        return reports.filter { $0.reportedEntityID == reportedEntityID }
    }

    // MARK: - Write

    func addReport(_ report: Report) {
        reports.append(report)
        Task {
            await insertReportInSupabase(report)
        }
    }

    func updateReport(_ report: Report) {
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = report
            Task {
                await updateReportInSupabase(report)
            }
        }
    }

    func deleteReport(at index: Int) {
        let report = reports.remove(at: index)
        Task {
            await deleteReportFromSupabase(report.id)
        }
    }

    func deleteReport(by id: String) {
        reports.removeAll(where: { $0.id == id })
        Task {
            await deleteReportFromSupabase(id)
        }
    }

    // MARK: - Supabase Operations

    private func loadReports() async {
        do {
            let rows: [ReportRow] = try await supabase
                .from(SupabaseTable.reports)
                .select()
                .execute()
                .value
            reports = rows.map { $0.toReport() }
        } catch {
            print("❌ Failed to load reports: \(error.localizedDescription)")
            reports = []
        }
    }

    private func insertReportInSupabase(_ report: Report) async {
        do {
            let row = ReportRow(from: report)
            try await supabase
                .from(SupabaseTable.reports)
                .insert(row)
                .execute()
        } catch {
            print("❌ Failed to insert report: \(error.localizedDescription)")
        }
    }

    private func updateReportInSupabase(_ report: Report) async {
        do {
            let row = ReportRow(from: report)
            try await supabase
                .from(SupabaseTable.reports)
                .update(row)
                .eq("id", value: report.id)
                .execute()
        } catch {
            print("❌ Failed to update report: \(error.localizedDescription)")
        }
    }

    private func deleteReportFromSupabase(_ id: String) async {
        do {
            try await supabase
                .from(SupabaseTable.reports)
                .delete()
                .eq("id", value: id)
                .execute()
        } catch {
            print("❌ Failed to delete report: \(error.localizedDescription)")
        }
    }
}
