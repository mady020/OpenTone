import UIKit

final class SessionFeedbackDetailViewController: UIViewController {

    private let feedback: SessionFeedback
    private let sessionTitle: String

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(feedback: SessionFeedback, sessionTitle: String) {
        self.feedback = feedback
        self.sessionTitle = sessionTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Feedback Details"
        view.backgroundColor = AppColors.screenBackground
        configureLayout()
        populateContent()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32)
        ])
    }

    private func populateContent() {
        let summaryDate = DateFormatter.localizedString(from: feedback.createdAt, dateStyle: .medium, timeStyle: .short)

        contentStack.addArrangedSubview(makeCard(
            title: sessionTitle,
            body: "Completed on \(summaryDate)"
        ))

        let scoreLines = [
            "Overall: \(formattedScore(feedback.overallScore ?? fallbackOverallScore()))",
            "Fluency: \(formattedScore(feedback.fluencyScore))",
            "Confidence: \(formattedScore(feedback.confidenceScore ?? fallbackConfidenceScore()))",
            "Clarity: \(formattedScore(feedback.clarityScore ?? feedback.onTopicScore))"
        ].joined(separator: "\n")

        contentStack.addArrangedSubview(makeCard(title: "Performance", body: scoreLines))

        let speakingSignals = [
            "Filler words: \(feedback.fillerWordCount)",
            "Pauses: \(feedback.pauses)"
        ].joined(separator: "\n")

        contentStack.addArrangedSubview(makeCard(title: "Speaking Signals", body: speakingSignals))

        if !feedback.mispronouncedWords.isEmpty {
            let words = feedback.mispronouncedWords.joined(separator: ", ")
            contentStack.addArrangedSubview(makeCard(
                title: "Difficult Words",
                body: words
            ))
        }

        contentStack.addArrangedSubview(makeCard(title: "How To Improve", body: feedback.summary))
    }

    private func makeCard(title: String, body: String) -> UIView {
        let card = UIView()
        card.backgroundColor = AppColors.cardBackground
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = AppColors.cardBorder.cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = AppColors.textPrimary

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: 15, weight: .regular)
        bodyLabel.numberOfLines = 0
        bodyLabel.textColor = AppColors.textPrimary

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(bodyLabel)

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }

    private func formattedScore(_ value: Double) -> String {
        String(format: "%.0f/100", max(0, min(100, value)))
    }

    private func fallbackConfidenceScore() -> Double {
        let estimated = 85.0 - Double(feedback.fillerWordCount) * 2.0 - Double(feedback.pauses)
        return max(30, min(95, estimated))
    }

    private func fallbackOverallScore() -> Double {
        let confidence = feedback.confidenceScore ?? fallbackConfidenceScore()
        let clarity = feedback.clarityScore ?? feedback.onTopicScore
        return (feedback.fluencyScore + clarity + confidence) / 3.0
    }
}
