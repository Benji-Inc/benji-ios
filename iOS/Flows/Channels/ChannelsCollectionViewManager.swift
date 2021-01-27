//
//  ChannelsCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Combine

class ChannelsCollectionViewManager: CollectionViewManager<ChannelCell> {

    var didSelectReservation: ((Reservation) -> Void)? = nil
    var cancellables = Set<AnyCancellable>()

    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: collectionView.width, height: 84)
    }

    func loadAllChannels() {
        let cycle = AnimationCycle(inFromPosition: .down,
                                   outToPosition: .down,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        self.set(newItems: ChannelSupplier.shared.allChannelsSorted,
                 animationCycle: cycle,
                 completion: nil)
    }

    // MARK: Menu overrides

    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration? {

        guard let channel = self.getItem(for: indexPath.row),
            let cell = collectionView.cellForItem(at: indexPath) as? ChannelCell else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            return ChannelPreviewViewController(with: channel, size: cell.size)
        }, actionProvider: { suggestedActions in
            if channel.isFromCurrentUser {
                return self.makeCurrentUsertMenu(for: channel, at: indexPath)
            } else {
                return self.makeNonCurrentUserMenu(for: channel, at: indexPath)
            }
        })
    }
}
