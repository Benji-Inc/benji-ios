//
//  MessageDeliveryTypeMenuDelegate.swift
//  Jibber
//
//  Created by Martin Young on 3/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MessageContentContextMenuDelegate: NSObject, UIContextMenuInteractionDelegate {

    unowned let content: MessageContentView

    init(content: MessageContentView) {
        self.content = content
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil) { [unowned self] () -> UIViewController? in
            guard let message = self.content.message else { return nil }
            return MessagePreviewViewController(with: message)
        } actionProvider: { [unowned self] (suggestions) -> UIMenu? in
            return self.makeContextMenu()
        }
    }

    private func makeContextMenu() -> UIMenu {
        guard let message = self.content.message as? Message, let cid = message.cid else {
            return UIMenu()
        }

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }

        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { action in
            Task {
                let controller = ChatClient.shared.messageController(cid: cid, messageId: message.id)
                do {
                    try await controller.deleteMessage()
                } catch {
                    await ToastScheduler.shared.schedule(toastType: .error(error))
                }
            }
        }

        let deleteMenu = UIMenu(title: "Delete Message",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])

        let viewReplies = UIAction(title: "View Replies") { [unowned self] action in
            self.content.delegate?.messageContent(self.content, didTapViewReplies: (cid, message.id))
        }

        let edit = UIAction(title: "Edit",
                            image: UIImage(systemName: "pencil.circle")) { [unowned self] action in
            self.content.delegate?.messageContent(self.content, didTapEditMessage: (cid, message.id))
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

        return UIMenu.init(title: "From: \(message.author.parseUser?.fullName ?? "Unkown")",
                           image: nil,
                           identifier: nil,
                           options: [],
                           children: menuElements)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {

        let params = UIPreviewParameters()
        params.backgroundColor = ThemeColor.clear.color
        params.shadowPath = UIBezierPath(rect: .zero)
        if let bubble = interaction.view as? SpeechBubbleView, let path = bubble.bubbleLayer.path {
            params.visiblePath = UIBezierPath(cgPath: path)
        }
        let preview = UITargetedPreview(view: interaction.view!, parameters: params)
        return preview
    }

    // MARK: - Message Consumption

    func setToRead() {
        guard let msg = self.content.message, msg.canBeConsumed else { return }
        Task {
            await msg.setToConsumed()
        }
    }

    func setToUnread() {
        guard let msg = self.content.message, msg.isConsumedByMe else { return }
        Task {
            try await msg.setToUnconsumed()
        }
    }
}
