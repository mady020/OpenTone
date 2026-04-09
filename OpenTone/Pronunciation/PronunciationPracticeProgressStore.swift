import Foundation

struct PronunciationPracticeProgress: Codable {
    var totalXP: Int
    var currentStreak: Int
    var longestStreak: Int
    var sessionsCompleted: Int
    var lastPracticeDate: Date?
    var unlockedBadges: [PracticeBadge]

    static let empty = PronunciationPracticeProgress(
        totalXP: 0,
        currentStreak: 0,
        longestStreak: 0,
        sessionsCompleted: 0,
        lastPracticeDate: nil,
        unlockedBadges: []
    )
}

enum PracticeBadge: String, Codable, CaseIterable {
    case firstTry
    case threeDayStreak
    case tenSessions
    case hundredXP
    case clearSpeaker

    var title: String {
        switch self {
        case .firstTry: return "First Step"
        case .threeDayStreak: return "3-Day Streak"
        case .tenSessions: return "Practice Machine"
        case .hundredXP: return "100 XP Club"
        case .clearSpeaker: return "Clear Speaker"
        }
    }

    var icon: String {
        switch self {
        case .firstTry: return "STAR"
        case .threeDayStreak: return "FIRE"
        case .tenSessions: return "TARGET"
        case .hundredXP: return "XP"
        case .clearSpeaker: return "VOICE"
        }
    }
}

final class PronunciationPracticeProgressStore {

    struct ProgressUpdate {
        let progress: PronunciationPracticeProgress
        let xpEarned: Int
        let newlyUnlockedBadges: [PracticeBadge]
    }

    static let shared = PronunciationPracticeProgressStore()

    private let defaults: UserDefaults
    private let now: () -> Date

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
    }

    func load() -> PronunciationPracticeProgress {
        guard let data = defaults.data(forKey: storageKey()) else {
            return .empty
        }
        return (try? JSONDecoder().decode(PronunciationPracticeProgress.self, from: data)) ?? .empty
    }

    @discardableResult
    func recordPractice(overallScore: Float, difficultWordsCount: Int) -> ProgressUpdate {
        var progress = load()
        let timestamp = now()

        let baseXP = 10
        let scoreBonus: Int
        if overallScore >= 85 {
            scoreBonus = 10
        } else if overallScore >= 70 {
            scoreBonus = 6
        } else if overallScore >= 55 {
            scoreBonus = 3
        } else {
            scoreBonus = 1
        }

        let focusBonus = difficultWordsCount > 0 ? 2 : 0
        let xpEarned = baseXP + scoreBonus + focusBonus

        progress.totalXP += xpEarned
        progress.sessionsCompleted += 1

        let calendar = Calendar.current
        if let lastDate = progress.lastPracticeDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let today = calendar.startOfDay(for: timestamp)
            let delta = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if delta == 0 {
                // Keep today's streak value unchanged.
            } else if delta == 1 {
                progress.currentStreak += 1
            } else {
                progress.currentStreak = 1
            }
        } else {
            progress.currentStreak = 1
        }

        progress.longestStreak = max(progress.longestStreak, progress.currentStreak)
        progress.lastPracticeDate = timestamp

        let newlyUnlocked = unlockBadges(progress: &progress, overallScore: overallScore)
        save(progress)

        return ProgressUpdate(progress: progress, xpEarned: xpEarned, newlyUnlockedBadges: newlyUnlocked)
    }

    private func unlockBadges(progress: inout PronunciationPracticeProgress, overallScore: Float) -> [PracticeBadge] {
        var newlyUnlocked: [PracticeBadge] = []

        func unlock(_ badge: PracticeBadge, when condition: Bool) {
            guard condition else { return }
            guard !progress.unlockedBadges.contains(badge) else { return }
            progress.unlockedBadges.append(badge)
            newlyUnlocked.append(badge)
        }

        unlock(.firstTry, when: progress.sessionsCompleted >= 1)
        unlock(.threeDayStreak, when: progress.currentStreak >= 3)
        unlock(.tenSessions, when: progress.sessionsCompleted >= 10)
        unlock(.hundredXP, when: progress.totalXP >= 100)
        unlock(.clearSpeaker, when: overallScore >= 90)

        return newlyUnlocked
    }

    private func save(_ progress: PronunciationPracticeProgress) {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: storageKey())
        }
    }

    private func storageKey() -> String {
        let userId = UserDataModel.shared.getCurrentUser()?.id.uuidString ?? "anonymous"
        return "opentone.pronunciationPracticeProgress.\(userId)"
    }
}
