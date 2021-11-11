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
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.contentView.addSubview(self.backgroundColorView)
        self.backgroundColorView.roundCorners()

        self.backgroundColorView.addSubview(self.textView)

        self.textView.textContainer.lineBreakMode = .byTruncatingTail
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundColorView.expandToSuperviewSize()

        self.textView.width = self.backgroundColorView.bubbleFrame.width
        self.textView.centerOnX()
        self.textView.top = self.backgroundColorView.bubbleFrame.top + Theme.contentOffset.half
        self.textView.expand(.bottom,
                             to: self.backgroundColorView.bubbleFrame.bottom - Theme.contentOffset.half)
    }

    func setText(with message: Messageable) {
        if message.isDeleted {
            self.textView.text = "DELETED"
        } else {
            self.textView.set(text: message.kind.text, messageContext: message.context)
        }

        self.setNeedsLayout()
    }

    /// Adds a context menu interaction to this cell, using the provided delegate object.
    /// If no delegate is provided, no interaction will be added. Previously added interactions are always removed.
    func setContextMenuInteraction(with contextMenuDelegate: UIContextMenuInteractionDelegate?) {
        self.backgroundColorView.interactions.removeAll()

        if let contextMenuDelegate = contextMenuDelegate {
            let contextMenuInteraction = UIContextMenuInteraction(delegate: contextMenuDelegate)
            self.backgroundColorView.addInteraction(contextMenuInteraction)
        }
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {

            return
        }

        self.textView.alpha = messageLayoutAttributes.shouldShowText ? 1 : 0.5
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

    static var minimumHeight: CGFloat { return 50 }
    static var maximumHeight: CGFloat { return 100 }

    /// Returns the height that a message subcell should be given a width and message to display.
    static func getHeight(withWidth width: CGFloat, message: Messageable) -> CGFloat {

        // If the message is deleted, we're not going to display its content.
        // Return the minimum height so we have enough to show the deleted status.
        if message.isDeleted {
            return MessageSubcell.minimumHeight
        }

        let textView = MessageTextView()
        textView.text = message.kind.text
        var textViewSize = textView.getSize(withWidth: width)
        textViewSize.height += Theme.contentOffset
        return clamp(textViewSize.height + self.bubbleTailLength,
                     MessageSubcell.minimumHeight,
                     MessageSubcell.maximumHeight)
    }
}
