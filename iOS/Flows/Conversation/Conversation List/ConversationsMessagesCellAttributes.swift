//
//  ConversationsMessagesCellAttributes.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/11/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationsMessagesCellAttributes: UICollectionViewLayoutAttributes {

    var canScroll: Bool = true

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ConversationsMessagesCellAttributes
        copy.canScroll = self.canScroll
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let layoutAttributes = object as? ConversationsMessagesCellAttributes {
            return super.isEqual(object)
            && layoutAttributes.canScroll == self.canScroll
        }

        return false
    }
}
