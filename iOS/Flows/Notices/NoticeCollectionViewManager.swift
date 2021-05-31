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

    var colors: [Color] = [.red, .lightPurple, .purple, .green, .orange]

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

    var notices: [SystemNotice] = []

    override func initialize() {
        super.initialize()

        self.collectionView.collectionViewLayout = self.layout

        for _ in 0...self.colors.count - 1 {
            let notice = SystemNotice(createdAt: Date(), notice: nil, type: .system, attributes: [:])
            self.notices.append(notice)
        }

        self.loadSnapshot()
    }

    override func getSections() -> [SectionType] {
        return SectionType.allCases
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        return self.notices
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        let cell = self.collectionView.dequeueManageableCell(using: self.noticeConfig,
                                                             for: indexPath,
                                                             item: item as? SystemNotice)
        guard let color = self.colors[safe: indexPath.row] else { return nil }
        cell?.contentView.set(backgroundColor: color)
        return cell
    }
}
