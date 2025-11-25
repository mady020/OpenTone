//
//  ReportDataModel.swift
//  StoryboardsExample
//
//  Created by Harshdeep Singh on 05/11/25.
//

import Foundation

@MainActor
class ReportDataModel {
    
    static let shared = ReportDataModel()
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let archiveURL: URL
    
    private var reports: [Report] = []
    
    private init() {
        archiveURL = documentsDirectory.appendingPathComponent("reports").appendingPathExtension("json")
        loadReports()
    }
    

    
    func getAllReports() -> [Report] {
        return reports
    }
    
    func addReport(_ report: Report) {
        reports.append(report)
        saveReports()
    }
    
    func updateReport(_ report: Report) {
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = report
            saveReports()
        }
    }
    
    func deleteReport(at index: Int) {
        reports.remove(at: index)
        saveReports()
    }
    
    func deleteReport(by id: String) {
        reports.removeAll(where: { $0.id == id })
        saveReports()
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
    

    
    private func loadReports() {
        if let savedReports = loadReportsFromDisk() {
            reports = savedReports
        } else {
            reports = loadSampleReports()
        }
    }
    
    private func loadReportsFromDisk() -> [Report]? {
        guard let codedReports = try? Data(contentsOf: archiveURL) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode([Report].self, from: codedReports)
    }
    
    private func saveReports() {
        let encoder = JSONEncoder()
        let codedReports = try? encoder.encode(reports)
        try? codedReports?.write(to: archiveURL)
    }
    
    private func loadSampleReports() -> [Report] {
        // Return empty array as sample - reports should be created by users
        return []
    }
}

