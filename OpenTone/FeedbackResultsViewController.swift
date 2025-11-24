import UIKit

final class FeedbackResultsViewController: UIViewController {

    // MARK: - MAIN SCROLL VIEW
    let scrollView = UIScrollView()
    let contentView = UIView()

    // MARK: - UI Elements
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    let analysisCard = UIView()
    let analysisTitleLabel = UILabel()
    let chatPreviewLabel = UILabel()
    let arrowButton = UIButton(type: .system)

    let expandedChatView = UILabel()

    var isExpanded = false

    // MARK: - Metrics UI
    let metricsTitle = UILabel()

    let speechMetricCard = UIView()
    let fillerMetricCard = UIView()
    let wpmMetricCard = UIView()
    let pausesMetricCard = UIView()

    // Buttons
    let endButton = UIButton(type: .system)
    let newButton = UIButton(type: .system)
    
    
    
    // Medal UI
    let medalIcon = UIImageView(image: UIImage(systemName: "medal.fill"))
    let medalLabel = UILabel()

    // Progress Views
    let speechProgress = UIProgressView(progressViewStyle: .default)
    let fillerProgress = UIProgressView(progressViewStyle: .default)
    let wpmProgress = UIProgressView(progressViewStyle: .default)
    let pausesProgress = UIProgressView(progressViewStyle: .default)

    // Metric Labels
    let speechTitle = UILabel()
    let fillerTitle = UILabel()
    let wpmTitle = UILabel()
    let pausesTitle = UILabel()
    let callDurationTitle = UILabel()
    let callDurationValue = UILabel()



    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemGray6

        setupScrollView()
        setupUI()
        layoutUI()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateMetrics()
        animateMedal()
    }

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

        UIView.animate(withDuration: 0.6,
                       delay: 0.3,
                       usingSpringWithDamping: 0.4,
                       initialSpringVelocity: 1,
                       options: [],
                       animations: {
            self.medalIcon.transform = .identity
            self.medalLabel.alpha = 1
        })
    }


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

    func setupUI() {

        // Title
        titleLabel.text = "Feedback & Results"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        subtitleLabel.text = "Great Job User! Here's your analysis:"
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.textColor = .systemTeal

        // Analysis Card
        analysisCard.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.15)
        analysisCard.layer.cornerRadius = 22
        analysisCard.layer.shadowColor = UIColor.black.cgColor
        analysisCard.layer.shadowOpacity = 0.1
        analysisCard.layer.shadowRadius = 10
        analysisCard.layer.shadowOffset = CGSize(width: 0, height: 4)

        analysisTitleLabel.text = "Conversation Analysis"
        analysisTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        chatPreviewLabel.text = "Hey! How are you?\nWhat did you learn recently?"
        chatPreviewLabel.numberOfLines = 0

        // Arrow
        let arrowImage = UIImage(systemName: "chevron.down.circle.fill")
        arrowButton.setImage(arrowImage, for: .normal)
        arrowButton.tintColor = .systemPurple
        arrowButton.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)

        // Expanded Chat
        expandedChatView.text = "ooh.. I learned new things…\nI am learning stock marketing now a days.\nMore detailed analysis…"
        expandedChatView.font = .systemFont(ofSize: 15)
        expandedChatView.numberOfLines = 0
        expandedChatView.alpha = 0  // Hidden initially

        // Metrics
        metricsTitle.text = "Key Metrics"
        metricsTitle.font = .systemFont(ofSize: 22, weight: .bold)

        [speechMetricCard, fillerMetricCard, wpmMetricCard, pausesMetricCard].forEach {
            styleMetricCard($0)
        }

        // Buttons
        setupGradientButton(endButton, title: "END SESSION")
        setupGradientButton(newButton, title: "START NEW ONE")

        // ADD TO CONTENT VIEW
        [
            titleLabel, subtitleLabel,
            analysisCard, analysisTitleLabel, chatPreviewLabel, arrowButton, expandedChatView,
            metricsTitle,
            speechMetricCard, fillerMetricCard, wpmMetricCard, pausesMetricCard,
            endButton, newButton
        ].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        
        // Medal
        medalIcon.tintColor = .systemYellow
        medalIcon.contentMode = .scaleAspectFit

        medalLabel.text = "+12"
        medalLabel.font = .systemFont(ofSize: 28, weight: .bold)
        medalLabel.textColor = .systemGreen

        // Metric Titles
        speechTitle.text = "Speech Length"
        fillerTitle.text = "Filler Words"
        wpmTitle.text = "Words Per Minute"
        pausesTitle.text = "Pauses"
        callDurationTitle.text = "Call Duration: "
        callDurationValue.text  = "3.15"
        callDurationTitle.font = .systemFont(ofSize: 18, weight: .semibold)
        callDurationValue.font = .systemFont(ofSize: 18, weight: .semibold)

        // Progress colors
        [speechProgress, fillerProgress, wpmProgress, pausesProgress].forEach {
            $0.progressTintColor = .systemPurple
            $0.trackTintColor = .systemGray5
        }

        // Add to metric cards
        setupMetricContent(card: speechMetricCard, title: speechTitle, value: "120 Words", progress: speechProgress)
        setupMetricContent(card: fillerMetricCard, title: fillerTitle, value: "6 (5%)", progress: fillerProgress)
        setupMetricContent(card: wpmMetricCard, title: wpmTitle, value: "55 WPM", progress: wpmProgress)
        setupMetricContent(card: pausesMetricCard, title: pausesTitle, value: "3", progress: pausesProgress)

        // Medal add
        contentView.addSubview(medalIcon)
        contentView.addSubview(medalLabel)
        
        
        
        contentView.addSubview(callDurationTitle)
        contentView.addSubview(callDurationValue)
        contentView.addSubview(endButton)
        contentView.addSubview(newButton)


    }

    func layoutUI() {

        NSLayoutConstraint.activate([

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            analysisCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            analysisCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            analysisCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            analysisCard.heightAnchor.constraint(equalToConstant: 170),

            analysisTitleLabel.topAnchor.constraint(equalTo: analysisCard.topAnchor, constant: 15),
            analysisTitleLabel.leadingAnchor.constraint(equalTo: analysisCard.leadingAnchor, constant: 15),

            chatPreviewLabel.topAnchor.constraint(equalTo: analysisTitleLabel.bottomAnchor, constant: 10),
            chatPreviewLabel.leadingAnchor.constraint(equalTo: analysisTitleLabel.leadingAnchor),

            arrowButton.topAnchor.constraint(equalTo: chatPreviewLabel.bottomAnchor, constant: 10),
            arrowButton.centerXAnchor.constraint(equalTo: analysisCard.centerXAnchor),

            expandedChatView.topAnchor.constraint(equalTo: arrowButton.bottomAnchor, constant: 10),
            expandedChatView.leadingAnchor.constraint(equalTo: analysisCard.leadingAnchor, constant: 15),
            expandedChatView.trailingAnchor.constraint(equalTo: analysisCard.trailingAnchor, constant: -15),

            metricsTitle.topAnchor.constraint(equalTo: analysisCard.bottomAnchor, constant: 30),
            metricsTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            speechMetricCard.topAnchor.constraint(equalTo: metricsTitle.bottomAnchor, constant: 20),
            speechMetricCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            speechMetricCard.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            speechMetricCard.heightAnchor.constraint(equalToConstant: 80),

            fillerMetricCard.topAnchor.constraint(equalTo: metricsTitle.bottomAnchor, constant: 20),
            fillerMetricCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            fillerMetricCard.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            fillerMetricCard.heightAnchor.constraint(equalToConstant: 80),

            wpmMetricCard.topAnchor.constraint(equalTo: speechMetricCard.bottomAnchor, constant: 15),
            wpmMetricCard.leadingAnchor.constraint(equalTo: speechMetricCard.leadingAnchor),
            wpmMetricCard.widthAnchor.constraint(equalTo: speechMetricCard.widthAnchor),
            wpmMetricCard.heightAnchor.constraint(equalToConstant: 80),

            pausesMetricCard.topAnchor.constraint(equalTo: fillerMetricCard.bottomAnchor, constant: 15),
            pausesMetricCard.trailingAnchor.constraint(equalTo: fillerMetricCard.trailingAnchor),
            pausesMetricCard.widthAnchor.constraint(equalTo: fillerMetricCard.widthAnchor),
            pausesMetricCard.heightAnchor.constraint(equalToConstant: 80),

            endButton.topAnchor.constraint(equalTo: callDurationValue.bottomAnchor, constant: 20),
                endButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                endButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                endButton.heightAnchor.constraint(equalToConstant: 50),

                newButton.topAnchor.constraint(equalTo: endButton.bottomAnchor, constant: 16),
                newButton.leadingAnchor.constraint(equalTo: endButton.leadingAnchor),
                newButton.trailingAnchor.constraint(equalTo: endButton.trailingAnchor),
                newButton.heightAnchor.constraint(equalToConstant: 50),

                newButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)

        ])
        
        
        medalIcon.translatesAutoresizingMaskIntoConstraints = false
        medalLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            medalIcon.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16), // was 5
            medalIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24), // was -40
            medalIcon.heightAnchor.constraint(equalToConstant: 34),
            medalIcon.widthAnchor.constraint(equalToConstant: 34),

            medalLabel.centerYAnchor.constraint(equalTo: medalIcon.centerYAnchor),
            medalLabel.leadingAnchor.constraint(equalTo: medalIcon.trailingAnchor, constant: 10) // was 6
        ])

        
        
        callDurationTitle.translatesAutoresizingMaskIntoConstraints = false
        callDurationValue.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(callDurationTitle)
        contentView.addSubview(callDurationValue)

        NSLayoutConstraint.activate([
            callDurationTitle.topAnchor.constraint(equalTo: pausesMetricCard.bottomAnchor, constant: 28),
            callDurationTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            callDurationValue.topAnchor.constraint(equalTo: callDurationTitle.bottomAnchor, constant: 6),
            callDurationValue.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])



    }


    @objc func toggleExpand() {
        isExpanded.toggle()

        UIView.animate(withDuration: 0.3) {
            self.expandedChatView.alpha = self.isExpanded ? 1 : 0
            let rotation: CGFloat = self.isExpanded ? .pi : 0
            self.arrowButton.transform = CGAffineTransform(rotationAngle: rotation)

            // Expand card height
            self.analysisCard.constraints.first { $0.firstAttribute == .height }?
                .constant = self.isExpanded ? 300 : 170

            self.view.layoutIfNeeded()
        }
    }

    func styleMetricCard(_ view: UIView) {
        view.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        view.layer.cornerRadius = 15
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

            valueLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            valueLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),

            progress.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 8),
            progress.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            progress.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            progress.heightAnchor.constraint(equalToConstant: 6)
        ])
    }

    
    
}
