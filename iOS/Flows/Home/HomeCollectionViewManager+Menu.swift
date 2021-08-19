//
//  ChannelCollectionViewManager+Menu.swift
//  Ours
//
//  Created by Benji Dodgson on 1/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension HomeCollectionViewManager {

    func makeCurrentUserMenu(for channel: DisplayableChannel, at indexPath: IndexPath) -> UIMenu {

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }

        let confirm = UIAction(title: "Confirm",
                               image: UIImage(systemName: "trash"),
                               attributes: .destructive) { action in

            switch channel.channelType {
            case .system(_):
                break
            case .pending(_):
                break
            case .channel(let tchChannel):
                Task {
                    do {
                        try await ChannelSupplier.shared.delete(channel: tchChannel)
                    } catch {
                        logDebug(error)
                    }
                }
            }
        }

        let deleteMenu = UIMenu(title: "Delete",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirm, neverMind])

        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { _ in
            self.select(indexPath: indexPath)
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Options", children: [open, deleteMenu])
    }

    func makeNonCurrentUserMenu(for channel: DisplayableChannel, at indexPath: IndexPath) -> UIMenu {

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }

        let confirm = UIAction(title: "Confirm",
                               image: UIImage(systemName: "clear"),
                               attributes: .destructive) { action in

            switch channel.channelType {
            case .system(_):
                break 
            case .pending(_):
                break
            case .channel(let tchChannel):
                Task {
                    do {
                        try await ChannelSupplier.shared.delete(channel: tchChannel)
                    } catch {
                        logDebug(error)
                    }
                }
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
