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
    private var cancellables = Set<AnyCancellable>()

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

    private func makeCurrentUsertMenu(for channel: DisplayableChannel, at indexPath: IndexPath) -> UIMenu {

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }

        let confirm = UIAction(title: "Confirm", image: UIImage(systemName: "trash"), attributes: .destructive) { action in

            switch channel.channelType {
            case .system(_):
                self.delete(item: channel)
            case .pending(_):
                break 
            case .channel(let tchChannel):
                ChannelSupplier.delete(channel: tchChannel)
                    .mainSink().store(in: &self.cancellables)
            }
        }

        let deleteMenu = UIMenu(title: "Delete", image: UIImage(systemName: "trash"), options: .destructive, children: [confirm, neverMind])

        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { _ in
            self.select(indexPath: indexPath)
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Options", children: [open, deleteMenu])
    }

    private func makeNonCurrentUserMenu(for channel: DisplayableChannel, at indexPath: IndexPath) -> UIMenu {

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }

        let confirm = UIAction(title: "Confirm", image: UIImage(systemName: "clear"), attributes: .destructive) { action in

            switch channel.channelType {
            case .system(_):
                self.delete(item: channel)
            case .pending(_):
                break 
            case .channel(let tchChannel):
                ChannelSupplier.leave(channel: tchChannel)
                    .mainSink().store(in: &self.cancellables)
            }
        }

        let deleteMenu = UIMenu(title: "Leave", image: UIImage(systemName: "clear"), options: .destructive, children: [confirm, neverMind])

        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { _ in
            self.select(indexPath: indexPath)
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Options", children: [open, deleteMenu])
    }
}
