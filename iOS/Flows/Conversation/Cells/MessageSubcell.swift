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

    /// Adjusts the background color of the cell to be appropriate for its position in the stack. Cells that are further back in the stack are darkened.
    func configureBackground(withStackIndex stackIndex: Int,
                             message: Messageable,
                             showBubbleTail: Bool) {

        // How much to scale the brightness of the background view.
        let colorFactor = 1 - CGFloat(stackIndex) * 0.05

        var backgroundColor: UIColor
        if message.isFromCurrentUser {
            backgroundColor = Color.gray.color
        } else {
            backgroundColor = Color.lightGray.color
        }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            backgroundColor = UIColor(red: red * colorFactor,
                                      green: green * colorFactor,
                                      blue: blue * colorFactor,
                                      alpha: alpha)
        }

        #warning("")
        self.backgroundColorView.borderColor = .white
        self.backgroundColorView.bubbleColor = backgroundColor
        self.backgroundColorView.tailLength = showBubbleTail ? MessageSubcell.bubbleTailLength : 0

        self.backgroundColorView.orientation = message.isFromCurrentUser ? .down : .up

        self.setNeedsLayout()
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
