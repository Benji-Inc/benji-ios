//
//  ConversationDetailCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationDetailCell: OptionCell, ManageableCell {
    
    typealias ItemType = ConversationDetailCollectionViewDataSource.OptionType
    
    var currentItem: ConversationDetailCollectionViewDataSource.OptionType?
    
    func configure(with item: ConversationDetailCollectionViewDataSource.OptionType) {
        self.configureFor(option: item)
    }
}

