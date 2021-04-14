//
//  CommentsCell.swift
//  Ours
//
//  Created by Benji Dodgson on 4/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import TMROLocalization

class CommentCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = Comment

    var currentItem: Comment?

    func configure(with item: Comment) {
        var config = CommentContentConfiguration()
        config.comment = item
        self.contentConfiguration = config
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let height: CGFloat = layoutAttributes.size.height > 0 ? layoutAttributes.size.height : 44
        layoutAttributes.size = CGSize(width: layoutAttributes.size.width, height: height)
        return layoutAttributes
    }
}
