//
//  MessageReadCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct ReadViewModel: Hashable {
    var authorId: String?
    var createdAt: Date?
}

class MessageReadCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = ReadViewModel
    
    var currentItem: ReadViewModel?
    
    let content = MessageReadContentView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.content)
    }

    func configure(with item: ReadViewModel) {
        self.content.configure(with: item)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.content.expandToSuperviewSize()
    }
}

