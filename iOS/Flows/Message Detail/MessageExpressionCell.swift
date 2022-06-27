//
//  MessageExpressionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageExpressionCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = ExpressionInfo
    
    var currentItem: ExpressionInfo?
    
    let content = ExpressionContentView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.content)
    }

    func configure(with item: ExpressionInfo) {
        self.content.configure(with: item)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.content.expandToSuperviewSize()
    }
}
