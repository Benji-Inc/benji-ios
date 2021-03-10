//
//  FeedCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedCollectionViewManger: CollectionViewManager<FeedCollectionViewManger.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case feed = 0
    }

    private let config = ManageableCellRegistration<FeedCell>().cellProvider

    var items: [FakeItem] = []

    override func initialize() {
        super.initialize()

        self.collectionView.collectionViewLayout = self.createLayout()
        self.collectionView.animationView.play()

        for _ in 0...10 {
            self.items.append(FakeItem())
        }

        self.loadSnapshot()
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        switch section {
        case .feed:
            return self.items
        }
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .feed:
            return self.collectionView.dequeueManageableCell(using: self.config,
                                                             for: indexPath,
                                                             item: item as? FakeItem)
        }
    }

    func createLayout() -> UICollectionViewCompositionalLayout {
        let fraction: CGFloat = 1 / 5

        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(fraction))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        // Section
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
}
