//
//  LoginViewController.swift
//  OpenTone
//
//  Created by Student on 13/11/25.
//

import UIKit

class LoginViewController: UIViewController {
    
    private let containerView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let rememberSwitch = UISwitch()
    private let rememberLabel = UILabel()
    private let forgotPasswordButton = UIButton(type: .system)
    private let signInButton = UIButton(type: .system)
    private let appleButton = UIButton(type: .system)
    private let signupLinkButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        
        setupUI()
    }
    
    private func setupUI() {
        // Gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.systemPurple.withAlphaComponent(0.1).cgColor,
                                UIColor.systemPink.withAlphaComponent(0.1).cgColor]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "OpenTone"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 34)
        titleLabel.textColor = UIColor.systemPurple
        titleLabel.textAlignment = .center
        
        // Container style
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        
        // Fields
        usernameField.placeholder = "User name"
        usernameField.borderStyle = .roundedRect
        
        passwordField.placeholder = "Enter password"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect
        
        rememberLabel.text = "Remember Me"
        rememberLabel.font = UIFont.systemFont(ofSize: 14)
        
        forgotPasswordButton.setTitle("Forgot password?", for: .normal)
        forgotPasswordButton.tintColor = .systemPurple
        forgotPasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        
        // Sign In button (liquid glass style)
        configureGlassButton(signInButton, title: "Sign In")
        
        // Apple button
        configureGlassButton(appleButton, title: "Sign in With Apple")
        appleButton.backgroundColor = .black
        appleButton.setTitleColor(.white, for: .normal)
        
        // Sign Up link
        signupLinkButton.setTitle("Don’t have account? Sign Up", for: .normal)
        signupLinkButton.tintColor = .systemPurple
        signupLinkButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        signupLinkButton.addTarget(self, action: #selector(openSignUp), for: .touchUpInside)
        
        // Layout
        let stack = UIStackView(arrangedSubviews: [
            usernameField, passwordField,
            rememberLabel, signInButton,
            appleButton, signupLinkButton
        ])
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
            
            signInButton.heightAnchor.constraint(equalToConstant: 50),
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
    
    @objc private func openSignUp() {
        let vc = SignUpViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}

    // In a storyboard-based application, you will often want to do a little preparation before navigation
   
