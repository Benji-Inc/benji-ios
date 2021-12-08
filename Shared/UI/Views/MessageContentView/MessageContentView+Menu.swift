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
import UIKit

extension MessageContentView: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil) { () -> UIViewController? in
            guard let message = self.message else { return nil }
            return MessagePreviewViewController(with: message)
        } actionProvider: { (suggestions) -> UIMenu? in
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
            let item = MessageSequenceItem(channelID: cid, messageID: message.id)
            self.handleTappedMessage?(item)
        }

        let edit = UIAction(title: "Edit",
                            image: UIImage(systemName: "pencil.circle")) { [unowned self] action in
            let item = MessageSequenceItem(channelID: cid, messageID: message.id)
            self.handleEditMessage?(item)
        }

        let read = UIAction(title: "Set to read",
                            image: UIImage(systemName: "eyeglasses")) { [unowned self] action in
            self.setToRead()
        }

        let unread = UIAction(title: "Set to unread",
                            image: UIImage(systemName: "eyeglasses")) { [unowned self] action in
            self.setToUnread()
        }

        var menuElements: [UIMenuElement] = []

        if message.isFromCurrentUser {
            menuElements.append(deleteMenu)
        }

        if message.isFromCurrentUser {
            menuElements.append(edit)
        }

        if message.isConsumedByMe {
            menuElements.append(unread)
        } else if message.canBeConsumed {
            menuElements.append(read)
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

        if message.parentMessageId.isNil {
            menuElements.append(viewReplies)
        }

        return UIMenu.init(title: "This is a title", image: UIImage(named: "add_reaction"), identifier: nil, options: [], children: menuElements)
        //return UIMenu(children: menuElements)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let params = UIPreviewParameters()
        params.backgroundColor = Color.clear.color
        params.shadowPath = UIBezierPath.init(rect: .zero)
        if let bubble = interaction.view as? SpeechBubbleView, let path = bubble.bubbleLayer.path {
            params.visiblePath = UIBezierPath.init(cgPath: path)
        }
        let preview = UITargetedPreview(view: interaction.view!, parameters: params)
        return preview
    }
}
#endif
