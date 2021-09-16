//
//  HomeCollectionViewDataSource.swift
//  HomeCollectionViewDataSource
//
//  Created by Martin Young on 8/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class HomeCollectionViewDataSource: CollectionViewDataSource<HomeCollectionViewDataSource.SectionType,
                                    HomeCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case notices
    }

    enum ItemType: Hashable {
        case notice(SystemNotice)
    }

    private let noticeConfig = ManageableCellRegistration<NoticeCell>().provider
    private let connectionConfig = ManageableCellRegistration<ConnectionRequestCell>().provider
    private let alertConfig = ManageableCellRegistration<AlertCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .notice(let notice):
            return self.getNoticeCell(with: collectionView, indexPath: indexPath, notice: notice)
        }
    }

    private func getNoticeCell(with collectionView: UICollectionView,
                               indexPath: IndexPath,
                               notice: SystemNotice) -> CollectionViewManagerCell? {

        guard let type = NoticeSupplier.shared.notices[safe: indexPath.row]?.type else { return nil }

        switch type {
        case .alert:
            return collectionView.dequeueConfiguredReusableCell(using: self.alertConfig,
                                                                for: indexPath,
                                                                item: notice)
        case .connectionRequest:
            return collectionView.dequeueConfiguredReusableCell(using: self.connectionConfig,
                                                                for: indexPath,
                                                                item: notice)
        default:
            return collectionView.dequeueConfiguredReusableCell(using: self.noticeConfig,
                                                                for: indexPath,
                                                                item: notice)
        }
    }
}
