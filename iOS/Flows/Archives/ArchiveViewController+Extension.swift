//
//  ArchiveViewController+Menu.swift
//  ArchiveViewController+Menu
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ArchiveViewController: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        guard let content = interaction.view as? ConversationContentView,
                let conversation = content.currentItem  else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            return ConversationPreviewViewController(with: conversation, size: content.size)
        }, actionProvider: { suggestedActions in
            if conversation.isOwnedByMe {
                return self.makeCurrentUserMenu(for: conversation)
            } else {
                return self.makeNonCurrentUserMenu(for: conversation)
            }
        })
    }

    func makeCurrentUserMenu(for conversation: Conversation) -> UIMenu {
        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }

        let confirm = UIAction(title: "Confirm",
                               image: UIImage(systemName: "trash"),
                               attributes: .destructive) { action in

            Task {
                await self.delete(conversation: conversation)
            }
        }

        let deleteMenu = UIMenu(title: "Delete",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirm, neverMind])

        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [unowned self] _ in
            self.delegate?.archiveView(self, didSelect: .conversation(conversation.cid))
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Options", children: [open, deleteMenu])
    }

    func makeNonCurrentUserMenu(for conversation: Conversation) -> UIMenu {

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }

        let confirm = UIAction(title: "Confirm",
                               image: UIImage(systemName: "clear"),
                               attributes: .destructive) { action in
            Task {
                await self.delete(conversation: conversation)
            }
        }

        let deleteMenu = UIMenu(title: "Leave",
                                image: UIImage(systemName: "clear"),
                                options: .destructive,
                                children: [confirm, neverMind])

        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [unowned self] _ in
            self.delegate?.archiveView(self, didSelect: .conversation(conversation.cid))
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Options", children: [open, deleteMenu])
    }

    private func delete(conversation: Conversation) async {
        Task {
            do {
                try await ChatClient.shared.deleteChannel(conversation)
                await self.dataSource.deleteItems([.conversation(conversation.cid)])
            } catch {
                logDebug(error)
            }
        }
    }
}
