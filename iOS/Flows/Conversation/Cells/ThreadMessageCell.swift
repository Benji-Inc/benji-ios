//
//  ThreadMessageCell.swift
//  Jibber
//
//  Created by Martin Young on 10/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

/// A cell to display a message within a thread along with the sender of the message..
class ThreadMessageCell: UICollectionViewCell {

    // Interaction handling
    var handleDeleteMessage: ((Messageable) -> Void)?
    private lazy var contextMenuInteraction = UIContextMenuInteraction(delegate: self)

    private let content = MessageContentView()

    /// The message to display.
    private var message: Messageable?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.content)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configures the cell to display the given messages.
    ///
    /// - Parameters:
    ///     - message: The root message to display.
    func set(message: Messageable) {
        self.message = message

        self.content.configure(with: message)

        self.content.configureBackground(color: message.context.color,
                                             showBubbleTail: false,
                                             tailOrientation: .left)
        self.setNeedsLayout()

        self.content.backgroundColorView.addInteraction(self.contextMenuInteraction)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {

            return
        }

        self.content.alpha = messageLayoutAttributes.alpha
        self.content.textView.isVisible = messageLayoutAttributes.shouldShowText
        self.content.configureBackground(color: messageLayoutAttributes.backgroundColor,
                                         showBubbleTail: messageLayoutAttributes.shouldShowTail,
                                         tailOrientation: messageLayoutAttributes.bubbleTailOrientation)
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension ThreadMessageCell: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { elements in
            return self.makeContextMenu()
        }
    }

    private func makeContextMenu() -> UIMenu {
        guard let message = self.message else { return UIMenu() }

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }

        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { [unowned self] action in
            self.handleDeleteMessage?(message)
        }

        let deleteMenu = UIMenu(title: "Delete",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])

        var menuElements: [UIMenuElement] = []
        if message.isFromCurrentUser {
            menuElements.append(deleteMenu)
        }

        return UIMenu(children: menuElements)
    }
}
