//
//  InputTypeCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputTypeCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = InputType

    var currentItem: InputType?

    override func initializeSubviews() {
        super.initializeSubviews()
    }


    func configure(with item: InputType) {
        self.currentItem = item

        
    }
}
