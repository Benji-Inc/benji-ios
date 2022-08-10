//
//  MomentCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/10/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct MomentModel: Hashable {
    var date: Date
    var momentId: String?
}

class MomentCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = MomentModel
    
    var currentItem: MomentModel?
    
    func configure(with item: MomentModel) {
        
    }
}
