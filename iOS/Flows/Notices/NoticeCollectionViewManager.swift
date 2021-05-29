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

    lazy var layout = UICollectionViewCompositionalLayout() { sectionIndex, layoutEnvironment in

        guard let sectionType = SectionType(rawValue: sectionIndex) else { return nil }

        switch sectionType {
        case .notices:
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

            return section
        }
    }

    override func initialize() {
        super.initialize()

    }

    override func getSections() -> [SectionType] {
        return SectionType.allCases
    }

    override func getItem(for indexPath: IndexPath) -> AnyHashable? {
        return nil
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        return self.collectionView.dequeueManageableCell(using: self.noticeConfig,
                                                         for: indexPath,
                                                         item: item as? Notice)
    }
}
