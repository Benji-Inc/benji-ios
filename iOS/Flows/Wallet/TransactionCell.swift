//
//  TransactionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class TransactionCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Transaction
    
    var currentItem: Transaction?
    
    func configure(with item: Transaction) {
        
    }
}
