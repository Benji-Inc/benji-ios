//
//  ConversationMessageCellAttributes.swift
//  Jibber
//
//  Created by Martin Young on 11/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationMessageCellLayoutAttributes: UICollectionViewLayoutAttributes {

    /// If true, then text should be shown in the speech bubble.
    var shouldShowText: Bool = true
    /// The color of the background of the cell.
    var backgroundColor: Color = .white
    /// How bright the background color is. 0 is black. 1 is full brightness of the given color
    var brightness: CGFloat = 1
    /// If true, the speechbubble tail should be shown.
    var shouldShowTail: Bool = false
    /// The direction the speech bubble tail should be pointed.
    var bubbleTailOrientation: SpeechBubbleView.TailOrientation = .down

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ConversationMessageCellLayoutAttributes
        copy.shouldShowText = self.shouldShowText
        copy.backgroundColor = self.backgroundColor
        copy.brightness = self.brightness
        copy.shouldShowTail = self.shouldShowTail
        copy.bubbleTailOrientation = self.bubbleTailOrientation
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let layoutAttributes = object as? ConversationMessageCellLayoutAttributes {
            return super.isEqual(object)
            && layoutAttributes.shouldShowText == self.shouldShowText
            && layoutAttributes.backgroundColor == self.backgroundColor
            && layoutAttributes.brightness == self.brightness
            && layoutAttributes.shouldShowTail == self.shouldShowTail
            && layoutAttributes.bubbleTailOrientation == self.bubbleTailOrientation
        }

        return false
    }
}
