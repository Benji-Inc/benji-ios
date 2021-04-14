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
}

struct CommentContentConfiguration: UIContentConfiguration, Hashable {

    var comment: Comment?

    func makeContentView() -> UIView & UIContentView {
        return CommentContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self {
        return self
    }
}
