//
//  CircleCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Int
    var currentItem: Int?
    
    private let circleView = CircleView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.circleView)
    }

    func configure(with item: Int) {
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.circleView.expandToSuperviewSize()
    }
}
