//
//  MessageContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
#if IOS
import SwiftUI
import StreamChat
#endif

class MessageContentView: BaseView {

#if IOS
    var handleTappedMessage: ((ConversationId, MessageId) -> Void)?
    var handleEditMessage: ((ConversationId, MessageId) -> Void)?
#endif

    // Sizing
    static let bubbleHeight: CGFloat = 148
    static var standardHeight: CGFloat { return MessageContentView.bubbleHeight - MessageContentView.textViewPadding }
    static let padding = Theme.ContentOffset.long
    static var textViewPadding: CGFloat { return MessageContentView.padding.value * 2 }

    static let bubbleTailLength: CGFloat = 12

    /// A speech bubble background view for the message.
    let bubbleView = MessageBubbleView(orientation: .down)
    /// Text view for displaying the text of the message.
    let textView = MessageTextView(font: .regular, textColor: .T1)
    let imageView = DisplayableImageView()
    private (set) var message: Messageable?

    let authorView = PersonView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.bubbleView.addSubview(self.authorView)

        self.addSubview(self.bubbleView)
        self.bubbleView.roundCorners()

        self.bubbleView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill

        self.bubbleView.addSubview(self.textView)
        self.textView.textContainer.lineBreakMode = .byTruncatingTail
        self.textView.textAlignment = .left

#if IOS
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        self.bubbleView.addInteraction(contextMenuInteraction)
#endif
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.bubbleView.expandToSuperviewSize()

        self.authorView.size = self.getAuthorSize()
        self.authorView.pin(.top, offset: MessageContentView.padding)
        self.authorView.pin(.left, offset: MessageContentView.padding)

        self.imageView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
        self.imageView.pin(.top, offset: MessageContentView.padding)
        self.imageView.width = 100
        self.imageView.height = self.height - MessageContentView.padding.value.doubled

        if imageView.displayable.exists {
            self.textView.match(.left, to: .right, of: self.imageView, offset: MessageContentView.padding)
        } else {
            self.textView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
        }
        self.textView.pin(.top, offset: MessageContentView.padding)
        self.textView.expand(.right, to: self.width - MessageContentView.padding.value)
        self.textView.expand(.bottom, to: self.height - MessageContentView.padding.value)
    }

    func configure(with message: Messageable) {
        self.message = message

        if message.isDeleted {
            self.textView.text = "DELETED"
        } else {
            self.textView.setText(with: message)

            self.imageView.displayable = nil
            switch message.kind {
            case .photo(photo: let photo, _):
                guard let url = photo.url else { break }
                self.imageView.displayable = url
            case .text, .attributedText, .video, .location, .emoji, .audio, .contact, .link:
                break
            }
        }

#if IOS
        self.configureConsumption(for: message)
#endif
        self.authorView.set(person: message.person)

        self.setNeedsLayout()
    }

    private var loadImageTask: Task<Void, Never>?

  

    /// Sets the background color and shows/hides the bubble tail.
    func configureBackground(color: UIColor,
                             textColor: UIColor,
                             brightness: CGFloat,
                             showBubbleTail: Bool,
                             tailOrientation: SpeechBubbleView.TailOrientation) {

        self.textView.textColor = textColor
        self.textView.linkTextAttributes = [.foregroundColor: textColor.withAlphaComponent(0.5), .underlineStyle: 0]

        self.bubbleView.setBubbleColor(color.withAlphaComponent(brightness), animated: false)
        self.bubbleView.tailLength = showBubbleTail ? MessageContentView.bubbleTailLength : 0
        self.bubbleView.orientation = tailOrientation

        // NOTE: Changes to the gradient layer need to be applied immediately without animation.
        // https://stackoverflow.com/questions/5833488/how-to-disable-calayer-implicit-animations
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        self.bubbleView.lightGradientLayer.opacity = 0
        self.bubbleView.darkGradientLayer.opacity = 0.2 * Float(1 - brightness)

        CATransaction.commit()
    }

    func getAuthorSize() -> CGSize {
        let authorHeight: CGFloat = MessageContentView.standardHeight * 0.33
        return self.authorView.getSize(for: authorHeight)
    }

    func getSize(with width: CGFloat) -> CGSize {
        var size = self.textView.getSize(width: width)
        size.width += MessageContentView.textViewPadding
        size.height += self.bubbleView.tailLength + MessageContentView.textViewPadding
        return size
    }
}

// MARK: - Message Consumption

#if IOS
extension MessageContentView {

    func configureConsumption(for message: Messageable) {
        if message.isConsumedByMe {
            self.textView.setFont(.regular)
        } else {
            self.textView.setFont(.regular)
        }
    }

    func setToRead() {
        guard let msg = self.message, msg.canBeConsumed else { return }
        Task {
            try await self.message?.setToConsumed()
        }
    }

    func setToUnread() {
        guard let msg = self.message, msg.isConsumedByMe else { return }
        Task {
            try await self.message?.setToUnconsumed()
        }
    }
}
#endif

extension MessageTextView {

    func getSize(width: CGFloat) -> CGSize {
        let maxTextWidth: CGFloat
        let maxTextHeight: CGFloat = MessageContentView.standardHeight

        let size = MessageContentView().getAuthorSize()
        maxTextWidth = width - (size.width + (MessageContentView.textViewPadding + MessageContentView.textViewPadding.half))

        return self.getSize(withMaxWidth: maxTextWidth, maxHeight: maxTextHeight)
    }
}

