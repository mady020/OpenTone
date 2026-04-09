import Foundation

// MARK: - ARPAbet Phone Inventory

/// Full ARPAbet phoneme inventory for American English.
/// Stress markers (0/1/2) are handled separately via `StressLevel`.
enum ARPAPhone: String, CaseIterable, Codable, Hashable {
    // Vowels (monophthongs)
    case AA, AE, AH, AO, EH, ER, IH, IY, UH, UW
    // Vowels (diphthongs)
    case AW, AY, EY, OW, OY
    // Stops
    case B, D, G, K, P, T
    // Affricates
    case CH, JH
    // Fricatives
    case DH, F, HH, S, SH, TH, V, Z, ZH
    // Nasals
    case M, N, NG
    // Liquids
    case L, R
    // Glides
    case W, Y

    var isVowel: Bool {
        switch self {
        case .AA, .AE, .AH, .AO, .EH, .ER, .IH, .IY, .UH, .UW,
             .AW, .AY, .EY, .OW, .OY:
            return true
        default:
            return false
        }
    }

    var isConsonant: Bool { !isVowel }

    var isStop: Bool {
        switch self {
        case .B, .D, .G, .K, .P, .T: return true
        default: return false
        }
    }

    var isFricative: Bool {
        switch self {
        case .DH, .F, .HH, .S, .SH, .TH, .V, .Z, .ZH: return true
        default: return false
        }
    }

    var isNasal: Bool {
        switch self {
        case .M, .N, .NG: return true
        default: return false
        }
    }

    /// IPA representation for user-facing display
    var ipaSymbol: String {
        switch self {
        case .AA: return "ɑ"
        case .AE: return "æ"
        case .AH: return "ʌ"
        case .AO: return "ɔ"
        case .EH: return "ɛ"
        case .ER: return "ɝ"
        case .IH: return "ɪ"
        case .IY: return "i"
        case .UH: return "ʊ"
        case .UW: return "u"
        case .AW: return "aʊ"
        case .AY: return "aɪ"
        case .EY: return "eɪ"
        case .OW: return "oʊ"
        case .OY: return "ɔɪ"
        case .B: return "b"
        case .D: return "d"
        case .G: return "ɡ"
        case .K: return "k"
        case .P: return "p"
        case .T: return "t"
        case .CH: return "tʃ"
        case .JH: return "dʒ"
        case .DH: return "ð"
        case .F: return "f"
        case .HH: return "h"
        case .S: return "s"
        case .SH: return "ʃ"
        case .TH: return "θ"
        case .V: return "v"
        case .Z: return "z"
        case .ZH: return "ʒ"
        case .M: return "m"
        case .N: return "n"
        case .NG: return "ŋ"
        case .L: return "l"
        case .R: return "ɹ"
        case .W: return "w"
        case .Y: return "j"
        }
    }

    /// Index in the 39-phone inventory (for posterior matrix indexing)
    var phoneIndex: Int {
        ARPAPhone.allCases.firstIndex(of: self) ?? 0
    }

    static let phoneCount = ARPAPhone.allCases.count

    /// Parse ARPAbet string (possibly with stress digit) into phone + stress
    static func parse(_ token: String) -> (phone: ARPAPhone, stress: StressLevel)? {
        let trimmed = token.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let lastChar = trimmed.last!
        let stress: StressLevel
        let phoneStr: String

        if lastChar.isNumber {
            stress = StressLevel(rawValue: Int(String(lastChar)) ?? 0) ?? .unstressed
            phoneStr = String(trimmed.dropLast())
        } else {
            stress = .none
            phoneStr = trimmed
        }

        guard let phone = ARPAPhone(rawValue: phoneStr) else { return nil }
        return (phone, stress)
    }
}

// MARK: - Stress Level

enum StressLevel: Int, Codable, Hashable {
    case none = -1
    case unstressed = 0
    case primary = 1
    case secondary = 2

    var displayName: String {
        switch self {
        case .none: return ""
        case .unstressed: return "unstressed"
        case .primary: return "primary stress"
        case .secondary: return "secondary stress"
        }
    }
}

// MARK: - Phoneme with Stress

struct StressedPhone: Codable, Hashable {
    let phone: ARPAPhone
    let stress: StressLevel
}

// MARK: - Phoneme Sequence

struct PhonemeSequence: Codable {
    let phones: [StressedPhone]
    let wordBoundaries: [WordPhoneBoundary]

    var count: Int { phones.count }
    var isEmpty: Bool { phones.isEmpty }

    func phonesForWord(at index: Int) -> [StressedPhone] {
        guard index < wordBoundaries.count else { return [] }
        let boundary = wordBoundaries[index]
        let end = min(boundary.startIndex + boundary.length, phones.count)
        return Array(phones[boundary.startIndex..<end])
    }
}

struct WordPhoneBoundary: Codable {
    let word: String
    let startIndex: Int
    let length: Int
}

// MARK: - Phoneme Variant

struct PhonemeVariant: Codable {
    let word: String
    let canonical: [StressedPhone]
    let alternates: [[StressedPhone]]
    let variantDescriptions: [String]
}

// MARK: - Acoustic Feature Matrix

struct AcousticFeatureMatrix {
    let features: [[Float]]  // [frame][feature_dim]
    let frameCount: Int
    let featureDim: Int
    let sampleRate: Int
    let hopLength: Int

    var frameDurationSeconds: Float {
        Float(hopLength) / Float(sampleRate)
    }

    func timeForFrame(_ frame: Int) -> Float {
        Float(frame) * frameDurationSeconds
    }

    var durationSeconds: Float {
        Float(frameCount) * frameDurationSeconds
    }
}

// MARK: - Phone Posterior Matrix

struct PhonePosteriorMatrix {
    let posteriors: [[Float]]  // [frame][phone_index]
    let frameCount: Int
    let phoneCount: Int

    func posteriorForPhone(_ phone: ARPAPhone, atFrame frame: Int) -> Float {
        guard frame < frameCount else { return 0 }
        return posteriors[frame][phone.phoneIndex]
    }

    func bestPhone(atFrame frame: Int) -> (phone: ARPAPhone, probability: Float) {
        guard frame < frameCount else { return (.AH, 0) }
        let row = posteriors[frame]
        var bestIdx = 0
        var bestVal: Float = -1
        for (i, val) in row.enumerated() {
            if val > bestVal {
                bestVal = val
                bestIdx = i
            }
        }
        return (ARPAPhone.allCases[bestIdx], bestVal)
    }
}

// MARK: - Alignment Result

struct AlignmentResult: Codable {
    let alignedPhones: [AlignedPhone]
    let overallScore: Float
    let alignmentPath: [AlignmentStep]
}

struct AlignedPhone: Codable {
    let expectedPhone: StressedPhone
    let startFrame: Int
    let endFrame: Int
    let confidence: Float
    let durationFrames: Int
    let category: AlignmentCategory
    let wordIndex: Int
}

enum AlignmentCategory: String, Codable {
    case matched
    case substituted
    case inserted
    case missing
}

struct AlignmentStep: Codable {
    let expectedIndex: Int
    let frameIndex: Int
    let cost: Float
    let operation: AlignmentCategory
}

// MARK: - Phone Score

struct PhoneScore: Codable {
    let phone: StressedPhone
    let score: Float           // 0–100
    let category: PhoneScoreCategory
    let severity: ScoreSeverity
    let confidence: ScoreConfidence
    let wordIndex: Int
    let word: String
    let substitutedWith: ARPAPhone?
    let diagnosticNote: String?
}

enum PhoneScoreCategory: String, Codable {
    case correct
    case weak
    case substituted
    case missing
    case inserted
    case acceptableVariation
}

enum ScoreSeverity: String, Codable, Comparable {
    case none
    case minor
    case moderate
    case critical

    private var sortOrder: Int {
        switch self {
        case .none: return 0
        case .minor: return 1
        case .moderate: return 2
        case .critical: return 3
        }
    }

    static func < (lhs: ScoreSeverity, rhs: ScoreSeverity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

enum ScoreConfidence: String, Codable {
    case high
    case medium
    case low
}

// MARK: - Prosody Result

struct ProsodyResult: Codable {
    let overallScore: Float       // 0–100
    let confidence: ScoreConfidence
    let wordStress: [WordStressResult]
    let issues: [ProsodyIssue]
}

struct WordStressResult: Codable {
    let word: String
    let wordIndex: Int
    let expectedStressPattern: [StressLevel]
    let observedStressEstimate: [StressLevel]
    let stressScore: Float        // 0–100
    let confidence: ScoreConfidence
}

enum ProsodyIssueType: String, Codable {
    case weakStress
    case compressedStress
    case flatDelivery
    case risingIntonation
    case unnaturalPacing
}

struct ProsodyIssue: Codable {
    let type: ProsodyIssueType
    let wordIndex: Int?
    let description: String
    let severity: ScoreSeverity
    let confidence: ScoreConfidence
}

// MARK: - Full Assessment Result

struct PronunciationAssessmentResult: Codable {
    let overallScore: Float       // 0–100
    let phoneScores: [PhoneScore]
    let wordScores: [WordPronunciationScore]
    let prosody: ProsodyResult
    let expectedText: String
    let transcribedText: String
    let diagnostics: PronunciationDiagnostics
}

struct WordPronunciationScore: Codable {
    let word: String
    let wordIndex: Int
    let score: Float              // 0–100
    let phoneScores: [PhoneScore]
    let hasIssue: Bool
    let primaryIssue: String?
}

struct PronunciationDiagnostics: Codable {
    let expectedPhonemeCount: Int
    let alignedPhonemeCount: Int
    let missingPhonemeCount: Int
    let substitutionCount: Int
    let insertionCount: Int
    let acceptableVariationCount: Int
    let acousticModelUsed: String
    let processingTimeMs: Double
}
