//
//  ExpressionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = Expression
    
    var currentItem: Expression?

    let personView = PersonGradientView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.personView)
    }
    
    func configure(with item: Expression) {
        self.personView.set(expression: item, author: nil)
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.personView.squaredSize = self.contentView.width
        self.personView.centerOnXAndY()
    }
}
