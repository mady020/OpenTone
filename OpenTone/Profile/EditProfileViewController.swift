import UIKit

/// Full-screen profile editor. Lets the user update their avatar, name, bio,
/// country, and English level. All changes persist through SessionManager →
/// UserDataModel immediately.
final class EditProfileViewController: UIViewController {

    // MARK: - Callback

    var onProfileUpdated: (() -> Void)?

    // MARK: - Data

    private var editableUser: User?

    private let avatarOptions = ["pp1", "pp2"]  // Asset catalog images

    private let countryList: [Country] = [
        Country(name: "India", code: "IN"),
        Country(name: "United States", code: "US"),
        Country(name: "United Kingdom", code: "GB"),
        Country(name: "Canada", code: "CA"),
        Country(name: "Australia", code: "AU"),
        Country(name: "Germany", code: "DE"),
        Country(name: "France", code: "FR"),
        Country(name: "Japan", code: "JP"),
        Country(name: "Brazil", code: "BR"),
        Country(name: "Mexico", code: "MX"),
        Country(name: "South Korea", code: "KR"),
        Country(name: "Italy", code: "IT"),
        Country(name: "Spain", code: "ES"),
        Country(name: "Netherlands", code: "NL"),
        Country(name: "Singapore", code: "SG"),
    ]

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 50
        iv.layer.borderWidth = 3
        iv.layer.borderColor = AppColors.primary.cgColor
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 100),
            iv.heightAnchor.constraint(equalToConstant: 100),
        ])
        return iv
    }()

    private let changePhotoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Change Photo", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(AppColors.primary, for: .normal)
        return btn
    }()

    private let nameField = EditProfileViewController.makeTextField(placeholder: "Full Name")
    private let bioTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.textColor = AppColors.textPrimary
        tv.backgroundColor = AppColors.cardBackground
        tv.layer.cornerRadius = 12
        tv.layer.borderWidth = 1
        tv.layer.borderColor = AppColors.cardBorder.cgColor
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        tv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tv.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        return tv
    }()

    private let countryButton = EditProfileViewController.makePickerButton(title: "Select Country")
    private let levelButton = EditProfileViewController.makePickerButton(title: "English Level")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Profile"
        view.backgroundColor = AppColors.screenBackground

        navigationItem.largeTitleDisplayMode = .never

        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        saveButton.tintColor = AppColors.primary
        navigationItem.rightBarButtonItem = saveButton

        editableUser = SessionManager.shared.currentUser

        setupUI()
        populateFields()
    }

    // MARK: - Setup

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        // Avatar section
        let avatarStack = UIStackView(arrangedSubviews: [avatarImageView, changePhotoButton])
        avatarStack.axis = .vertical
        avatarStack.alignment = .center
        avatarStack.spacing = 8
        contentStack.addArrangedSubview(avatarStack)

        changePhotoButton.addTarget(self, action: #selector(changePhotoTapped), for: .touchUpInside)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changePhotoTapped))
        avatarImageView.addGestureRecognizer(tapGesture)

        // Name
        contentStack.addArrangedSubview(makeSectionLabel("Name"))
        contentStack.addArrangedSubview(nameField)

        // Bio
        contentStack.addArrangedSubview(makeSectionLabel("Bio"))
        contentStack.addArrangedSubview(bioTextView)

        // Country
        contentStack.addArrangedSubview(makeSectionLabel("Country"))
        countryButton.addTarget(self, action: #selector(countryTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(countryButton)

        // English Level
        contentStack.addArrangedSubview(makeSectionLabel("English Level"))
        levelButton.addTarget(self, action: #selector(levelTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(levelButton)
    }

    private func populateFields() {
        guard let user = editableUser else { return }

        avatarImageView.image = ProfileStoryboardCollectionViewController.loadAvatar(named: user.avatar)
        nameField.text = user.name
        bioTextView.text = user.bio ?? ""

        if let country = user.country {
            countryButton.setTitle("\(country.flag) \(country.name)", for: .normal)
            countryButton.setTitleColor(AppColors.textPrimary, for: .normal)
        }

        if let level = user.englishLevel {
            levelButton.setTitle(level.rawValue.capitalized, for: .normal)
            levelButton.setTitleColor(AppColors.textPrimary, for: .normal)
        }
    }

    // MARK: - Actions

    @objc private func saveTapped() {
        guard var user = editableUser else { return }

        let newName = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !newName.isEmpty else {
            showAlert(title: "Invalid Name", message: "Name cannot be empty.")
            return
        }

        user.name = newName
        user.bio = bioTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        SessionManager.shared.updateSessionUser(user)
        onProfileUpdated?()
        navigationController?.popViewController(animated: true)
    }

    @objc private func changePhotoTapped() {
        let alert = UIAlertController(title: "Choose Avatar", message: nil, preferredStyle: .actionSheet)

        for avatarName in avatarOptions {
            let action = UIAlertAction(title: avatarName, style: .default) { [weak self] _ in
                self?.editableUser?.avatar = avatarName
                self?.avatarImageView.image = UIImage(named: avatarName)
            }
            if let img = UIImage(named: avatarName) {
                let size = CGSize(width: 40, height: 40)
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                img.draw(in: CGRect(origin: .zero, size: size))
                let resized = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                action.setValue(resized?.withRenderingMode(.alwaysOriginal), forKey: "image")
            }
            alert.addAction(action)
        }

        // Option to pick from photo library
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.openPhotoLibrary()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = avatarImageView
            popover.sourceRect = avatarImageView.bounds
        }

        present(alert, animated: true)
    }

    private func openPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    @objc private func countryTapped() {
        let alert = UIAlertController(title: "Select Country", message: nil, preferredStyle: .actionSheet)

        for country in countryList {
            let action = UIAlertAction(title: "\(country.flag) \(country.name)", style: .default) { [weak self] _ in
                self?.editableUser?.country = country
                self?.countryButton.setTitle("\(country.flag) \(country.name)", for: .normal)
                self?.countryButton.setTitleColor(AppColors.textPrimary, for: .normal)
            }
            if country.code == editableUser?.country?.code {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = countryButton
            popover.sourceRect = countryButton.bounds
        }

        present(alert, animated: true)
    }

    @objc private func levelTapped() {
        let alert = UIAlertController(title: "English Level", message: nil, preferredStyle: .actionSheet)

        for level in [EnglishLevel.beginner, .intermediate, .advanced] {
            let action = UIAlertAction(title: level.rawValue.capitalized, style: .default) { [weak self] _ in
                self?.editableUser?.englishLevel = level
                self?.levelButton.setTitle(level.rawValue.capitalized, for: .normal)
                self?.levelButton.setTitleColor(AppColors.textPrimary, for: .normal)
            }
            if level == editableUser?.englishLevel {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = levelButton
            popover.sourceRect = levelButton.bounds
        }

        present(alert, animated: true)
    }

    // MARK: - Helpers

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private static func makeTextField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = .systemFont(ofSize: 16)
        tf.textColor = AppColors.textPrimary
        tf.backgroundColor = AppColors.cardBackground
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = AppColors.cardBorder.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.rightViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return tf
    }

    private static func makePickerButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.secondaryLabel, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.contentHorizontalAlignment = .leading
        btn.backgroundColor = AppColors.cardBackground
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1
        btn.layer.borderColor = AppColors.cardBorder.cgColor
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true

        // Add disclosure indicator
        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = .secondaryLabel
        chevron.translatesAutoresizingMaskIntoConstraints = false
        btn.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -12),
            chevron.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 14),
            chevron.heightAnchor.constraint(equalToConstant: 8),
        ])

        return btn
    }
}

// MARK: - UIImagePickerControllerDelegate

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        guard let editedImage = info[.editedImage] as? UIImage
                ?? info[.originalImage] as? UIImage else { return }

        avatarImageView.image = editedImage

        // Save the custom image to documents and store the file name
        let fileName = "custom_avatar_\(UUID().uuidString).jpg"
        if let data = editedImage.jpegData(compressionQuality: 0.8) {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent(fileName)
            try? data.write(to: fileURL, options: .atomic)
            editableUser?.avatar = fileName
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
