//
//  NewChannelCell.swift
//  Ours
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Connection

    func configure(with item: Connection) {
        guard let nonMeUser = item.nonMeUser else { return }
    }
}
