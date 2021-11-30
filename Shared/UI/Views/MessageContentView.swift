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

class MessageContentView: View {

    /// Sizing

    static var minimumHeight: CGFloat { return 50 }
    static var maximumHeight: CGFloat { return 100 }
    static var verticalPadding: CGFloat { return MessageContentView.bubbleTailLength + Theme.contentOffset }

    static let bubbleTailLength: CGFloat = 7

    /// A speech bubble background view for the message.
    let bubbleView = SpeechBubbleView(orientation: .down)
    /// Text view for displaying the text of the message.
    let textView = MessageTextView(font: .regularBold, textColor: .textColor)
    private (set) var message: Messageable?

    let authorView = AvatarView()
    let reactionsView = ReactionsView()

    private var cancellables = Set<AnyCancellable>()

    enum State {
        case expanded
        case collapsed
    }

    @Published var state: State = .collapsed

    deinit {
        self.cancellables.forEach { cancellable in
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
        self.bubbleView.addSubview(self.reactionsView)

        self.$state.mainSink { [unowned self] state in
            self.layoutNow()
        }.store(in: &self.cancellables)
    }

    func configure(with message: Messageable) {
        self.message = message
        if message.isDeleted {
            self.textView.text = "DELETED"
        } else {
            self.textView.setText(with: message)
        }

        self.authorView.set(avatar: message.avatar)
        #if IOS
        if let msg = message as? Message {
            self.reactionsView.configure(with: msg.latestReactions)
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

        let authorHeight: CGFloat = self.state == .collapsed ? .zero : MessageContentView.minimumHeight - Theme.contentOffset
        self.authorView.setSize(for: authorHeight)
        let padding = Theme.contentOffset.half - self.bubbleView.tailLength.half
        let topPadding = self.bubbleView.orientation == .down ? padding : padding + self.bubbleView.tailLength
        self.authorView.pin(.top, padding: topPadding)
        self.authorView.pin(.left, padding: padding)

        self.reactionsView.squaredSize = self.authorView.width
        self.reactionsView.pin(.top, padding: topPadding)
        self.reactionsView.pin(.right, padding: padding)

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
            let authorHeight: CGFloat = MessageContentView.minimumHeight - Theme.contentOffset
            let size = AvatarView().getSize(for: authorHeight)
            maxTextWidth = width - ((size.width * 2) + Theme.contentOffset)
            maxTextHeight = CGFloat.greatestFiniteMagnitude
        case .collapsed:
            maxTextWidth = width 
            maxTextHeight = MessageContentView.maximumHeight - MessageContentView.bubbleTailLength - Theme.contentOffset
        }

        let size = self.getSize(withMaxWidth: maxTextWidth, maxHeight: maxTextHeight)
        return size
    }
}
