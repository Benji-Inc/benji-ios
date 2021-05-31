//
//  NoticeCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 5/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticeCollectionViewManager: CollectionViewManager<NoticeCollectionViewManager.SectionType> {

    enum SectionType: Int, ManagerSectionType, CaseIterable {
        case notices
    }

    private let noticeConfig = ManageableCellRegistration<NoticeCell>().provider

    @Published var centerIndexPath: IndexPath? = nil

    lazy var layout: UICollectionViewCompositionalLayout = {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal

        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, enviroment in
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

            // Section
            let section = NSCollectionLayoutSection(group: group)
            return section

        }, configuration: config)
    }()

    override func initialize() {
        super.initialize()

        self.collectionView.collectionViewLayout = self.layout

        NoticeSupplier.shared.$notices.mainSink { _ in
            self.loadSnapshot().mainSink { _ in
                // Begin auto scroll
            }.store(in: &self.cancellables)
        }.store(in: &self.cancellables)
    }

    override func getSections() -> [SectionType] {
        return SectionType.allCases
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        return NoticeSupplier.shared.notices
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {

        return self.collectionView.dequeueManageableCell(using: self.noticeConfig,
                                                         for: indexPath,
                                                         item: item as? SystemNotice)

    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        super.scrollViewDidEndDecelerating(scrollView)
        self.centerIndexPath = self.collectionView.centerMostIndexPath()
    }

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        super.scrollViewDidEndScrollingAnimation(scrollView)
        self.centerIndexPath = self.collectionView.centerMostIndexPath()
    }
}
