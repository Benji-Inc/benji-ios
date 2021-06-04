//
//  ChannelCell.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

class MessageCell: BaseMessageCell {

    let imageView = LinkView()
    let bubbleView = MessageBubbleView()
    let textView = MessageTextView()

    override func initializeViews() {
        super.initializeViews()

        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.bubbleView)
        self.bubbleView.addSubview(self.textView)

        self.bubbleView.onTap { [unowned self] tap in
            
            guard let current = User.current(), let message = self.currentMessage, !message.isFromCurrentUser, message.canBeConsumed, !message.hasBeenConsumedBy.contains(current.objectId!) else {
                self.didTapMessage()
                return
            }

            let location = tap.location(in: self.bubbleView)
            self.bubbleView.startFillAnimation(at: location, for: message) { [unowned self] msg in
                self.didTapMessage()
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.bubbleView.layer.borderColor = nil
        self.bubbleView.layer.borderWidth = 0
        self.textView.text = nil
    }

    override func configure(with message: Messageable) {
        super.configure(with: message)

        if case MessageKind.text(let text) = message.kind {
            if let first = message.getDataTypes()?.first, first.resultType == .link {
                self.imageView.displayable = first
            } else {
                self.textView.set(text: text, messageContext: message.context)
            }
        }
    }

    override func handleIsConsumed(for message: Messageable) {
        guard message.getDataTypes().isNil else { return }

        self.bubbleView.set(backgroundColor: message.color)

        if !message.isFromCurrentUser, !message.isConsumed, message.context != .status {

            if !message.isFromCurrentUser, message.context == .casual {
                self.bubbleView.layer.borderColor = Color.purple.color.cgColor
            } else {
                self.bubbleView.layer.borderColor = message.context.color.color.cgColor
            }

            self.bubbleView.layer.borderWidth = 2
        }
    }

    override func layoutContent(with attributes: ChannelCollectionViewLayoutAttributes) {
        super.layoutContent(with: attributes)
        
        self.textView.frame = attributes.attributes.textViewFrame
        self.bubbleView.frame = attributes.attributes.bubbleViewFrame
        self.bubbleView.layer.maskedCorners = attributes.attributes.maskedCorners
        self.bubbleView.roundCorners()
        self.bubbleView.indexPath = attributes.indexPath
        self.imageView.frame = attributes.attributes.attachmentFrame
    }
}
