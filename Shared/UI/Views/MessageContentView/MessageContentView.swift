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

    /// Sizing

    static let bubbleHeight: CGFloat = 68
    static var standardHeight: CGFloat { return MessageContentView.bubbleHeight - MessageContentView.textViewPadding }
    static let padding = Theme.ContentOffset.long
    static var textViewPadding: CGFloat { return MessageContentView.padding.value * 2 }

    static let bubbleTailLength: CGFloat = 12

    /// A speech bubble background view for the message.
    let bubbleView = MessageBubbleView(orientation: .down)
    /// Text view for displaying the text of the message.
    let textView = MessageTextView(font: .regular, textColor: .T1)
    private (set) var message: Messageable?

    let authorView = AvatarView()

    private var cancellables = Set<AnyCancellable>()
    var publisherCancellables = Set<AnyCancellable>()

    enum State {
        case thread
        case expanded
        case collapsed
    }

    @Published var state: State = .collapsed

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }

        self.publisherCancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.bubbleView)
        self.bubbleView.roundCorners()

        self.bubbleView.addSubview(self.textView)
        self.textView.textContainer.lineBreakMode = .byTruncatingTail

        self.bubbleView.addSubview(self.authorView)
        self.authorView.isVisible = false

        self.$state.mainSink { [unowned self] state in
            self.authorView.isVisible = state == .thread
            self.layoutNow()
        }.store(in: &self.cancellables)

#if IOS
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        self.bubbleView.addInteraction(contextMenuInteraction)
#endif
    }

    func configure(with message: Messageable) {
        self.message = message

        if message.isDeleted {
            self.textView.text = "DELETED"
        } else {
            self.textView.setText(with: message)
        }

        #if IOS
        self.configureConsumption(for: message)
        #endif

        self.authorView.set(avatar: message.avatar)

        self.setNeedsLayout()
    }

    /// Sets the background color and shows/hides the bubble tail.
    func configureBackground(color: UIColor,
                             textColor: UIColor,
                             brightness: CGFloat,
                             focusAmount: CGFloat,
                             showBubbleTail: Bool,
                             tailOrientation: SpeechBubbleView.TailOrientation) {

        self.textView.textColor = textColor
        self.bubbleView.setBubbleColor(color.withAlphaComponent(brightness), animated: false)
        self.bubbleView.tailLength = showBubbleTail ? MessageContentView.bubbleTailLength : 0
        self.bubbleView.orientation = tailOrientation

        // NOTE: Changes to the gradient layer need to be applied immediately without animation.
        // https://stackoverflow.com/questions/5833488/how-to-disable-calayer-implicit-animations
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        self.bubbleView.lightGradientLayer.opacity
        = Float(1 - focusAmount) * 0.2 * Float(1 - brightness)
        self.bubbleView.darkGradientLayer.opacity
        = Float(focusAmount) * 0.2 * Float(1 - brightness)

        CATransaction.commit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.bubbleView.expandToSuperviewSize()

        self.authorView.size = self.getAuthorSize(for: self.state)
        self.authorView.pin(.top, offset: MessageContentView.padding)
        self.authorView.pin(.left, offset: MessageContentView.padding)

        self.textView.size = self.textView.getSize(with: self.state, width: self.bubbleView.bubbleFrame.width)

        if self.state == .thread {
            self.textView.textAlignment = .left
            self.textView.match(.left, to: .right, of: self.authorView, offset: MessageContentView.padding)
            self.textView.centerOnY()
        } else if state == .expanded {
            if self.textView.numberOfLines > 1 {
                self.textView.textAlignment = .left
                self.textView.pin(.left, offset: MessageContentView.padding)
                self.textView.centerOnY()
                if self.bubbleView.orientation == .up {
                    self.textView.centerY += self.bubbleView.tailLength.half
                }
            } else {
                self.textView.textAlignment = .center
                self.textView.centerOnX()
                self.textView.center = self.bubbleView.center
                self.textView.center.y += self.bubbleView.tailLength.half
            }
        } else if self.textView.numberOfLines > 1 {
            self.textView.textAlignment = .left
            self.textView.pin(.left, offset: MessageContentView.padding)
            self.textView.center.y = self.bubbleView.center.y

            if self.textView.top < MessageContentView.padding.value {
                self.textView.pin(.top, offset: MessageContentView.padding)
            }

        } else {
            self.textView.textAlignment = .center
            self.textView.center = self.bubbleView.center
        }

        if self.state == .collapsed, self.bubbleView.tailLength > 0 {
            switch self.bubbleView.orientation {
            case .up:
                self.textView.center.y += self.bubbleView.tailLength.half
            default:
                break
            }
        }
    }

    func getAuthorSize(for state: State) -> CGSize {
        // Don't show the author for the collapsed state.
        guard state != .collapsed else { return .zero }

        let authorHeight: CGFloat = MessageContentView.standardHeight - Theme.ContentOffset.short.value
        return self.authorView.getSize(for: authorHeight)
    }

    func getSize(for state: State, with width: CGFloat) -> CGSize {
        var size = self.textView.getSize(with: state, width: width)
        size.width += MessageContentView.textViewPadding
        size.height += self.bubbleView.tailLength + MessageContentView.textViewPadding
        return size 
    }
}

extension MessageTextView {

    func getSize(with state: MessageContentView.State, width: CGFloat) -> CGSize {
        let maxTextWidth: CGFloat
        var maxTextHeight: CGFloat = MessageContentView.standardHeight

        switch state {
        case .expanded:
            maxTextWidth = width - MessageContentView.textViewPadding
            maxTextHeight = CGFloat.greatestFiniteMagnitude
        case .thread:
            let size = MessageContentView().getAuthorSize(for: state)
            maxTextWidth = width - (size.width + (MessageContentView.textViewPadding + MessageContentView.textViewPadding.half))
        case .collapsed:
            maxTextWidth = width - MessageContentView.textViewPadding
        }

        return self.getSize(withMaxWidth: maxTextWidth, maxHeight: maxTextHeight)
    }
}
