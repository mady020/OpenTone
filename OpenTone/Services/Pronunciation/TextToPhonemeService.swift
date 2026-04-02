import Foundation

/// Converts English text to phoneme sequences using a bundled CMU dictionary
/// with rule-based fallback for out-of-vocabulary words.
final class TextToPhonemeService {

    static let shared = TextToPhonemeService()

    private var dictionary: [String: [[String]]] = [:]
    private var isLoaded = false

    private init() {
        loadDictionary()
    }

    // MARK: - Public API

    /// Convert a full sentence/phrase to a phoneme sequence with word boundaries.
    func convert(text: String) -> (sequence: PhonemeSequence, variants: [PhonemeVariant]) {
        let words = tokenize(text)
        var allPhones: [StressedPhone] = []
        var boundaries: [WordPhoneBoundary] = []
        var variants: [PhonemeVariant] = []

        for (wordIndex, word) in words.enumerated() {
            let lookupKey = word.lowercased()
            let pronunciations = lookupPronunciations(for: lookupKey)

            guard let primary = pronunciations.first else { continue }

            let startIdx = allPhones.count
            let stressedPhones = primary.compactMap { token -> StressedPhone? in
                guard let parsed = ARPAPhone.parse(token) else { return nil }
                return StressedPhone(phone: parsed.phone, stress: parsed.stress)
            }

            allPhones.append(contentsOf: stressedPhones)
            boundaries.append(WordPhoneBoundary(
                word: word,
                startIndex: startIdx,
                length: stressedPhones.count
            ))

            // Collect alternates
            let alternatePhones = pronunciations.dropFirst().map { pron in
                pron.compactMap { token -> StressedPhone? in
                    guard let parsed = ARPAPhone.parse(token) else { return nil }
                    return StressedPhone(phone: parsed.phone, stress: parsed.stress)
                }
            }

            // Generate common variation alternates
            let variationAlternates = generateVariationAlternates(
                canonical: stressedPhones,
                word: word
            )

            let allAlternates = Array(alternatePhones) + variationAlternates.map { $0.0 }
            let descriptions = Array(repeating: "dictionary variant", count: alternatePhones.count)
                + variationAlternates.map { $0.1 }

            if !allAlternates.isEmpty {
                variants.append(PhonemeVariant(
                    word: word,
                    canonical: stressedPhones,
                    alternates: allAlternates,
                    variantDescriptions: descriptions
                ))
            }
        }

        let sequence = PhonemeSequence(phones: allPhones, wordBoundaries: boundaries)
        return (sequence, variants)
    }

    /// Look up a single word's phoneme representations.
    func lookupPronunciations(for word: String) -> [[String]] {
        let key = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        if let entries = dictionary[key], !entries.isEmpty {
            return entries
        }
        return [ruleBasedFallback(word: key)]
    }

    // MARK: - Dictionary Loading

    private func loadDictionary() {
        guard let url = Bundle.main.url(forResource: "cmu_dict_compact", withExtension: "json") else {
            print("[TextToPhoneme] CMU dictionary not found in bundle, using rule-based fallback only")
            isLoaded = false
            return
        }

        do {
            let data = try Data(contentsOf: url)
            dictionary = try JSONDecoder().decode([String: [[String]]].self, from: data)
            isLoaded = true
            print("[TextToPhoneme] Loaded CMU dictionary with \(dictionary.count) entries")
        } catch {
            print("[TextToPhoneme] Failed to load CMU dictionary: \(error)")
            isLoaded = false
        }
    }

    // MARK: - Tokenization

    private func tokenize(_ text: String) -> [String] {
        text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    // MARK: - Rule-Based Fallback

    /// Simple letter-to-phoneme rules for words not in the dictionary.
    /// Not linguistically perfect, but provides a reasonable baseline.
    private func ruleBasedFallback(word: String) -> [String] {
        let chars = Array(word.lowercased())
        var phones: [String] = []
        var i = 0

        while i < chars.count {
            let remaining = String(chars[i...])

            if let (phone, consumed) = matchRule(remaining) {
                phones.append(phone)
                i += consumed
            } else {
                // Skip unknown characters
                i += 1
            }
        }

        return phones
    }

    private func matchRule(_ text: String) -> (String, Int)? {
        let rules: [(String, String, Int)] = [
            // Digraphs first
            ("th", "TH", 2),
            ("sh", "SH", 2),
            ("ch", "CH", 2),
            ("ng", "NG", 2),
            ("ph", "F", 2),
            ("wh", "W", 2),
            ("ck", "K", 2),
            ("ee", "IY1", 2),
            ("ea", "IY1", 2),
            ("oo", "UW1", 2),
            ("ou", "AW1", 2),
            ("ow", "AW1", 2),
            ("ai", "EY1", 2),
            ("ay", "EY1", 2),
            ("oi", "OY1", 2),
            ("oy", "OY1", 2),
            // Single consonants
            ("b", "B", 1),
            ("c", "K", 1),
            ("d", "D", 1),
            ("f", "F", 1),
            ("g", "G", 1),
            ("h", "HH", 1),
            ("j", "JH", 1),
            ("k", "K", 1),
            ("l", "L", 1),
            ("m", "M", 1),
            ("n", "N", 1),
            ("p", "P", 1),
            ("q", "K", 1),
            ("r", "R", 1),
            ("s", "S", 1),
            ("t", "T", 1),
            ("v", "V", 1),
            ("w", "W", 1),
            ("x", "K", 1),  // Simplified
            ("y", "Y", 1),
            ("z", "Z", 1),
            // Single vowels (simplified)
            ("a", "AE1", 1),
            ("e", "EH1", 1),
            ("i", "IH1", 1),
            ("o", "AA1", 1),
            ("u", "AH1", 1),
        ]

        let lower = text.lowercased()
        for (pattern, phone, consumed) in rules {
            if lower.hasPrefix(pattern) {
                return (phone, consumed)
            }
        }
        return nil
    }

    // MARK: - Variation Generation

    /// Generate common acceptable pronunciation variants for a canonical form.
    private func generateVariationAlternates(
        canonical: [StressedPhone],
        word: String
    ) -> [([StressedPhone], String)] {
        var alternates: [([StressedPhone], String)] = []

        // T-flapping: intervocalic /T/ → /D/ (e.g., "butter", "water")
        for (i, sp) in canonical.enumerated() {
            if sp.phone == .T,
               i > 0, i < canonical.count - 1,
               canonical[i - 1].phone.isVowel,
               canonical[i + 1].phone.isVowel {
                var variant = canonical
                variant[i] = StressedPhone(phone: .D, stress: sp.stress)
                alternates.append((variant, "t-flapping (American English)"))
            }
        }

        // Schwa reduction: unstressed vowels → AH
        var schwaVariant = canonical
        var hasSchwa = false
        for (i, sp) in canonical.enumerated() {
            if sp.phone.isVowel && sp.stress == .unstressed && sp.phone != .AH {
                schwaVariant[i] = StressedPhone(phone: .AH, stress: .unstressed)
                hasSchwa = true
            }
        }
        if hasSchwa {
            alternates.append((schwaVariant, "schwa reduction in unstressed syllables"))
        }

        // Rhotic vowel variants: ER can be non-rhotic
        for (i, sp) in canonical.enumerated() {
            if sp.phone == .ER {
                var variant = canonical
                variant[i] = StressedPhone(phone: .AH, stress: sp.stress)
                alternates.append((variant, "non-rhotic variant"))
            }
        }

        // Glottal stop for final T
        if let last = canonical.last, last.phone == .T {
            let variant = Array(canonical.dropLast())
            alternates.append((variant, "glottal stop for final /t/"))
        }

        return alternates
    }
}
