import Foundation

@MainActor
class SessionFeedbackDataModel {
    
    static let shared = SessionFeedbackDataModel()
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let archiveURL: URL
    
    private var sessionFeedbacks: [SessionFeedback] = []
    
    private init() {
        archiveURL = documentsDirectory.appendingPathComponent("sessionFeedbacks").appendingPathExtension("json")
        loadSessionFeedbacks()
    }
    
 
    
    func getAllSessionFeedbacks() -> [SessionFeedback] {
        return sessionFeedbacks
    }
    
    func addSessionFeedback(_ sessionFeedback: SessionFeedback) {
        sessionFeedbacks.append(sessionFeedback)
        saveSessionFeedbacks()
    }
    
    func updateSessionFeedback(_ sessionFeedback: SessionFeedback) {
        if let index = sessionFeedbacks.firstIndex(where: { $0.id == sessionFeedback.id }) {
            sessionFeedbacks[index] = sessionFeedback
            saveSessionFeedbacks()
        }
    }
    

    func deleteSessionFeedback(at index: Int) {
        sessionFeedbacks.remove(at: index)
        saveSessionFeedbacks()
    }
    
    func deleteSessionFeedback(by id: String) {
        sessionFeedbacks.removeAll(where: { $0.id == id })
        saveSessionFeedbacks()
    }
    
    func getSessionFeedback(by id: String) -> SessionFeedback? {
        return sessionFeedbacks.first(where: { $0.id == id })
    }
    
    func getSessionFeedbacks(by sessionId: UUID) -> [SessionFeedback] {
        return sessionFeedbacks.filter { $0.sessionId == sessionId }
    }
    

    private func loadSessionFeedbacks() {
        if let savedSessionFeedbacks = loadSessionFeedbacksFromDisk() {
            sessionFeedbacks = savedSessionFeedbacks
        } else {
            sessionFeedbacks = loadSampleSessionFeedbacks()
        }
    }
    
    private func loadSessionFeedbacksFromDisk() -> [SessionFeedback]? {
        guard let codedSessionFeedbacks = try? Data(contentsOf: archiveURL) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode([SessionFeedback].self, from: codedSessionFeedbacks)
    }
    
    private func saveSessionFeedbacks() {
        let encoder = JSONEncoder()
        let codedSessionFeedbacks = try? encoder.encode(sessionFeedbacks)
        try? codedSessionFeedbacks?.write(to: archiveURL)
    }
    
    private func loadSampleSessionFeedbacks() -> [SessionFeedback] {
        return []
    }
}

