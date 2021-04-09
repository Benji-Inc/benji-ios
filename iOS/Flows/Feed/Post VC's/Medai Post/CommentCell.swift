//
//  CommentsCell.swift
//  Ours
//
//  Created by Benji Dodgson on 4/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CommentCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Comment

    var currentItem: Comment?

    func configure(with item: Comment) {
        // Lets try using a configuration for display
    }

    override func layoutSubviews() {
        super.layoutSubviews()

    }
}
