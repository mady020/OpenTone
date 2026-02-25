import UIKit

/// Section 5 — Next Goal + Practice Again CTA
class FeedbackTranscriptCell: UICollectionViewCell {

    static let reuseID = "FeedbackTranscriptCell"

    // MARK: - Views

    private let goalLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = AppColors.textPrimary
        l.numberOfLines = 4
        return l
    }()

    private let focusHeader: UILabel = {
        let l = UILabel()
        l.text = "🎯  NEXT GOAL"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .tertiaryLabel
        return l
    }()

    private let practiceButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Practice Again"
        cfg.image = UIImage(systemName: "arrow.counterclockwise")
        cfg.imagePadding = 8
        cfg.imagePlacement = .leading
        cfg.cornerStyle = .capsule
        cfg.baseBackgroundColor = AppColors.primary
        cfg.baseForegroundColor = .white
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            return a
        }
        let b = UIButton(configuration: cfg)
        return b
    }()

    private let transcriptHeader: UILabel = {
        let l = UILabel()
        l.text = "TRANSCRIPT"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .tertiaryLabel
        return l
    }()

    private let transcriptBody: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }()

    private let card: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.cornerCurve = .continuous
        return v
    }()

    var onPracticeAgain: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        practiceButton.addTarget(self, action: #selector(practiceAgainTapped), for: .touchUpInside)

        let goalCard = UIView()
        goalCard.backgroundColor = AppColors.primary.withAlphaComponent(0.08)
        goalCard.layer.cornerRadius = 14
        goalCard.layer.cornerCurve = .continuous

        let goalInner = UIStackView(arrangedSubviews: [focusHeader, goalLabel])
        goalInner.axis = .vertical
        goalInner.spacing = 8
        goalInner.translatesAutoresizingMaskIntoConstraints = false
        goalCard.addSubview(goalInner)
        NSLayoutConstraint.activate([
            goalInner.topAnchor.constraint(equalTo: goalCard.topAnchor, constant: 14),
            goalInner.leadingAnchor.constraint(equalTo: goalCard.leadingAnchor, constant: 16),
            goalInner.trailingAnchor.constraint(equalTo: goalCard.trailingAnchor, constant: -16),
            goalInner.bottomAnchor.constraint(equalTo: goalCard.bottomAnchor, constant: -14),
        ])

        let buttonRow = UIView()
        practiceButton.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.addSubview(practiceButton)
        NSLayoutConstraint.activate([
            practiceButton.topAnchor.constraint(equalTo: buttonRow.topAnchor),
            practiceButton.bottomAnchor.constraint(equalTo: buttonRow.bottomAnchor),
            practiceButton.leadingAnchor.constraint(equalTo: buttonRow.leadingAnchor),
            practiceButton.trailingAnchor.constraint(equalTo: buttonRow.trailingAnchor),
            practiceButton.heightAnchor.constraint(equalToConstant: 52),
        ])

        let divider = UIView()
        divider.backgroundColor = AppColors.cardBorder
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let outerStack = UIStackView(arrangedSubviews: [goalCard, buttonRow, divider, transcriptHeader, transcriptBody])
        outerStack.axis = .vertical
        outerStack.spacing = 16
        outerStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(card)
        card.addSubview(outerStack)
        card.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

            outerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            outerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            outerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            outerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
        ])

        applyStyle()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: FeedbackTranscriptCell, _) in self.applyStyle() }
    }

    private func applyStyle() {
        card.backgroundColor = AppColors.cardBackground
        card.layer.borderWidth = 1
        card.layer.borderColor = AppColors.cardBorder.cgColor
    }

    @objc private func practiceAgainTapped() {
        onPracticeAgain?()
    }

    func configure(transcript: String) {
        // Legacy shim
        goalLabel.text = "Keep practising to improve your fluency!"
        transcriptBody.attributedText = NSAttributedString(string: transcript.isEmpty ? "(No transcript)" : transcript)
    }

    /// Main configure — highlights filler words and repeated words in the transcript.
    func configureCoaching(nextGoal: String, transcript: String, fillerExamples: [FillerExample] = [], repetitions: Int = 0) {
        goalLabel.text = nextGoal

        let displayText = transcript.isEmpty ? "(No transcript available)" : transcript
        transcriptBody.attributedText = buildHighlightedTranscript(
            text: displayText,
            fillerExamples: fillerExamples
        )
    }

    // MARK: - Transcript Highlighting

    private func buildHighlightedTranscript(text: String, fillerExamples: [FillerExample]) -> NSAttributedString {
        let baseFont    = UIFont.systemFont(ofSize: 15)
        let baseColor   = UIColor.secondaryLabel
        let result      = NSMutableAttributedString(
            string: text,
            attributes: [.font: baseFont, .foregroundColor: baseColor]
        )

        // Collect filler word strings (lowercased, deduplicated)
        var fillerWords = Set(fillerExamples.map { $0.word.lowercased() })
        // Always include common fillers for local highlighting even if backend didn't catch them
        let commonFillers: Set<String> = ["uh", "um", "uhh", "umm", "like", "you know", "i mean"]
        fillerWords.formUnion(commonFillers)

        // Highlight filler words: amber background, bold
        let fillerAttrs: [NSAttributedString.Key: Any] = [
            .backgroundColor: UIColor.systemOrange.withAlphaComponent(0.18),
            .foregroundColor: UIColor(red: 0.78, green: 0.45, blue: 0.0, alpha: 1),
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
        ]

        // Highlight repeated words: light red underline
        let repetitionAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemRed.withAlphaComponent(0.75),
            .font: UIFont.systemFont(ofSize: 15, weight: .medium),
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: UIColor.systemRed.withAlphaComponent(0.5),
        ]

        let lowercasedText = text.lowercased() as NSString
        let fullRange = NSRange(location: 0, length: lowercasedText.length)

        // Apply filler highlights — word boundary search
        for filler in fillerWords {
            var searchRange = fullRange
            while searchRange.length > 0 {
                let found = lowercasedText.range(of: filler, options: .caseInsensitive, range: searchRange)
                guard found.location != NSNotFound else { break }

                // Verify word boundary: char before and after must be whitespace/punctuation/start/end
                let before = found.location == 0
                    ? true
                    : isWordBoundary(lowercasedText as String, at: found.location - 1)
                let afterIdx = found.location + found.length
                let after = afterIdx >= lowercasedText.length
                    ? true
                    : isWordBoundary(lowercasedText as String, at: afterIdx)

                if before && after {
                    result.addAttributes(fillerAttrs, range: found)
                }

                let nextStart = found.location + found.length
                searchRange = NSRange(location: nextStart, length: fullRange.length - nextStart)
            }
        }

        // Detect and highlight adjacent word repetitions
        let words = text.components(separatedBy: .whitespaces)
        var cursor = 0
        var prev: String? = nil
        for word in words {
            let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            if let p = prev, p == clean, clean.count > 2 {
                // Find this word in result string starting from cursor
                if let range = (text as NSString).range(of: word, options: .caseInsensitive,
                    range: NSRange(location: cursor, length: (text as NSString).length - cursor)).toOptional() {
                    result.addAttributes(repetitionAttrs, range: range)
                }
            }
            cursor += word.count + 1
            prev = clean.isEmpty ? prev : clean
        }

        return result
    }

    private func isWordBoundary(_ text: String, at index: Int) -> Bool {
        let idx = text.index(text.startIndex, offsetBy: index)
        let ch = text[idx]
        return ch.isWhitespace || ch.isPunctuation || ch == "," || ch == "." || ch == "!" || ch == "?"
    }
}

private extension NSRange {
    func toOptional() -> NSRange? {
        location == NSNotFound ? nil : self
    }
}

