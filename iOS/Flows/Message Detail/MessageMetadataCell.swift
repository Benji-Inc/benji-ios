//
//  MessageMetadataCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct MetadataModel: Hashable {
    var conversationId: String
    var messageId: String
}

class MessageMetadataCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = MetadataModel
    
    var currentItem: MetadataModel?

    override func initializeSubviews() {
        super.initializeSubviews()
    }
    
    func configure(with item: MetadataModel) {

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}
