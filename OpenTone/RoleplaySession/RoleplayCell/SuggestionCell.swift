import UIKit

protocol SuggestionCellDelegate: AnyObject {
    func didTapSuggestion(_ suggestion: String)
}

class SuggestionCell: UITableViewCell {

    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!

    weak var delegate: SuggestionCellDelegate?

    override func prepareForReuse() {
        super.prepareForReuse()
        button1.isHidden = true
        button2.isHidden = true
        button3.isHidden = true
    }

    func configure(_ suggestions: [String]) {
        let buttons = [button1, button2, button3]

        for (index, suggestion) in suggestions.enumerated() {
            guard index < buttons.count else { break }
            let btn = buttons[index]!

            btn.setTitle(suggestion, for: .normal)
            btn.isHidden = false
        }
    }

    @IBAction func suggestionTapped(_ sender: UIButton) {
        if let text = sender.title(for: .normal) {
            delegate?.didTapSuggestion(text)
        }
    }

}
