//
//  ChatViewControllerScreen.swift
//  OpenTone
//
//  Created by Student on 01/12/25.
//

import UIKit

// MARK: - MODEL

enum MessageSender {
    case user
    case app
}

struct ChatMessage {
    let text: String
    let sender: MessageSender
}

// MARK: - CELL

class ChatMessageCell: UICollectionViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        messageLabel.numberOfLines = 0
        messageLabel.layer.cornerRadius = 12
        messageLabel.clipsToBounds = true
    }
    
    func configure(with message: ChatMessage) {
        
        messageLabel.text = message.text
        
        if message.sender == .user {
            messageLabel.textAlignment = .right
            messageLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            userImageView.image = UIImage(named: "userPic")  // Your user's image
        } else {
            messageLabel.textAlignment = .left
            messageLabel.backgroundColor = UIColor.systemGray6
            userImageView.image = UIImage(named: "botPic")   // Your app's bot image
        }
    }
}

// MARK: - CHAT VIEW CONTROLLER

class ChatViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var messageTextField: UITextField!
    
    var messages: [ChatMessage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        loadInitialMessages()
    }
    
    // MARK: - Load starting messages
    func loadInitialMessages() {
        messages.append(ChatMessage(text: "Hi! I will guide you in this role-play.", sender: .app))
        messages.append(ChatMessage(text: "Okay, I’m ready!", sender: .user))

        collectionView.reloadData()
        scrollToBottom()
    }
    
    // MARK: - Send message
    @IBAction func sendBtnTapped(_ sender: UIButton) {
        guard let text = messageTextField.text, !text.isEmpty else { return }
        
        let msg = ChatMessage(text: text, sender: .user)
        messages.append(msg)
        messageTextField.text = ""
        
        collectionView.reloadData()
        scrollToBottom()
        
        replyFromApp()
    }
    
    // MARK: - Auto reply from app
    func replyFromApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let reply = ChatMessage(text: "This is app’s reply to your message.", sender: .app)
            self.messages.append(reply)
            self.collectionView.reloadData()
            self.scrollToBottom()
        }
    }
    
    // MARK: - Scroll helper
    func scrollToBottom() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }
}

// MARK: - COLLECTION VIEW

extension ChatViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ChatMessageCell",
            for: indexPath
        ) as! ChatMessageCell
        
        let msg = messages[indexPath.item]
        cell.configure(with: msg)
        
        return cell
    }
    
    // Auto height for each message
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let msg = messages[indexPath.item].text
        
        let width = collectionView.frame.width * 0.75
        
        let size = msg.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 16)],
            context: nil
        )
        
        return CGSize(width: collectionView.frame.width,
                      height: size.height + 40)
    }
}
