//
//  ReactionsCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ReactionsCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Set<ChatMessageReaction>

    var currentItem: Set<ChatMessageReaction>?

    func configure(with item: Set<ChatMessageReaction>) {

    }
}
