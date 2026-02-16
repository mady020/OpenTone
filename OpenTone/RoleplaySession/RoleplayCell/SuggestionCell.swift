import UIKit

protocol SuggestionCellDelegate: AnyObject {
    func didTapSuggestion(_ suggestion: String)
}

class SuggestionCell: UITableViewCell {

    weak var delegate: SuggestionCellDelegate?

    private let stackView = UIStackView()
    private var suggestionButtons: [UIButton] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupStack()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStack()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none
        // Stack is already set up from init(coder:)
    }

    private func setupStack() {
        backgroundColor = .clear
        selectionStyle = .none

        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .trailing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        for button in suggestionButtons {
            button.removeFromSuperview()
        }
        suggestionButtons.removeAll()
    }

    func configure(_ suggestions: [String]) {
        // Clear old buttons
        for button in suggestionButtons {
            button.removeFromSuperview()
        }
        suggestionButtons.removeAll()

        for suggestion in suggestions {
            let button = makeSuggestionButton(title: suggestion)
            stackView.addArrangedSubview(button)
            suggestionButtons.append(button)
        }
    }

    private func makeSuggestionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        button.configuration = config
        button.setTitle(title, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(AppColors.primary, for: .normal)
        button.backgroundColor = AppColors.primaryLight
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 1
        button.layer.borderColor = AppColors.primary.withAlphaComponent(0.25).cgColor
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)

        // Match chat bubble corner style — round top-left, top-right, bottom-left
        button.layer.maskedCorners = [
            .layerMinXMinYCorner,  // top-left
            .layerMaxXMinYCorner,  // top-right
            .layerMinXMaxYCorner   // bottom-left
        ]

        // Max width so long text wraps
        button.widthAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true

        return button
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        for button in suggestionButtons {
            button.isEnabled = false
            button.alpha = 0.5
        }
        delegate?.didTapSuggestion(text)
    }
}
