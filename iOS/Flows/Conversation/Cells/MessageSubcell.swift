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

    static let bubbleTailLength: CGFloat = 7

    /// A rounded and colored background view for the message. Changes color based on the sender.
    let backgroundColorView = SpeechBubbleView(orientation: .down)
    /// Text view for displaying the text of the message.
    let textView = MessageTextView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.intitializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.intitializeViews()
    }

    private func intitializeViews() {
        self.contentView.addSubview(self.backgroundColorView)
        self.backgroundColorView.roundCorners()

        self.backgroundColorView.addSubview(self.textView)
        self.textView.textAlignment = .center
        self.textView.textColor = Color.textColor.color
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundColorView.width = self.width
        self.backgroundColorView.expandToSuperviewHeight()
        self.backgroundColorView.centerOnXAndY()

        self.textView.width = self.backgroundColorView.width
        self.textView.sizeToFit()
        self.textView.center = self.backgroundColorView.bubbleFrame.center
    }

    func setText(with message: Messageable) {
        if message.isDeleted {
            self.textView.text = "DELETED"
        } else {
            self.textView.text = message.kind.text
        }

        self.setNeedsLayout()
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {

            return
        }

        self.textView.isVisible = messageLayoutAttributes.shouldShowText
        self.configureBackground(color: messageLayoutAttributes.backgroundColor,
                                 showBubbleTail: messageLayoutAttributes.shouldShowTail,
                                 tailOrientation: messageLayoutAttributes.bubbleTailOrientation)
    }

    /// Sets the background color and shows/hides the bubble tail.
    func configureBackground(color: UIColor,
                             showBubbleTail: Bool,
                             tailOrientation: SpeechBubbleView.TailOrientation) {

        self.backgroundColorView.bubbleColor = color
        self.backgroundColorView.tailLength = showBubbleTail ? MessageSubcell.bubbleTailLength : 0
        self.backgroundColorView.orientation = tailOrientation
    }
}

extension MessageSubcell {

    /// Returns the height that a message subcell should be given a width and message to display.
    static func getHeight(withWidth width: CGFloat, message: Messageable) -> CGFloat {
        let textView = MessageTextView()
        textView.text = message.kind.text
        var textViewSize = textView.getSize(withWidth: width)
        textViewSize.height += Theme.contentOffset.doubled
        return textViewSize.height + self.bubbleTailLength
    }
}
