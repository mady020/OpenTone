//
//  SignUpViewController.swift
//  OpenTone
//
//  Created by Student on 13/11/25.
//
import UIKit

class SignUpViewController: UIViewController {
    
    private let containerView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let signUpButton = UIButton(type: .system)
    private let appleButton = UIButton(type: .system)
    private let signInLinkButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        setupUI()
    }
    
    private func setupUI() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.systemPurple.withAlphaComponent(0.1).cgColor,
                                UIColor.systemPink.withAlphaComponent(0.1).cgColor]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        let titleLabel = UILabel()
        titleLabel.text = "OpenTone"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 34)
        titleLabel.textColor = UIColor.systemPurple
        titleLabel.textAlignment = .center
        
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        
        nameField.placeholder = "Enter full name"
        nameField.borderStyle = .roundedRect
        
        emailField.placeholder = "Enter email"
        emailField.borderStyle = .roundedRect
        emailField.keyboardType = .emailAddress
        
        passwordField.placeholder = "Create password"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        
        configureGlassButton(signUpButton, title: "Sign Up")
        configureGlassButton(appleButton, title: "Sign Up With Apple")
        appleButton.backgroundColor = .black
        appleButton.setTitleColor(.white, for: .normal)
        
        signInLinkButton.setTitle("Already have an account? Sign In", for: .normal)
        signInLinkButton.tintColor = .systemPurple
        signInLinkButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        signInLinkButton.addTarget(self, action: #selector(openSignIn), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [nameField, emailField, passwordField, signUpButton, appleButton, signInLinkButton])
        stack.axis = .vertical
        stack.spacing = 15
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(containerView)
        containerView.contentView.addSubview(stack)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            containerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            stack.topAnchor.constraint(equalTo: containerView.contentView.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor, constant: -30),
            
            signUpButton.heightAnchor.constraint(equalToConstant: 50),
            appleButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureGlassButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.6)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.systemPurple.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 10
    }
    
    @objc private func openSignIn() {
        dismiss(animated: true)
    }
}
