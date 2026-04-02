import Foundation

struct DifficultWordEntry: Codable, Equatable, Identifiable {
    let id: UUID
    var phrase: String
    var plainReason: String
    var technicalHint: String?
    var source: String
    var attempts: Int
    var improvements: Int
    var lastScore: Float?
    var bestScore: Float?
    var scoreHistory: [Float]
    var createdAt: Date
    var updatedAt: Date

    var trendDelta: Float? {
        guard scoreHistory.count >= 2 else { return nil }
        return scoreHistory[scoreHistory.count - 1] - scoreHistory[scoreHistory.count - 2]
    }
}

final class DifficultWordsStore {

    static let shared = DifficultWordsStore()

    private let defaults: UserDefaults
    private let now: () -> Date

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
    }

    func all() -> [DifficultWordEntry] {
        loadEntries().sorted { $0.updatedAt > $1.updatedAt }
    }

    func saveOrUpdate(
        phrase: String,
        plainReason: String,
        technicalHint: String?,
        source: String
    ) {
        let normalizedPhrase = normalizePhrase(phrase)
        guard !normalizedPhrase.isEmpty else { return }

        var entries = loadEntries()
        let timestamp = now()

        if let idx = entries.firstIndex(where: { normalizePhrase($0.phrase) == normalizedPhrase }) {
            var existing = entries[idx]
            existing.plainReason = plainReason
            existing.technicalHint = technicalHint
            existing.source = source
            existing.updatedAt = timestamp
            entries[idx] = existing
        } else {
            entries.append(
                DifficultWordEntry(
                    id: UUID(),
                    phrase: phrase,
                    plainReason: plainReason,
                    technicalHint: technicalHint,
                    source: source,
                    attempts: 0,
                    improvements: 0,
                    lastScore: nil,
                    bestScore: nil,
                    scoreHistory: [],
                    createdAt: timestamp,
                    updatedAt: timestamp
                )
            )
        }

        saveEntries(entries)
    }

    func recordPractice(phrase: String, score: Float, issueSummary: String?) {
        let normalizedPhrase = normalizePhrase(phrase)
        guard !normalizedPhrase.isEmpty else { return }

        var entries = loadEntries()
        let timestamp = now()

        if let idx = entries.firstIndex(where: { normalizePhrase($0.phrase) == normalizedPhrase }) {
            var existing = entries[idx]
            let previousScore = existing.lastScore

            existing.attempts += 1
            existing.lastScore = score
            existing.bestScore = max(existing.bestScore ?? score, score)
            existing.scoreHistory.append(score)
            if existing.scoreHistory.count > 20 {
                existing.scoreHistory.removeFirst(existing.scoreHistory.count - 20)
            }
            if let previousScore, score >= previousScore + 3 {
                existing.improvements += 1
            }
            if let issueSummary, !issueSummary.isEmpty {
                existing.plainReason = issueSummary
            }
            existing.updatedAt = timestamp
            entries[idx] = existing
        } else {
            let reason = issueSummary ?? "Needs targeted pronunciation practice."
            entries.append(
                DifficultWordEntry(
                    id: UUID(),
                    phrase: phrase,
                    plainReason: reason,
                    technicalHint: nil,
                    source: "practice",
                    attempts: 1,
                    improvements: 0,
                    lastScore: score,
                    bestScore: score,
                    scoreHistory: [score],
                    createdAt: timestamp,
                    updatedAt: timestamp
                )
            )
        }

        saveEntries(entries)
    }

    func remove(id: UUID) {
        var entries = loadEntries()
        entries.removeAll { $0.id == id }
        saveEntries(entries)
    }

    func clear() {
        defaults.removeObject(forKey: storageKey())
    }

    private func storageKey() -> String {
        let userId = UserDataModel.shared.getCurrentUser()?.id.uuidString ?? "anonymous"
        return "opentone.difficultWords.\(userId)"
    }

    private func loadEntries() -> [DifficultWordEntry] {
        guard let data = defaults.data(forKey: storageKey()) else { return [] }
        return (try? JSONDecoder().decode([DifficultWordEntry].self, from: data)) ?? []
    }

    private func saveEntries(_ entries: [DifficultWordEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: storageKey())
        }
    }

    private func normalizePhrase(_ phrase: String) -> String {
        phrase
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
