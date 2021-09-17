//
//  UserCell.swift
//  UserCell
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = User

    var currentItem: User?


    override func initializeSubviews() {
        super.initializeSubviews()


    }

    func configure(with item: User) {
        
    }

    override func layoutSubviews() {
        super.layoutSubviews()


    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.currentItem = nil
    }
}
