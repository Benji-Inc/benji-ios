//
//  MemberCellLayoutAttributes.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/13/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MemberCellLayoutAttributes: UICollectionViewLayoutAttributes {

    var contentSize: CGSize = .zero
    var contentTransform: CGAffineTransform = .identity
    var contentCenter: CGPoint = .zero

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! MemberCellLayoutAttributes
        copy.contentSize = self.contentSize
        copy.contentTransform = self.contentTransform
        copy.contentCenter = self.contentCenter
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let layoutAttributes = object as? MemberCellLayoutAttributes {
            return super.isEqual(object)
            && layoutAttributes.contentSize == self.contentSize
            && layoutAttributes.contentTransform == self.contentTransform
            && layoutAttributes.contentCenter == self.contentCenter
        }

        return false
    }
}
