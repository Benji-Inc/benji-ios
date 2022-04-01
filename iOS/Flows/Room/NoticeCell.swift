//
//  NoticeCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticeCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Notice
    var currentItem: Notice?
    
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .red)
        self.contentView.layer.cornerRadius = Theme.cornerRadius
        
    }

    func configure(with item: Notice) {

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}
