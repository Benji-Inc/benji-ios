//
//  HomeCollectionViewDataSourceCreator.swift
//  HomeCollectionViewDataSourceCreator
//
//  Created by Martin Young on 8/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct HomeCollectionViewDataSourceCreator: CollectionViewDataSourceCreator {

    typealias SectionType = HomeCollectionViewManager.SectionType
    typealias ItemIdentifier = AnyHashable

    private let noticeConfig = ManageableCellRegistration<NoticeCell>().provider
    private let connectionConfig = ManageableCellRegistration<ConnectionRequestCell>().provider
    private let alertConfig = ManageableCellRegistration<AlertCell>().provider
    private let channelConfig = ManageableCellRegistration<ChannelCell>().provider
    private let footerConfig = ManageableFooterRegistration<ReservationsFooterView>().provider
    private let headerConfig = ManageableHeaderRegistration<UserHeaderView>().provider

    // MARK: - CollectionViewDataSourceCreator Functions

    func dequeueCell(with collectionView: UICollectionView,
                     indexPath: IndexPath,
                     identifier: AnyHashable) -> UICollectionViewCell? {

        guard let section = HomeCollectionViewManager.SectionType(rawValue: indexPath.section) else {
            return nil
        }

        switch section {
        case .notices:
            return self.getNoticeCell(with: collectionView, indexPath: indexPath, identifier: identifier)
        case .channels:
            return self.getUserCell(with: collectionView, indexPath: indexPath, identifier: identifier)
        }
    }

    func dequeueSupplementaryView(with collectionView: UICollectionView,
                                  kind: String,
                                  indexPath: IndexPath) -> UICollectionReusableView? {

        guard let section = HomeCollectionViewManager.SectionType(rawValue: indexPath.section) else {
            return nil
        }

        return self.getSupplementaryView(for: collectionView, section: section, kind: kind, indexPath: indexPath)
    }

    // MARK: - Cell Dequeueing

    private func getNoticeCell(with collectionView: UICollectionView,
                               indexPath: IndexPath,
                               identifier: AnyHashable) -> CollectionViewManagerCell? {

        guard let type = NoticeSupplier.shared.notices[safe: indexPath.row]?.type else { return nil }

        switch type {
        case .alert:
            return collectionView.dequeueConfiguredReusableCell(using: self.alertConfig,
                                                                for: indexPath,
                                                                item: identifier as? SystemNotice)
        case .connectionRequest:
            return collectionView.dequeueConfiguredReusableCell(using: self.connectionConfig,
                                                                for: indexPath,
                                                                item: identifier as? SystemNotice)
        default:
            return collectionView.dequeueConfiguredReusableCell(using: self.noticeConfig,
                                                                for: indexPath,
                                                                item: identifier as? SystemNotice)
        }
    }

    private func getUserCell(with collectionView: UICollectionView,
                             indexPath: IndexPath,
                             identifier: AnyHashable?) -> CollectionViewManagerCell? {

        return collectionView.dequeueConfiguredReusableCell(using: self.channelConfig,
                                                            for: indexPath,
                                                            item: identifier as? DisplayableChannel)
    }

    private func getSupplementaryView(for collectionView: UICollectionView,
                                       section: SectionType,
                                       kind: String,
                                       indexPath: IndexPath) -> UICollectionReusableView? {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard section == .notices else { return nil }
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            return header
        case UICollectionView.elementKindSectionFooter:
            guard section == .channels else { return nil }

            let footer = collectionView.dequeueConfiguredReusableSupplementary(using: self.footerConfig, for: indexPath)
//            footer.configure(with: self.unclaimedCount)
            footer.button.didSelect {
//                self.didSelectReservations?()
            }
            return footer
        default:
            return nil
        }
    }
}
