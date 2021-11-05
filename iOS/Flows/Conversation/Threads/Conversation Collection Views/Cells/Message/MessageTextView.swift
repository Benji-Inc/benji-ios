//
//  MessageTextView.swift
//  Benji
//
//  Created by Benji Dodgson on 7/1/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class MessageTextView: TextView {

    override func initializeViews() {
        super.initializeViews()

        self.isEditable = false
        self.isScrollEnabled = false
        self.isSelectable = true

        self.textContainerInset.top = 0
        self.textContainerInset.bottom = 0
        self.textContainerInset.left = Theme.contentOffset
        self.textContainerInset.right = Theme.contentOffset
    }

    func set(text: Localized, messageContext: MessageContext) {
        let textColor: Color = messageContext == .status ? .darkGray : .textColor
        let attributedString = AttributedString(text,
                                                fontType: .smallBold,
                                                color: textColor)

        self.set(attributed: attributedString,
                 alignment: .center,
                 lineCount: 0,
                 lineBreakMode: .byWordWrapping,
                 stringCasing: .unchanged,
                 isEditable: false,
                 linkColor: .white)

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2

        self.addTextAttributes([NSAttributedString.Key.paragraphStyle: style])
    }

    // Allows us to interact with links if they exist or pass the touch to the next receiver if they do not
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Location of the tap
        var location = point
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top

        // Find the character that's been tapped
        let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if characterIndex < self.textStorage.length {
            // Check if character is a link and handle normally
            if (self.textStorage.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) != nil) {
                return self
            }
        }

        // Return nil to pass touch to next receiver
        return nil
    }
}
