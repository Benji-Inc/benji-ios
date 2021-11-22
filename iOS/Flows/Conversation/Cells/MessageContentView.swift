//
//  MessageContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageContentView: View {

    static let bubbleTailLength: CGFloat = 7

    /// A rounded and colored background view for the message. Changes color based on the sender.
    let backgroundColorView = SpeechBubbleView(orientation: .down)
    /// Text view for displaying the text of the message.
    let textView = MessageTextView()
    private (set) var message: Messageable?

    private let authorView = AvatarView()
    private let reactionsView = View()

    enum State {
        case expanded
        case collapsed
    }

    var state: State = .collapsed

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.backgroundColorView)
        self.backgroundColorView.roundCorners()

        self.backgroundColorView.addSubview(self.textView)

        self.textView.textContainer.lineBreakMode = .byTruncatingTail

        self.backgroundColorView.addSubview(self.authorView)
        self.backgroundColorView.addSubview(self.reactionsView)
        self.reactionsView.set(backgroundColor: .red)
    }

    func setText(with message: Messageable) {
        self.message = message
        if message.isDeleted {
            self.textView.text = "DELETED"
        } else {
            self.textView.setText(with: message)
        }

        self.setNeedsLayout()
    }

    /// Sets the background color and shows/hides the bubble tail.
    func configureBackground(color: Color,
                             showBubbleTail: Bool,
                             tailOrientation: SpeechBubbleView.TailOrientation) {

        self.backgroundColorView.bubbleColor = color.color
        self.backgroundColorView.tailLength = showBubbleTail ? MessageContentView.bubbleTailLength : 0
        self.backgroundColorView.orientation = tailOrientation
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundColorView.expandToSuperviewSize()

        let authorSize: CGFloat = self.state == .collapsed ? .zero : MessageContentView.minimumHeight - Theme.contentOffset
        self.authorView.setSize(for: authorSize)
        self.authorView.pin(.top, padding: Theme.contentOffset.half)
        self.authorView.pin(.left, padding: Theme.contentOffset.half)

        self.reactionsView.size = self.authorView.size
        self.reactionsView.pin(.top, padding: Theme.contentOffset.half)
        self.reactionsView.pin(.right, padding: Theme.contentOffset.half)

        let textWidth = self.backgroundColorView.bubbleFrame.width - ((authorSize * 2) + Theme.contentOffset)
        self.textView.width = textWidth
        self.textView.centerOnX()
        self.textView.top = self.backgroundColorView.bubbleFrame.top + Theme.contentOffset.half
        self.textView.expand(.bottom,
                             to: self.backgroundColorView.bubbleFrame.bottom - Theme.contentOffset.half)
    }

    /// Sizing

    static var minimumHeight: CGFloat { return 50 }
    static var maximumHeight: CGFloat { return 100 }

    /// Returns the height that a message subcell should be given a width and message to display.
    static func getHeight(withWidth width: CGFloat, message: Messageable) -> CGFloat {

        // If the message is deleted, we're not going to display its content.
        // Return the minimum height so we have enough to show the deleted status.
        if message.isDeleted {
            return MessageContentView.minimumHeight
        }

        let textView = MessageTextView()
        textView.setText(with: message)
        var textViewSize = textView.getSize(withMaxWidth: width)
        textViewSize.height += Theme.contentOffset
        return clamp(textViewSize.height + MessageContentView.bubbleTailLength,
                     MessageContentView.minimumHeight,
                     MessageContentView.maximumHeight)
    }
}
