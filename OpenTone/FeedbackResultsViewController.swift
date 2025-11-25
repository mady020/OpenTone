import UIKit

final class FeedbackResultsViewController: UIViewController {

    // MARK: - MAIN SCROLL VIEW
    let scrollView = UIScrollView()
    let contentView = UIView()

    // MARK: - UI Elements
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    // MARK: - Mistake Section
    let mistakesTitle = UILabel()

    let mistakeCard1 = UIView()
    let mistakeWrong1 = UILabel()
    let mistakeCorrect1 = UILabel()
    let mistakeExplanation1 = UILabel()

    let mistakeCard2 = UIView()
    let mistakeWrong2 = UILabel()
    let mistakeCorrect2 = UILabel()
    let mistakeExplanation2 = UILabel()

    // MARK: - Transcript Section
    let transcriptCard = UIView()
    let transcriptTitle = UILabel()
    let transcriptPreview = UILabel()
    let transcriptToggle = UIButton(type: .system)
    let transcriptFull = UILabel()
    var transcriptExpanded = false

    // MARK: - Metrics & Buttons
    let metricsTitle = UILabel()

    let speechMetricCard = UIView()
    let fillerMetricCard = UIView()
    let wpmMetricCard = UIView()
    let pausesMetricCard = UIView()

    let speechTitle = UILabel()
    let fillerTitle = UILabel()
    let wpmTitle = UILabel()
    let pausesTitle = UILabel()

    let speechProgress = UIProgressView(progressViewStyle: .default)
    let fillerProgress = UIProgressView(progressViewStyle: .default)
    let wpmProgress = UIProgressView(progressViewStyle: .default)
    let pausesProgress = UIProgressView(progressViewStyle: .default)

    let callDurationTitle = UILabel()
    let callDurationValue = UILabel()

    // Medal
    let medalIcon = UIImageView(image: UIImage(systemName: "medal.fill"))
    let medalLabel = UILabel()

    // Buttons
    let endButton = UIButton(type: .system)
    let newButton = UIButton(type: .system)


    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemGray6

        setupScrollView()
        setupUI()
        setupMistakeCards()
        setupTranscriptSection()
        layoutUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateMetrics()
        animateMedal()
    }

    // MARK: - Animations
    func animateMetrics() {
        UIView.animate(withDuration: 1.2) {
            self.speechProgress.setProgress(0.8, animated: true)
            self.fillerProgress.setProgress(0.25, animated: true)
            self.wpmProgress.setProgress(0.65, animated: true)
            self.pausesProgress.setProgress(0.3, animated: true)
        }
    }

    func animateMedal() {
        medalIcon.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        medalLabel.alpha = 0

        UIView.animate(
            withDuration: 0.6,
            delay: 0.3,
            usingSpringWithDamping: 0.4,
            initialSpringVelocity: 1,
            options: [],
            animations: {
                self.medalIcon.transform = .identity
                self.medalLabel.alpha = 1
            }
        )
    }

    // MARK: - ScrollView Setup
    func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // MARK: - Top UI Setup
    func setupUI() {

        titleLabel.text = "Feedback & Results"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        subtitleLabel.text = "Great job! Here’s your analysis:"
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.textColor = .systemTeal

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        [titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // Medal
        medalIcon.tintColor = .systemYellow
        medalIcon.contentMode = .scaleAspectFit
        medalLabel.text = "+12"
        medalLabel.font = .systemFont(ofSize: 28, weight: .bold)
        medalLabel.textColor = .systemGreen

        contentView.addSubview(medalIcon)
        contentView.addSubview(medalLabel)

        medalIcon.translatesAutoresizingMaskIntoConstraints = false
        medalLabel.translatesAutoresizingMaskIntoConstraints = false

        // Metrics header
        metricsTitle.text = "Key Metrics"
        metricsTitle.font = .systemFont(ofSize: 22, weight: .bold)
        metricsTitle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(metricsTitle)

        // Metric cards
        [speechMetricCard, fillerMetricCard, wpmMetricCard, pausesMetricCard].forEach {
            styleMetricCard($0)
        }

        setupMetrics()
        setupBottomButtons()
    }

    // MARK: - Mistake Cards Setup
    func setupMistakeCards() {

        mistakesTitle.text = "Your Mistakes"
        mistakesTitle.font = .systemFont(ofSize: 22, weight: .bold)
        mistakesTitle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mistakesTitle)

        setupMistakeCardView(card: mistakeCard1,
                             wrong: mistakeWrong1,
                             correct: mistakeCorrect1,
                             explanation: mistakeExplanation1,
                             wrongText: "❌ I am working in technology since 5 year.",
                             correctText: "✔️ I have been working in technology for 5 years.",
                             explanationText: "Use present perfect continuous + plural form.")

        setupMistakeCardView(card: mistakeCard2,
                             wrong: mistakeWrong2,
                             correct: mistakeCorrect2,
                             explanation: mistakeExplanation2,
                             wrongText: "❌ I very like coding.",
                             correctText: "✔️ I really like coding.",
                             explanationText: "Use 'really' instead of 'very' before verbs.")
    }

    func setupMistakeCardView(card: UIView,
                              wrong: UILabel,
                              correct: UILabel,
                              explanation: UILabel,
                              wrongText: String,
                              correctText: String,
                              explanationText: String) {

        card.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)
        card.layer.cornerRadius = 18

        wrong.text = wrongText
        wrong.font = .systemFont(ofSize: 15, weight: .regular)
        wrong.textColor = .systemRed
        wrong.numberOfLines = 0

        correct.text = correctText
        correct.font = .systemFont(ofSize: 15, weight: .semibold)
        correct.textColor = .systemGreen
        correct.numberOfLines = 0

        explanation.text = explanationText
        explanation.font = .systemFont(ofSize: 13)
        explanation.textColor = .secondaryLabel
        explanation.numberOfLines = 0

        [wrong, correct, explanation].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            wrong.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            wrong.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            wrong.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            correct.topAnchor.constraint(equalTo: wrong.bottomAnchor, constant: 8),
            correct.leadingAnchor.constraint(equalTo: wrong.leadingAnchor),
            correct.trailingAnchor.constraint(equalTo: wrong.trailingAnchor),

            explanation.topAnchor.constraint(equalTo: correct.bottomAnchor, constant: 6),
            explanation.leadingAnchor.constraint(equalTo: wrong.leadingAnchor),
            explanation.trailingAnchor.constraint(equalTo: wrong.trailingAnchor),
            explanation.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Transcript Section
    func setupTranscriptSection() {

        transcriptCard.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12)
        transcriptCard.layer.cornerRadius = 18
        transcriptCard.translatesAutoresizingMaskIntoConstraints = false

        transcriptTitle.text = "Conversation Transcript"
        transcriptTitle.font = .systemFont(ofSize: 18, weight: .semibold)

        transcriptPreview.text = """
You: Hey! How are you?
You: I learned new things…
"""
        transcriptPreview.font = .systemFont(ofSize: 15)
        transcriptPreview.numberOfLines = 0
        transcriptPreview.textColor = .label

        transcriptToggle.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        transcriptToggle.tintColor = .systemPurple
        transcriptToggle.addTarget(self, action: #selector(toggleTranscript), for: .touchUpInside)

        transcriptFull.text = """
Partner: That's great!
You: I am learning stock marketing now a days.
Partner: Oh wow nice!
"""
        transcriptFull.font = .systemFont(ofSize: 15)
        transcriptFull.numberOfLines = 0
        transcriptFull.alpha = 0 // collapsed initially

        [transcriptCard, transcriptTitle, transcriptPreview, transcriptToggle, transcriptFull].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    @objc func toggleTranscript() {
        transcriptExpanded.toggle()

        UIView.animate(withDuration: 0.3) {
            self.transcriptFull.alpha = self.transcriptExpanded ? 1 : 0
            self.transcriptToggle.transform =
                CGAffineTransform(rotationAngle: self.transcriptExpanded ? .pi : 0)

            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Metrics Section Setup
    func setupMetrics() {
        [speechMetricCard, fillerMetricCard, wpmMetricCard, pausesMetricCard].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        // Titles
        speechTitle.text = "Speech Length"
        fillerTitle.text = "Filler Words"
        wpmTitle.text = "Words Per Minute"
        pausesTitle.text = "Pauses"

        callDurationTitle.text = "Call Duration:"
        callDurationTitle.font = .systemFont(ofSize: 18, weight: .semibold)

        callDurationValue.text = "3.15"
        callDurationValue.font = .systemFont(ofSize: 18, weight: .semibold)

        [speechProgress, fillerProgress, wpmProgress, pausesProgress].forEach {
            $0.progressTintColor = .systemPurple
            $0.trackTintColor = .systemGray5
        }

        setupMetricContent(card: speechMetricCard, title: speechTitle, value: "120 Words", progress: speechProgress)
        setupMetricContent(card: fillerMetricCard, title: fillerTitle, value: "6 (5%)", progress: fillerProgress)
        setupMetricContent(card: wpmMetricCard, title: wpmTitle, value: "55 WPM", progress: wpmProgress)
        setupMetricContent(card: pausesMetricCard, title: pausesTitle, value: "3", progress: pausesProgress)

        contentView.addSubview(callDurationTitle)
        contentView.addSubview(callDurationValue)
        callDurationTitle.translatesAutoresizingMaskIntoConstraints = false
        callDurationValue.translatesAutoresizingMaskIntoConstraints = false
    }

    func styleMetricCard(_ view: UIView) {
        view.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        view.layer.cornerRadius = 15
    }

    func setupMetricContent(card: UIView, title: UILabel, value: String, progress: UIProgressView) {

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .medium)

        title.font = .systemFont(ofSize: 14, weight: .semibold)

        [title, valueLabel, progress].forEach {
            card.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),

            valueLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant:  6),
            valueLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),

            progress.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 8),
            progress.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            progress.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            progress.heightAnchor.constraint(equalToConstant: 6)
        ])
    }

    // MARK: - Buttons
    func setupBottomButtons() {

        setupGradientButton(endButton, title: "END SESSION")
        setupGradientButton(newButton, title: "START NEW ONE")

        [endButton, newButton].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    func setupGradientButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.systemPurple.cgColor,
            UIColor.systemPink.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 25
        gradient.frame = CGRect(x: 0, y: 0, width: view.frame.width - 40, height: 50)
        button.layer.insertSublayer(gradient, at: 0)

        button.layer.cornerRadius = 25
        button.clipsToBounds = true
    }

    // MARK: - Layout
    func layoutUI() {

        NSLayoutConstraint.activate([

            // Titles
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            // Medal
            medalIcon.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
            medalIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            medalIcon.heightAnchor.constraint(equalToConstant: 34),
            medalIcon.widthAnchor.constraint(equalToConstant: 34),

            medalLabel.centerYAnchor.constraint(equalTo: medalIcon.centerYAnchor),
            medalLabel.leadingAnchor.constraint(equalTo: medalIcon.trailingAnchor, constant: 8),

            // Mistake Section
            mistakesTitle.topAnchor.constraint(equalTo: medalIcon.bottomAnchor, constant: 30),
            mistakesTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            mistakeCard1.topAnchor.constraint(equalTo: mistakesTitle.bottomAnchor, constant: 12),
            mistakeCard1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mistakeCard1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            mistakeCard2.topAnchor.constraint(equalTo: mistakeCard1.bottomAnchor, constant: 12),
            mistakeCard2.leadingAnchor.constraint(equalTo: mistakeCard1.leadingAnchor),
            mistakeCard2.trailingAnchor.constraint(equalTo: mistakeCard1.trailingAnchor),

            // Transcript
            transcriptCard.topAnchor.constraint(equalTo: mistakeCard2.bottomAnchor, constant: 30),
            transcriptCard.leadingAnchor.constraint(equalTo: mistakeCard1.leadingAnchor),
            transcriptCard.trailingAnchor.constraint(equalTo: mistakeCard1.trailingAnchor),

            transcriptTitle.topAnchor.constraint(equalTo: transcriptCard.topAnchor, constant: 14),
            transcriptTitle.leadingAnchor.constraint(equalTo: transcriptCard.leadingAnchor, constant: 14),

            transcriptToggle.centerYAnchor.constraint(equalTo: transcriptTitle.centerYAnchor),
            transcriptToggle.trailingAnchor.constraint(equalTo: transcriptCard.trailingAnchor, constant: -14),

            transcriptPreview.topAnchor.constraint(equalTo: transcriptTitle.bottomAnchor, constant: 10),
            transcriptPreview.leadingAnchor.constraint(equalTo: transcriptTitle.leadingAnchor),
            transcriptPreview.trailingAnchor.constraint(equalTo: transcriptToggle.trailingAnchor),

            transcriptFull.topAnchor.constraint(equalTo: transcriptPreview.bottomAnchor, constant: 6),
            transcriptFull.leadingAnchor.constraint(equalTo: transcriptPreview.leadingAnchor),
            transcriptFull.trailingAnchor.constraint(equalTo: transcriptPreview.trailingAnchor),
            transcriptFull.bottomAnchor.constraint(equalTo: transcriptCard.bottomAnchor, constant: -12),

            // Metrics Title
            metricsTitle.topAnchor.constraint(equalTo: transcriptCard.bottomAnchor, constant: 30),
            metricsTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            // Metric Cards
            speechMetricCard.topAnchor.constraint(equalTo: metricsTitle.bottomAnchor, constant: 20),
            speechMetricCard.leadingAnchor.constraint(equalTo: metricsTitle.leadingAnchor),
            speechMetricCard.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            speechMetricCard.heightAnchor.constraint(equalToConstant: 85),

            fillerMetricCard.topAnchor.constraint(equalTo: speechMetricCard.topAnchor),
            fillerMetricCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            fillerMetricCard.widthAnchor.constraint(equalTo: speechMetricCard.widthAnchor),
            fillerMetricCard.heightAnchor.constraint(equalToConstant: 85),

            wpmMetricCard.topAnchor.constraint(equalTo: speechMetricCard.bottomAnchor, constant: 15),
            wpmMetricCard.leadingAnchor.constraint(equalTo: speechMetricCard.leadingAnchor),
            wpmMetricCard.widthAnchor.constraint(equalTo: speechMetricCard.widthAnchor),
            wpmMetricCard.heightAnchor.constraint(equalToConstant: 85),

            pausesMetricCard.topAnchor.constraint(equalTo: fillerMetricCard.bottomAnchor, constant: 15),
            pausesMetricCard.trailingAnchor.constraint(equalTo: fillerMetricCard.trailingAnchor),
            pausesMetricCard.widthAnchor.constraint(equalTo: fillerMetricCard.widthAnchor),
            pausesMetricCard.heightAnchor.constraint(equalToConstant: 85),

            // Duration
            callDurationTitle.topAnchor.constraint(equalTo: pausesMetricCard.bottomAnchor, constant: 28),
            callDurationTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            callDurationValue.topAnchor.constraint(equalTo: callDurationTitle.bottomAnchor, constant: 6),
            callDurationValue.leadingAnchor.constraint(equalTo: callDurationTitle.leadingAnchor),

            // Buttons
            endButton.topAnchor.constraint(equalTo: callDurationValue.bottomAnchor, constant: 20),
            endButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            endButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            endButton.heightAnchor.constraint(equalToConstant: 50),

            newButton.topAnchor.constraint(equalTo: endButton.bottomAnchor, constant: 16),
            newButton.leadingAnchor.constraint(equalTo: endButton.leadingAnchor),
            newButton.trailingAnchor.constraint(equalTo: endButton.trailingAnchor),
            newButton.heightAnchor.constraint(equalToConstant: 50),
            newButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
}

