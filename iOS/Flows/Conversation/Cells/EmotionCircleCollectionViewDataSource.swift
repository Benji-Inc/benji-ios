//
//  EmotionCircleCollectionViewDataSource.swift
//  Jibber
//
//  Created by Martin Young on 4/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

typealias EmotionCircleSection = EmotionCircleCollectionViewDataSource.SectionType
typealias EmotionCircleItem = EmotionCircleCollectionViewDataSource.ItemType

class EmotionCircleCollectionViewDataSource: CollectionViewDataSource<EmotionCircleSection,
                                                EmotionCircleItem> {

    enum SectionType: Int, Hashable {
        case emotions
    }

    struct ItemType: Hashable {
        let emotion: Emotion
    }

    // Cell registration
    private let emotionCellRegistration
    = EmotionCircleCollectionViewDataSource.createEmotionCellRegistration()

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

            let emotionCell
            = collectionView.dequeueConfiguredReusableCell(using: self.emotionCellRegistration,
                                                           for: indexPath,
                                                           item: item)
            return emotionCell
    }
}

// MARK: - Cell Registration

extension EmotionCircleCollectionViewDataSource {

    typealias EmotionCellRegistration = UICollectionView.CellRegistration<EmotionCircleCell,
                                                                            EmotionCircleItem>
    static func createEmotionCellRegistration() -> EmotionCellRegistration {
        return EmotionCellRegistration { cell, indexPath, item in
            cell.configure(with: item.emotion)
        }
    }
}

class EmotionCircleCell: UICollectionViewCell {

    private let label = ThemeLabel(font: .regular, textColor: .white)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.clipsToBounds = true

        self.addSubview(self.label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.halfWidth

        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }

    func configure(with emotion: Emotion) {
        self.label.text = emotion.rawValue
        self.backgroundColor = emotion.color.withAlphaComponent(0.6)

        self.setNeedsLayout()
    }

    // MARK: - UIDynamicItem

    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .ellipse
    }
}
