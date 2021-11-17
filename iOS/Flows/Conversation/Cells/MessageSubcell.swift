//
//  MessageSubcell.swift
//  Jibber
//
//  Created by Martin Young on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A cell for displaying individual messages  and replies within a MessageCell or ThreadedMessageCell.
class MessageSubcell: UICollectionViewCell {

    let content = MessageContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.contentView.addSubview(self.content)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
    }

    func setText(with message: Messageable) {
        self.content.setText(with: message)
        self.setNeedsLayout()
    }

    /// Adds a context menu interaction to this cell, using the provided delegate object.
    /// If no delegate is provided, no interaction will be added. Previously added interactions are always removed.
    func setContextMenuInteraction(with contextMenuDelegate: UIContextMenuInteractionDelegate?) {
        self.content.backgroundColorView.interactions.removeAll()

        if let contextMenuDelegate = contextMenuDelegate {
            let contextMenuInteraction = UIContextMenuInteraction(delegate: contextMenuDelegate)
            self.content.backgroundColorView.addInteraction(contextMenuInteraction)
        }
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {

            return
        }

        self.content.textView.isVisible = messageLayoutAttributes.shouldShowText
        self.content.configureBackground(color: messageLayoutAttributes.backgroundColor,
                                         showBubbleTail: messageLayoutAttributes.shouldShowTail,
                                         tailOrientation: messageLayoutAttributes.bubbleTailOrientation)
    }
}
