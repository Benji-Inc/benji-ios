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

    /// A rounded and colored background view for the message. Changes color based on the sender.
    let backgroundColorView = UIView()
    /// Text view for displaying the text of the message.
    let textView = MessageTextView()

    /// Where this cell appears on the z-axis stack of messages. 0 means the item closest to the user.
    private var stackIndex = 0
    /// How much to scale the size of the background view.
    private var scaleFactor: CGFloat {
        return 1 - CGFloat(self.stackIndex) * 0.05
    }

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
        self.textView.isScrollEnabled = false
        self.textView.isEditable = false
        self.textView.textAlignment = .center
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundColorView.width = self.width * self.scaleFactor
        self.backgroundColorView.expandToSuperviewHeight()
        self.backgroundColorView.centerOnXAndY()

        self.textView.expandToSuperviewWidth()
        self.textView.sizeToFit()
        self.textView.centerOnXAndY()
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
    func configureBackground(withStackIndex stackIndex: Int, message: Messageable) {
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

        self.backgroundColorView.backgroundColor = backgroundColor

        self.stackIndex = stackIndex
        self.setNeedsLayout()
    }
}
