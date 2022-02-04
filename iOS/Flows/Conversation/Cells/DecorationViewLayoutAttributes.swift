//
//  DecorationViewLayoutAttributes.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class DecorationViewLayoutAttributes: UICollectionViewLayoutAttributes {

    var state: ConversationUIState = .read

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as!DecorationViewLayoutAttributes
        copy.state = self.state
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let layoutAttributes = object as? DecorationViewLayoutAttributes {
            return super.isEqual(object)
            && layoutAttributes.state == self.state
        }

        return false
    }
}
