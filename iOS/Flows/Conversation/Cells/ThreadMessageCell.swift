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
    private let authorView = AvatarView()

    private var state: ConversationUIState = .read

    /// The message to display.
    private var message: Messageable?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.content)
        self.contentView.addSubview(self.authorView)

        // Don't clip to bounds so that the vertical lines can meet between cells.
        self.clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.authorView.setSize(for: MessageContentView.minimumHeight - Theme.contentOffset.half)
        self.authorView.pin(.left)

        let width = self.contentView.width - (self.authorView.width + Theme.contentOffset.half)
        self.content.match(.left, to: .right, of: self.authorView, offset: Theme.contentOffset.half)
        self.content.width = width
        if let message = self.message {
            self.content.height = MessageContentView.getHeight(withWidth: width, message: message)
        }

        self.content.centerOnY()

        self.authorView.centerY = self.content.centerY
    }

    /// Configures the cell to display the given messages.
    ///
    /// - Parameters:
    ///     - message: The root message to display.
    func set(message: Messageable) {
        self.message = message

        self.authorView.set(avatar: message.avatar)
        self.content.setText(with: message)

        self.content.configureBackground(color: message.context.color,
                                             showBubbleTail: true,
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
