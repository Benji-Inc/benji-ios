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
        case channels
    }

    enum ItemType: Hashable {
        case notice(SystemNotice)
        case channel(DisplayableConversation)
    }

    var unclaimedCount: Int = 0
    var didSelectReservations: CompletionOptional = nil

    private let noticeConfig = ManageableCellRegistration<NoticeCell>().provider
    private let connectionConfig = ManageableCellRegistration<ConnectionRequestCell>().provider
    private let alertConfig = ManageableCellRegistration<AlertCell>().provider
    private let channelConfig = ManageableCellRegistration<ConversationCell>().provider
    private let footerConfig = ManageableFooterRegistration<ReservationsFooterView>().provider
    private let headerConfig = ManageableHeaderRegistration<UserHeaderView>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .notice(let notice):
            return self.getNoticeCell(with: collectionView, indexPath: indexPath, notice: notice)
        case .channel(let channel):
            return self.getConversationCell(with: collectionView, indexPath: indexPath, channel: channel)
        }
    }

    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {

        return self.getSupplementaryView(for: collectionView, section: section, kind: kind, indexPath: indexPath)
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

    private func getConversationCell(with collectionView: UICollectionView,
                                indexPath: IndexPath,
                                channel: DisplayableConversation) -> CollectionViewManagerCell? {
        
        return collectionView.dequeueConfiguredReusableCell(using: self.channelConfig,
                                                            for: indexPath,
                                                            item: channel)
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
            footer.configure(with: self.unclaimedCount)
            footer.button.didSelect { [unowned self] in
                self.didSelectReservations?()
            }
            return footer
        default:
            return nil
        }
    }
}
