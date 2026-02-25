import Foundation

// MARK: - Request

struct AnalyzeRequest: Encodable {
    let audioURL: String?
    let transcript: String?
    let durationS: Double?
    let userId: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case audioURL   = "audio_url"
        case transcript = "transcript"
        case durationS  = "duration_s"
        case userId     = "user_id"
        case sessionId  = "session_id"
    }
}

// MARK: - Metrics

struct SpeechMetrics: Codable {
    let wpm: Double
    let totalWords: Int
    let durationS: Double
    let fillerRatePerMin: Double
    let fillers: Int
    let pauses: Int
    let avgPauseS: Double
    let veryLongPauses: Int
    let repetitions: Int
    let fillerExamples: [FillerExample]
    let pauseExamples: [PauseExample]

    enum CodingKeys: String, CodingKey {
        case wpm, fillers, pauses, repetitions
        case totalWords        = "total_words"
        case durationS         = "duration_s"
        case fillerRatePerMin  = "filler_rate_per_min"
        case avgPauseS         = "avg_pause_s"
        case veryLongPauses    = "very_long_pauses"
        case fillerExamples    = "filler_examples"
        case pauseExamples     = "pause_examples"
    }
}

struct FillerExample: Codable {
    let word: String
    let timestamp: Double
}

struct PauseExample: Codable {
    let start: Double
    let end: Double
    let duration: Double
}

// MARK: - Coaching

struct SpeechCoaching: Codable {
    let scores: CoachingScores
    let primaryIssue: String
    let primaryIssueTitle: String
    let secondaryIssues: [String]
    let strengths: [String]
    let suggestions: [String]
    let evidence: [EvidenceItem]

    enum CodingKeys: String, CodingKey {
        case scores, strengths, suggestions, evidence
        case primaryIssue      = "primary_issue"
        case primaryIssueTitle = "primary_issue_title"
        case secondaryIssues   = "secondary_issues"
    }
}

struct CoachingScores: Codable {
    let fluency: Double
    let confidence: Double
    let clarity: Double

    /// 0–100 overall composite
    var overall: Double { (fluency + confidence + clarity) / 3.0 }
}

struct EvidenceItem: Codable {
    let type: String        // "filler" | "pause" | "repetition"
    let timestamp: Double
    let text: String        // e.g. "00:14 — \"um\""
}

// MARK: - Progress

struct SpeechProgress: Codable {
    let deltas: Deltas
    let overallDirection: String  // "improving" | "declining" | "mixed"
    let weeklySummary: String

    enum CodingKeys: String, CodingKey {
        case deltas
        case overallDirection = "overall_direction"
        case weeklySummary    = "weekly_summary"
    }

    var directionArrow: String {
        switch overallDirection {
        case "improving": return "↑"
        case "declining": return "↓"
        default:          return "→"
        }
    }
}

struct Deltas: Codable {
    let wpm: Double
    let fillers: Double
    let pauses: Double

    var fillersDescription: String? {
        guard abs(fillers) >= 0.1 else { return nil }
        let dir = fillers > 0 ? "fewer" : "more"
        return String(format: "%.1f \(dir) fillers/min", abs(fillers))
    }

    var wpmDescription: String? {
        guard abs(wpm) >= 1 else { return nil }
        let dir = wpm > 0 ? "faster" : "slower"
        return String(format: "%+.0f WPM (\(dir))", wpm)
    }
}

// MARK: - Full Response

struct SpeechAnalysisResponse: Codable {
    let transcript: String
    let metrics: SpeechMetrics
    let coaching: SpeechCoaching
    let progress: SpeechProgress
}

// MARK: - User Profile

struct UserSpeechProfile: Codable {
    let userId: String
    let avgWpm: Double
    let avgFillerRate: Double
    let avgPause: Double
    let avgRepetition: Double
    let fluencyScore: Double
    let confidenceScore: Double
    let clarityScore: Double
    let sessionsCount: Int

    enum CodingKeys: String, CodingKey {
        case userId           = "user_id"
        case avgWpm           = "avg_wpm"
        case avgFillerRate    = "avg_filler_rate"
        case avgPause         = "avg_pause"
        case avgRepetition    = "avg_repetition"
        case fluencyScore     = "fluency_score"
        case confidenceScore  = "confidence_score"
        case clarityScore     = "clarity_score"
        case sessionsCount    = "sessions_count"
    }

    var overallScore: Double { (fluencyScore + confidenceScore + clarityScore) / 3.0 }
}
