//
//  MessageContentView+Menu.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/28/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

#if IOS
import StreamChat

extension MessageContentView: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { elements in
            return self.makeContextMenu()
        }
    }

    private func makeContextMenu() -> UIMenu {
        guard let message = self.message as? Message, let cid = message.cid else { return UIMenu() }

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }

        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { [unowned self] action in
            Task {
                let controller = ChatClient.shared.messageController(cid: cid, messageId: message.id)
                do {
                    try await controller.deleteMessage()
                } catch {
                    logDebug(error)
                }
            }.add(to: self.taskPool)
        }

        let deleteMenu = UIMenu(title: "Delete Message",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])

        let viewReplies = UIAction(title: "View Replies") { [unowned self] action in
            let item = ConversationMessageItem(channelID: cid, messageID: message.id)
            self.handleTappedMessage?(item)
        }

        let edit = UIAction(title: "Edit",
                            image: UIImage(systemName: "pencil.circle")) { [unowned self] action in
            let item = ConversationMessageItem(channelID: cid, messageID: message.id)
            self.handleEditMessage?(item)
        }

        let read = UIAction(title: "Read",
                            image: UIImage(systemName: "eyeglasses")) { [unowned self] action in
            self.setToRead()
        }

        var menuElements: [UIMenuElement] = []

        if message.isFromCurrentUser {
            menuElements.append(deleteMenu)
        }

        if message.isFromCurrentUser {
            menuElements.append(edit)
        }

        if message.parentMessageId.isNil {
            menuElements.append(viewReplies)
        }

        let children: [UIAction] = ReactionType.allCases.filter({ type in
            return type != .read 
        }).compactMap { type in
            return UIAction.init(title: type.emoji,
                                 subtitle: nil,
                                 image: nil,
                                 identifier: nil,
                                 discoverabilityTitle: nil,
                                 attributes: []) { [unowned self] _ in
                Task {
                    let controller = ChatClient.shared.messageController(cid: cid, messageId: message.id)
                    do {
                        try await controller.addReaction(with: type)
                    } catch {
                        logDebug(error)
                    }
                }.add(to: self.taskPool)
            }
        }

        let reactionsMenu = UIMenu(title: "Add Reaction",
                                image: UIImage(systemName: "face.smile"),
                                children: children)

        menuElements.append(reactionsMenu)

        return UIMenu(children: menuElements)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let params = UIPreviewParameters()
        params.backgroundColor = Color.clear.color
        let preview = UITargetedPreview(view: interaction.view!, parameters: params)
        return preview
    }
}
#endif
