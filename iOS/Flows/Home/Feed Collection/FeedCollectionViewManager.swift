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

    lazy var layout: UICollectionViewCompositionalLayout = {
        let widthFraction: CGFloat = 0.2
        let heightFraction: CGFloat = 0.45

        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(widthFraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let verticalInset: CGFloat = 10
        let horizontalInset: CGFloat = 5
        item.contentInsets = NSDirectionalEdgeInsets(top: verticalInset, leading: horizontalInset, bottom: verticalInset, trailing: horizontalInset)

        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        // Section
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }()

    func loadFeeds() {

        self.collectionView.collectionViewLayout = self.layout

        self.collectionView.animationView.play()

        FeedManager.shared.$feeds.mainSink { feeds in
            let cycle = AnimationCycle(inFromPosition: .inward, outToPosition: .inward, shouldConcatenate: true, scrollToEnd: false)
            self.loadSnapshot(animationCycle: cycle)
                .mainSink { _ in
                    self.collectionView.animationView.stop()
                }.store(in: &self.cancellables)
        }.store(in: &self.cancellables)
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        switch section {
        case .feed:
            return FeedManager.shared.feeds
        }
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .feed:
            return self.collectionView.dequeueManageableCell(using: self.config,
                                                             for: indexPath,
                                                             item: item as? Feed)
        }
    }
}
