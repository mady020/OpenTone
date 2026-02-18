import UIKit

final class EditProfileViewController: UIViewController {


    var onProfileUpdated: (() -> Void)?


    private var editableUser: User?

    private let avatarOptions = ["pp1", "pp2"]

    private let allInterestItems = InterestItem.allItems

    private var selectedInterests: Set<InterestItem> = []

    private var interestsHeightConstraint: NSLayoutConstraint!


    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var changePhotoButton: UIButton!
    @IBOutlet private weak var nameField: UITextField!
    @IBOutlet private weak var bioTextView: UITextView!
    @IBOutlet private weak var countryButton: UIButton!
    @IBOutlet private weak var levelButton: UIButton!
    @IBOutlet private weak var interestsCollectionView: UICollectionView!


    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Profile"
        view.backgroundColor = AppColors.screenBackground

        navigationItem.largeTitleDisplayMode = .never

        let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))
        saveButton.tintColor = AppColors.primary
        navigationItem.rightBarButtonItem = saveButton

        editableUser = SessionManager.shared.currentUser

        styleUI()
        setupInterestsCollectionView()
        populateFields()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        interestsCollectionView.reloadData()
    }


    private func styleUI() {

        avatarImageView.layer.cornerRadius = 50
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = AppColors.primary.cgColor

        changePhotoButton.setTitleColor(AppColors.primary, for: .normal)
        changePhotoButton.addTarget(self, action: #selector(changePhotoTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changePhotoTapped))
        avatarImageView.addGestureRecognizer(tapGesture)

        nameField.textColor = AppColors.textPrimary
        nameField.backgroundColor = AppColors.cardBackground
        nameField.layer.cornerRadius = 12
        nameField.layer.borderWidth = 1
        nameField.layer.borderColor = AppColors.cardBorder.cgColor
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        nameField.leftViewMode = .always
        nameField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        nameField.rightViewMode = .always

        bioTextView.textColor = AppColors.textPrimary
        bioTextView.backgroundColor = AppColors.cardBackground
        bioTextView.layer.cornerRadius = 12
        bioTextView.layer.borderWidth = 1
        bioTextView.layer.borderColor = AppColors.cardBorder.cgColor
        bioTextView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)

        stylePickerButton(countryButton, placeholder: "Select Country")

        stylePickerButton(levelButton, placeholder: "English Level")
    }

    private func stylePickerButton(_ btn: UIButton, placeholder: String) {
        btn.setTitleColor(.secondaryLabel, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.backgroundColor = AppColors.cardBackground
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1
        btn.layer.borderColor = AppColors.cardBorder.cgColor

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

        selectedInterests = user.interests ?? []
        interestsCollectionView.reloadData()
        updateInterestsHeight()
    }

    @objc private func saveTapped() {
        guard var user = editableUser else { return }

        let newName = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !newName.isEmpty else {
            showAlert(title: "Invalid Name", message: "Name cannot be empty.")
            return
        }

        user.name = newName
        user.bio = bioTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        user.interests = selectedInterests

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
        let storyboard = UIStoryboard(name: "UserOnboarding", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "CountryPickerViewController"
        ) as! CountryPickerViewController

        vc.onSelect = { [weak self] country in
            self?.editableUser?.country = country
            self?.countryButton.setTitle("\(country.flag) \(country.name)", for: .normal)
            self?.countryButton.setTitleColor(AppColors.textPrimary, for: .normal)
        }

        present(vc, animated: true)
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


    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension EditProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    fileprivate func setupInterestsCollectionView() {
        interestsCollectionView.collectionViewLayout = makeInterestsLayout()
        interestsCollectionView.backgroundColor = .clear
        interestsCollectionView.isScrollEnabled = false
        interestsCollectionView.dataSource = self
        interestsCollectionView.delegate = self

        interestsCollectionView.register(
            UINib(nibName: "InterestCard", bundle: nil),
            forCellWithReuseIdentifier: InterestCard.reuseIdentifier
        )

        interestsHeightConstraint = interestsCollectionView.heightAnchor.constraint(equalToConstant: 320)
        interestsHeightConstraint.isActive = true
    }

    private func makeInterestsLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / 3.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(120)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item, item, item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            return section
        }
    }

    fileprivate func updateInterestsHeight() {
        let rows = ceil(Double(allInterestItems.count) / 3.0)
        let height = rows * 120 + (rows - 1) * 8
        interestsHeightConstraint.constant = CGFloat(height)
        interestsCollectionView.layoutIfNeeded()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        allInterestItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InterestCard.reuseIdentifier,
            for: indexPath
        ) as! InterestCard

        let item = allInterestItems[indexPath.item]
        let isSelected = selectedInterests.contains(item)

        cell.configure(
            with: item,
            backgroundColor: isSelected ? AppColors.primary : AppColors.cardBackground,
            tintColor: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            borderColor: AppColors.cardBorder,
            selected: isSelected
        )

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = allInterestItems[indexPath.item]

        if selectedInterests.contains(item) {
            selectedInterests.remove(item)
        } else {
            selectedInterests.insert(item)
        }

        collectionView.reloadItems(at: [indexPath])
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        guard let editedImage = info[.editedImage] as? UIImage
                ?? info[.originalImage] as? UIImage else { return }

        avatarImageView.image = editedImage

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
