import Foundation

// MARK: - Word Timestamp

struct WordTimestamp: Codable {
    let word: String
    let timestamp: Double
}

// MARK: - Pause Example

struct PauseExample: Codable {
    let start: Double
    let end: Double
    let duration: Double
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
    let fillerExamples: [WordTimestamp]
    let pauseExamples: [PauseExample]

    enum CodingKeys: String, CodingKey {
        case wpm, fillers, pauses, repetitions
        case totalWords         = "total_words"
        case durationS          = "duration_s"
        case fillerRatePerMin   = "filler_rate_per_min"
        case avgPauseS          = "avg_pause_s"
        case veryLongPauses     = "very_long_pauses"
        case fillerExamples     = "filler_examples"
        case pauseExamples      = "pause_examples"
    }
}

// MARK: - Coaching Scores

struct CoachingScores: Codable {
    let fluency: Double
    let confidence: Double
    let clarity: Double
}

// MARK: - Evidence

struct EvidenceItem: Codable {
    let type: String          // "filler" | "pause" | "repetition"
    let timestamp: Double
    let text: String
}

// MARK: - Coaching Result

struct SpeechCoaching: Codable {
    let scores: CoachingScores
    let primaryIssue: String
    let secondaryIssues: [String]
    let strengths: [String]
    let suggestions: [String]
    let evidence: [EvidenceItem]

    enum CodingKeys: String, CodingKey {
        case scores, strengths, suggestions, evidence
        case primaryIssue    = "primary_issue"
        case secondaryIssues = "secondary_issues"
    }

    /// Human-readable title for the primary issue
    var primaryIssueTitle: String {
        switch primaryIssue {
        case "too_many_fillers":    return "Too many filler words"
        case "speaking_too_slow":   return "Speaking pace — too slow"
        case "speaking_too_fast":   return "Speaking pace — too fast"
        case "long_pauses":         return "Pausing mid-thought"
        case "word_repetitions":    return "Repeated words"
        default:                    return "Great delivery!"
        }
    }
}

// MARK: - Progress

struct ProgressDeltas: Codable {
    let wpm: Double
    let fillers: Double
    let pauses: Double
    let fluencyScore: Double

    enum CodingKeys: String, CodingKey {
        case wpm, fillers, pauses
        case fluencyScore = "fluency_score"
    }

    var wpmDescription: String {
        if abs(wpm) < 1 { return nil ?? "" }
        let arrow = wpm > 0 ? "↑" : "↓"
        return "\(arrow) \(abs(Int(wpm))) WPM"
    }

    var fillersDescription: String? {
        guard abs(fillers) >= 0.5 else { return nil }
        if fillers > 0 {
            return "↓ \(String(format: "%.1f", fillers)) fewer fillers/min"
        } else {
            return "↑ \(String(format: "%.1f", abs(fillers))) more fillers/min"
        }
    }
}

struct SpeechProgress: Codable {
    let deltas: ProgressDeltas
    let overallDirection: String    // "improving" | "declining" | "stable"
    let weeklySummary: String

    enum CodingKeys: String, CodingKey {
        case deltas
        case overallDirection = "overall_direction"
        case weeklySummary    = "weekly_summary"
    }

    var directionEmoji: String {
        switch overallDirection {
        case "improving": return "📈"
        case "declining": return "📉"
        default:          return "➡️"
        }
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
    let lastSessionAt: String?

    enum CodingKeys: String, CodingKey {
        case userId          = "user_id"
        case avgWpm          = "avg_wpm"
        case avgFillerRate   = "avg_filler_rate"
        case avgPause        = "avg_pause"
        case avgRepetition   = "avg_repetition"
        case fluencyScore    = "fluency_score"
        case confidenceScore = "confidence_score"
        case clarityScore    = "clarity_score"
        case sessionsCount   = "sessions_count"
        case lastSessionAt   = "last_session_at"
    }

    /// Average of three coaching scores (0–100)
    var overallScore: Double {
        (fluencyScore + confidenceScore + clarityScore) / 3.0
    }
}
