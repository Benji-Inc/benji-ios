//
//  MessageContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class MessageContentView: View {

    static let bubbleTailLength: CGFloat = 7

    /// A rounded and colored background view for the message. Changes color based on the sender.
    let backgroundColorView = SpeechBubbleView(orientation: .down)
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

        self.addSubview(self.backgroundColorView)
        self.backgroundColorView.roundCorners()

        self.backgroundColorView.addSubview(self.textView)
        self.textView.textContainer.lineBreakMode = .byTruncatingTail

        self.backgroundColorView.addSubview(self.authorView)
        self.backgroundColorView.addSubview(self.reactionsView)

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
        if let msg = message as? Message {
            self.reactionsView.configure(with: msg.latestReactions)
        }

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

        let authorHeight: CGFloat = self.state == .collapsed ? .zero : MessageContentView.minimumHeight - Theme.contentOffset
        self.authorView.setSize(for: authorHeight)
        let padding = Theme.contentOffset.half - self.backgroundColorView.tailLength.half
        let topPadding = self.backgroundColorView.orientation == .down ? padding : padding + self.backgroundColorView.tailLength
        self.authorView.pin(.top, padding: topPadding)
        self.authorView.pin(.left, padding: padding)

        self.reactionsView.squaredSize = self.authorView.width
        self.reactionsView.pin(.top, padding: topPadding)
        self.reactionsView.pin(.right, padding: padding)

        let maxWidth = self.backgroundColorView.bubbleFrame.width - ((self.authorView.width * 2) + Theme.contentOffset)
        let maxHeight = MessageContentView.maximumHeight - MessageContentView.bubbleTailLength - Theme.contentOffset
        self.textView.setSize(withMaxWidth: maxWidth, maxHeight: maxHeight)
        self.textView.center = self.backgroundColorView.bubbleFrame.center
    }

    /// Sizing

    static var minimumHeight: CGFloat { return 50 }
    static var maximumHeight: CGFloat { return 100 }

    /// Returns the height that a message subcell should be given a width and message to display.
    static func getHeight(withWidth width: CGFloat,
                          state: MessageContentView.State, 
                          message: Messageable) -> CGFloat {

        // If the message is deleted, we're not going to display its content.
        // Return the minimum height so we have enough to show the deleted status.
        if message.isDeleted {
            return MessageContentView.minimumHeight
        }

        let textView = MessageTextView()
        textView.setText(with: message)
        let maxWidth: CGFloat
        if state == .collapsed {
            maxWidth = width
        } else {
            let authorHeight: CGFloat = MessageContentView.minimumHeight - Theme.contentOffset
            let size = AvatarView().getSize(for: authorHeight)
            maxWidth = width - ((size.width * 2) + Theme.contentOffset)
        }

        let maxHeight = MessageContentView.maximumHeight - MessageContentView.bubbleTailLength
        var textViewSize = textView.getSize(withMaxWidth: maxWidth, maxHeight: maxHeight)
        textViewSize.height += Theme.contentOffset

        return clamp(textViewSize.height + MessageContentView.bubbleTailLength,
                     MessageContentView.minimumHeight,
                     MessageContentView.maximumHeight)
    }
}
