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

    func configure(with message: Messageable) {
        self.content.configure(with: message)
        self.setNeedsLayout()
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
    }
}
