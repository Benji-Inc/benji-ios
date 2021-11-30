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

    /// A rounded and colored background view for the message. Changes color based on the sender.
    let backgroundColorView = SpeechBubbleView(orientation: .down)
    /// Text view for displaying the text of the message.
    let textView = MessageTextView(font: .regularBold, textColor: .textColor)
    private (set) var message: Messageable?

    let authorView = AvatarView()
    let reactionsView = ReactionsView()

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

        self.addSubview(self.backgroundColorView)
        self.backgroundColorView.roundCorners()

        self.backgroundColorView.addSubview(self.textView)
        self.textView.textContainer.lineBreakMode = .byTruncatingTail

        self.backgroundColorView.addSubview(self.authorView)
        self.backgroundColorView.addSubview(self.reactionsView)

        self.$state.mainSink { [unowned self] state in
            self.authorView.isVisible = state == .expanded
            self.reactionsView.isVisible = state == .expanded
            self.layoutNow()
        }.store(in: &self.cancellables)
    }

    #if IOS
    func setContextMenu() {
        self.backgroundColorView.interactions.removeAll()
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        self.backgroundColorView.addInteraction(contextMenuInteraction)
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
            self.reactionsView.configure(with: msg.latestReactions)
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

        self.backgroundColorView.bubbleColor = color.color.color(withBrightness: brightness)
        self.backgroundColorView.tailLength = showBubbleTail ? MessageContentView.bubbleTailLength : 0
        self.backgroundColorView.orientation = tailOrientation
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundColorView.expandToSuperviewSize()

        let authorHeight: CGFloat = self.state == .collapsed ? .zero : MessageContentView.standardHeight - MessageContentView.verticalPadding
        self.authorView.setSize(for: authorHeight)
        let padding = Theme.ContentOffset.standard.value - self.backgroundColorView.tailLength.half
        let topPadding = self.backgroundColorView.orientation == .down ? padding : padding + self.backgroundColorView.tailLength
        self.authorView.pin(.top, offset: .custom(topPadding))
        self.authorView.pin(.left, offset: .custom(padding))

        self.reactionsView.squaredSize = self.authorView.width
        self.reactionsView.pin(.top, offset: .custom(topPadding))
        self.reactionsView.pin(.right, offset: .custom(padding))

        let maxWidth
        = self.backgroundColorView.bubbleFrame.width - ((self.authorView.width * 2) + Theme.contentOffset)

        self.textView.size = self.textView.getSize(with: self.state, width: maxWidth)

        self.textView.center = self.backgroundColorView.center

        switch self.backgroundColorView.orientation {
        case .up:
            self.textView.center.y += self.backgroundColorView.tailLength.half
        case .down:
            self.textView.center.y -= self.backgroundColorView.tailLength.half
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
