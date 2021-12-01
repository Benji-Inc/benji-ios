//
//  MessageContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
#if IOS
import StreamChat
#endif

class MessageContentView: View {

    #if IOS
    var handleTappedMessage: ((ConversationMessageItem) -> Void)?
    var handleEditMessage: ((ConversationMessageItem) -> Void)?
    var messageController: ChatMessageController?
    #endif

    /// Sizing

    static var standardHeight: CGFloat { return 60 + MessageContentView.bubbleTailLength }
    static var verticalPadding: CGFloat { return MessageContentView.bubbleTailLength + Theme.ContentOffset.xtraLong.value }

    static let bubbleTailLength: CGFloat = 12

    /// A speech bubble background view for the message.
    let bubbleView = SpeechBubbleView(orientation: .down)
    /// Text view for displaying the text of the message.
    let textView = MessageTextView(font: .regularBold, textColor: .textColor)
    private (set) var message: Messageable?

    let authorView = AvatarView()

    private var cancellables = Set<AnyCancellable>()
    var publisherCancellables = Set<AnyCancellable>()

    enum State {
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

        self.$state.mainSink { [unowned self] state in
            self.authorView.isVisible = state == .expanded
            self.layoutNow()
        }.store(in: &self.cancellables)
    }

    #if IOS
    func setContextMenu() {
        self.bubbleView.interactions.removeAll()
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        self.bubbleView.addInteraction(contextMenuInteraction)
    }
    #endif

    func configure(with message: Messageable) {
        self.message = message
        if message.isDeleted {
            self.textView.text = "DELETED"
        } else {
            self.textView.setText(with: message)
        }

        self.configureConsumption(for: message)

        self.authorView.set(avatar: message.avatar)
        #if IOS
        if let msg = message as? Message {
            self.subscribeToUpdates(for: msg)
        }
        #endif

        self.setNeedsLayout()
    }

    /// Sets the background color and shows/hides the bubble tail.
    func configureBackground(color: Color,
                             brightness: CGFloat,
                             showBubbleTail: Bool,
                             tailOrientation: SpeechBubbleView.TailOrientation) {

        self.bubbleView.bubbleColor = color.color.color(withBrightness: brightness)
        self.bubbleView.tailLength = showBubbleTail ? MessageContentView.bubbleTailLength : 0
        self.bubbleView.orientation = tailOrientation
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.bubbleView.expandToSuperviewSize()

        let authorHeight: CGFloat = self.state == .collapsed ? .zero : MessageContentView.standardHeight - MessageContentView.verticalPadding
        self.authorView.setSize(for: authorHeight)
        let padding = Theme.ContentOffset.standard.value - self.bubbleView.tailLength.half
        let topPadding = self.bubbleView.orientation == .down ? padding : padding + self.bubbleView.tailLength
        self.authorView.pin(.top, offset: .custom(topPadding))
        self.authorView.pin(.left, offset: .custom(padding))

        let maxWidth
        = self.bubbleView.bubbleFrame.width - ((self.authorView.width * 2) + Theme.contentOffset)

        self.textView.size = self.textView.getSize(with: self.state, width: maxWidth)

        self.textView.center = self.bubbleView.center

        switch self.bubbleView.orientation {
        case .up:
            self.textView.center.y += self.bubbleView.tailLength.half
        case .down:
            self.textView.center.y -= self.bubbleView.tailLength.half
        default:
            break
        }
    }

    func getSize(with width: CGFloat) -> CGSize {
        let horizontalPadding = ((self.authorView.width * 2) + Theme.contentOffset)
        var textSize = self.textView.getSize(with: self.state, width: width - horizontalPadding)
        textSize.height += MessageContentView.verticalPadding
        return textSize
    }
}

extension MessageTextView {

    func getSize(with state: MessageContentView.State, width: CGFloat) -> CGSize {
        let maxTextWidth: CGFloat
        let maxTextHeight: CGFloat

        switch state {
        case .expanded:
            let authorHeight: CGFloat = MessageContentView.standardHeight - MessageContentView.verticalPadding
            let size = AvatarView().getSize(for: authorHeight)
            maxTextWidth = width - ((size.width * 2) + Theme.contentOffset)
            maxTextHeight = CGFloat.greatestFiniteMagnitude
        case .collapsed:
            maxTextWidth = width 
            maxTextHeight = MessageContentView.standardHeight - MessageContentView.verticalPadding
        }

        let size = self.getSize(withMaxWidth: maxTextWidth, maxHeight: maxTextHeight)
        return size
    }
}
