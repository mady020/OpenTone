import UIKit

class InterestsCell: UICollectionViewCell {
    static let reuseId = "InterestsCell"
    
    // MARK: - UI Components
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Interests"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .label
        return label
    }()
    
    private let chipsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        return cv
    }()
    
    private var interests: [String] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}


// MARK: - UI Setup

extension InterestsCell {
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(chipsCollectionView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        chipsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Title label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Chips collection
            chipsCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            chipsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chipsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chipsCollectionView.heightAnchor.constraint(equalToConstant: 36),
            
            // Bottom
            chipsCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupCollectionView() {
        chipsCollectionView.dataSource = self
        chipsCollectionView.delegate = self
        chipsCollectionView.register(InterestChipCell.self, forCellWithReuseIdentifier: InterestChipCell.reuseId)
    }
}


// MARK: - Configure

extension InterestsCell {
    func configure(with interests: [String]) {
        self.interests = interests
        chipsCollectionView.reloadData()
    }
}


// MARK: - Collection Data Source

extension InterestsCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return interests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InterestChipCell.reuseId, for: indexPath) as! InterestChipCell
        cell.configure(text: interests[indexPath.item])
        return cell
    }
    
    // Dynamic chip sizing
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let text = interests[indexPath.item]
        let size = (text as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
        
        return CGSize(width: size.width + 24, height: 32)  // padding + height
    }
}
