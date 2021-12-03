//
//  MessageSubcell.swift
//  Jibber
//
//  Created by Martin Young on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A cell for displaying individual messages, author and reactions.
class MessageSubcell: UICollectionViewCell {

    let content = MessageContentView()
    let detailView = MessageDetailView()

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
        self.contentView.addSubview(self.detailView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.detailView.expandToSuperviewWidth()
        self.content.expandToSuperviewWidth()

        self.content.height = self.bounds.height - (self.detailView.height - (self.content.bubbleView.tailLength - Theme.ContentOffset.short.value))

        if self.content.bubbleView.orientation == .down {
            self.content.pin(.top)
            self.detailView.pin(.bottom)
        } else if self.content.bubbleView.orientation == .up {
            self.detailView.pin(.top)
            self.content.pin(.bottom)
        }
    }

    func configure(with message: Messageable, showAuthor: Bool) {
        self.content.configure(with: message)
        self.content.state = showAuthor ? .expanded : .collapsed
        self.detailView.configure(with: message)
        self.layoutNow()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {
            return
        }

        self.content.textView.isVisible = messageLayoutAttributes.shouldShowText
        self.content.configureBackground(color: messageLayoutAttributes.backgroundColor,
                                         brightness: messageLayoutAttributes.brightness,
                                         showBubbleTail: messageLayoutAttributes.shouldShowTail,
                                         tailOrientation: messageLayoutAttributes.bubbleTailOrientation)

        self.detailView.height = MessageDetailView.height
        self.detailView.alpha = messageLayoutAttributes.detailAlpha

        self.detailView.updateReadStatus(shouldRead: messageLayoutAttributes.detailAlpha == 1.0)
    }
}
