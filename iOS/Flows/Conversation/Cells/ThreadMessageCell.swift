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

    private let messageView = MessageSubcell(frame: .zero)
    private let authorView = AvatarView()
    private let topVerticalLine = View()
    private let bottomVerticalLine = View()
    private let dotView = View()

    private var state: ConversationUIState = .read

    /// The message to display.
    private var message: Messageable?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.messageView)

        self.topVerticalLine.set(backgroundColor: .lightGray)
        self.contentView.addSubview(self.topVerticalLine)
        self.bottomVerticalLine.set(backgroundColor: .lightGray)
        self.contentView.addSubview(self.bottomVerticalLine)

        self.contentView.addSubview(self.dotView)
        self.dotView.set(backgroundColor: .lightGray)

        self.contentView.addSubview(self.authorView)

        self.dotView.set(backgroundColor: .white)

        self.contentView.addSubview(self.authorView)

        // Don't clip to bounds so that the vertical lines can meet between cells.
        self.clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let shouldShowAvatar = self.authorView.displayable.exists

        if shouldShowAvatar {
            self.messageView.left = 40
        } else {
            self.messageView.left = 0
        }
        self.messageView.expand(.right)
        self.messageView.expandToSuperviewHeight()

        if shouldShowAvatar {
            self.authorView.setSize(for: 40)
            self.authorView.pin(.left)
            self.authorView.centerY = self.messageView.halfHeight

            let lineOffset: CGFloat = 10

            self.topVerticalLine.height = self.contentView.halfHeight + lineOffset
            self.topVerticalLine.width = 2
            self.topVerticalLine.top = -lineOffset
            self.topVerticalLine.centerX = self.authorView.centerX

            self.bottomVerticalLine.height = self.contentView.halfHeight + lineOffset
            self.bottomVerticalLine.width = 2
            self.bottomVerticalLine.centerX = self.authorView.centerX
            self.bottomVerticalLine.pin(.bottom, padding: -lineOffset)

            self.dotView.size = CGSize(width: 6, height: 6)
            self.dotView.layer.cornerRadius = 3
            self.dotView.center = self.authorView.center
        } else {
            self.authorView.frame = .zero
            self.topVerticalLine.frame = .zero
            self.bottomVerticalLine.frame = .zero
        }
    }

    /// Configures the cell to display the given messages.
    ///
    /// - Parameters:
    ///     - message: The root message to display, which may have replies.
    ///     - replies: The currently loaded replies to the message. These should be ordered by newest to oldest.
    ///     - totalReplyCount: The total number of replies that this message has. It may be more than the passed in replies.
    func set(message: Messageable, replies: [Messageable], totalReplyCount: Int) {
        self.message = message

        self.authorView.set(avatar: message.avatar)
        self.messageView.setText(with: message)

        let backgroundColor: UIColor
        if message.isFromCurrentUser {
            backgroundColor = .gray
        } else {
            backgroundColor = .darkGray
        }
        self.messageView.configureBackground(color: backgroundColor,
                                             showBubbleTail: false,
                                             tailOrientation: .down)

        self.setNeedsLayout()

        if message.isFromCurrentUser {
            self.messageView.backgroundColorView.addInteraction(self.contextMenuInteraction)
        }
    }

    func setAuthor(with avatar: Avatar, showTopLine: Bool, showBottomLine: Bool) {
        self.authorView.set(avatar: avatar)
        self.authorView.isVisible = !showTopLine

        self.topVerticalLine.isVisible = showTopLine
        self.bottomVerticalLine.isVisible = showBottomLine

        self.dotView.isVisible = showTopLine && !showBottomLine

        self.setNeedsLayout()
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
