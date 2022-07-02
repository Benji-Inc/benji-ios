//
//  ExpressionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = ExpressionInfo
    
    var currentItem: ExpressionInfo?

    let content = ExpressionContentView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.content)
        self.content.personView.expressionVideoView.shouldPlay = true 
    }
    
    func configure(with item: ExpressionInfo) {
        self.content.configure(with: item)
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
    }
}
