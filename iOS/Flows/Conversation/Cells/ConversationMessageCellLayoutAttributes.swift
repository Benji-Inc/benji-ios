//
//  ConversationMessageCellAttributes.swift
//  Jibber
//
//  Created by Martin Young on 11/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationMessageCellLayoutAttributes: UICollectionViewLayoutAttributes {

    /// How bright the background color is. 0 is black. 1 is full brightness of the given color
    var brightness: CGFloat = 1
    /// The alpha of the detial view.
    var detailAlpha: CGFloat = 0

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ConversationMessageCellLayoutAttributes
        copy.brightness = self.brightness
        copy.detailAlpha = self.detailAlpha
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let layoutAttributes = object as? ConversationMessageCellLayoutAttributes {
            return super.isEqual(object)
            && layoutAttributes.brightness == self.brightness
            && layoutAttributes.detailAlpha == self.detailAlpha
        }

        return false
    }
}
