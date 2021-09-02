//
//  ConversationCollectionViewManager+Menu.swift
//  Benji
//
//  Created by Benji Dodgson on 11/16/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import TwilioChatClient
import SafariServices

extension ConversationCollectionViewManager: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexView = interaction.view as? Indexable,
            let indexPath = indexView.indexPath,
            let message = self.item(at: indexPath) else { return nil }

        return UIContextMenuConfiguration(identifier: nil) {
            if case MessageKind.link(let url) = message.kind {
                return SFSafariViewController(url: url)
            }
            return nil
        } actionProvider: { suggested in
            return self.makeContextMenu(for: message, at: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    private func makeContextMenu(for message: Messageable, at indexPath: IndexPath) -> UIMenu {

        // Create a UIAction for sharing
        let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { action in
            self.didTapShare?(message)
        }

        let editMessage = UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")) { action in
            self.didTapEdit?(message, indexPath)
        }

        let resend = UIAction(title: "Resend", image: UIImage(systemName: "arrow.2.circlepath")) { action in
            self.didTapResend?(message)
        }

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in}

        let confirm = UIAction(title: "Confirm", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
            self.delete(item: message, in: indexPath.section)
            MessageSupplier.shared.delete(message: message)
        }

        let deleteMenu = UIMenu(title: "Delete", image: UIImage(systemName: "trash"), options: .destructive, children: [confirm, neverMind])

        let readOk = UIAction(title: "Ok", image: UIImage(systemName: "hand.thumbsup")) { action in
            self.setToRead(message: message)
        }

        let readCancel = UIAction(title: "Never mind", image: UIImage(systemName: "nosign")) { action in
        }

        let open = UIAction(title: "Open", image: UIImage(systemName: "cursorarrow")) { action in
            if case MessageKind.link(let url) = message.kind {
                UIApplication.shared.open(url)
            }
        }

        let readMenu = UIMenu(title: "Set messages to read", image: UIImage(systemName: "eyeglasses"), children: [readCancel, readOk])

        if message.isFromCurrentUser {
            if message.status == .error {
                return UIMenu(title: "There was an error sending this message.", children: [resend])
            } else {
                var children = [deleteMenu, share]
                if case MessageKind.link(_) = message.kind {
                    children.append(open)
                } else {
                    children.append(editMessage)
                }
                return UIMenu(title: "", children: children)
            }
        }

        var children = [share, readMenu]
        if case MessageKind.link(_) = message.kind {
            children.append(open)
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "", children: children)
    }

    private func setToRead(message: Messageable) {
        guard let current = User.current() else { return }
        Task {
            do {
                try await message.updateConsumers(with: current)
            } catch {
                logDebug(error)
            }
        }
    }
}
