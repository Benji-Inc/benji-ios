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
    private let connectionConfig = ManageableCellRegistration<ConnectionRequestCell>().provider
    private let alertConfig = ManageableCellRegistration<AlertCell>().provider

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

        self.collectionView.animationView.play()
        NoticeSupplier.shared.$notices.mainSink { _ in
            let cycle = AnimationCycle(inFromPosition: .inward, outToPosition: .inward, shouldConcatenate: true, scrollToEnd: false)
            self.loadSnapshot(animationCycle: cycle).mainSink { _ in
                // Begin auto scroll
                self.collectionView.animationView.stop()
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

        guard let type = NoticeSupplier.shared.notices[safe: indexPath.row]?.type else { return nil }

        switch type {
        case .alert:
            return self.collectionView.dequeueManageableCell(using: self.alertConfig,
                                                             for: indexPath,
                                                             item: item as? SystemNotice)
        case .connectionRequest:
            let cell = self.collectionView.dequeueManageableCell(using: self.connectionConfig,
                                                                 for: indexPath,
                                                                 item: item as? SystemNotice)
            cell?.content.didUpdateConnection = { [weak self] _ in
                // Do something??
            }
            return cell 
        default:
            return self.collectionView.dequeueManageableCell(using: self.noticeConfig,
                                                             for: indexPath,
                                                             item: item as? SystemNotice)
        }
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
