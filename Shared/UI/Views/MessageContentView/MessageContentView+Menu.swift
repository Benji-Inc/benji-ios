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
                    logError(error)
                }
            }.add(to: self.taskPool)
        }

        let deleteMenu = UIMenu(title: "Delete Message",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])

        let viewReplies = UIAction(title: "View Replies") { [unowned self] action in
            self.handleTappedMessage?(cid, message.id)
        }

        let edit = UIAction(title: "Edit",
                            image: UIImage(systemName: "pencil.circle")) { [unowned self] action in
            self.handleEditMessage?(cid, message.id)
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

        if !isRelease, message.isFromCurrentUser {
            menuElements.append(deleteMenu)
        }

        if !isRelease, message.isFromCurrentUser {
            menuElements.append(edit)
        }

        if message.isConsumedByMe {
            menuElements.append(unread)
        } else if message.canBeConsumed {
            menuElements.append(read)
        }

        if message.parentMessageId.isNil {
            menuElements.append(viewReplies)
        }

        return UIMenu.init(title: "From: \(message.avatar.fullName)",
                           image: nil,
                           identifier: nil,
                           options: [],
                           children: menuElements)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let params = UIPreviewParameters()
        params.backgroundColor = ThemeColor.clear.color
        params.shadowPath = UIBezierPath.init(rect: .zero)
        if let bubble = interaction.view as? SpeechBubbleView, let path = bubble.bubbleLayer.path {
            params.visiblePath = UIBezierPath.init(cgPath: path)
        }
        let preview = UITargetedPreview(view: interaction.view!, parameters: params)
        return preview
    }
}
#endif
