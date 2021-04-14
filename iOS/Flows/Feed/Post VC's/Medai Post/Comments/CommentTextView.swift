//
//  CommentTextview.swift
//  Ours
//
//  Created by Benji Dodgson on 4/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class CommentTextView: TextView {

    override func initialize() {
        super.initialize()

        self.isEditable = false
        self.isScrollEnabled = false
        self.isSelectable = true
    }

    func set(text: Localized) {
        let attributedString = AttributedString(text,
                                                fontType: .smallBold,
                                                color: .white)

        self.set(attributed: attributedString,
                 alignment: .left,
                 lineCount: 0,
                 lineBreakMode: .byWordWrapping,
                 stringCasing: .unchanged,
                 isEditable: false,
                 linkColor: .teal)

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
