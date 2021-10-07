//
//  ArchiveCollectionDataSource.swift
//  ArchiveCollectionDataSource
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ArchiveCollectionViewDataSource: CollectionViewDataSource<ArchiveCollectionViewDataSource.SectionType,
                                       ArchiveCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case notices
        case conversations
    }

    enum ItemType: Hashable {
        case notice(SystemNotice)
        case conversation(ChannelId)
    }

    private let conversationConfig = ManageableCellRegistration<ConversationCell>().provider

    #warning("Remove after beta")
    private let reservationConfig = ManageableCellRegistration<ReservationCell>().provider
    private let connectionConfig = ManageableCellRegistration<ConnectionRequestCell>().provider
    var didUpdateConnection: CompletionOptional = nil

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .conversation(let conversation):
            return collectionView.dequeueConfiguredReusableCell(using: self.conversationConfig,
                                                                for: indexPath,
                                                                item: conversation)
        case .notice(let notice):
            switch notice.type {
            case .connectionRequest:
                let cell = collectionView.dequeueConfiguredReusableCell(using: self.connectionConfig,
                                                                        for: indexPath,
                                                                        item: notice)
                cell.content.didUpdateConnection = { [unowned self] _ in
                    self.didUpdateConnection?()
                }
                return cell
            case .rsvps:
                return collectionView.dequeueConfiguredReusableCell(using: self.reservationConfig,
                                                                    for: indexPath,
                                                                    item: notice)
            default:
                return nil
            }
        }
    }
}
