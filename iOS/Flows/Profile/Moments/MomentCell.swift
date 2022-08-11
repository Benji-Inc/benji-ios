//
//  MomentCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/10/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct MomentViewModel: Hashable {
    var date: Date
    var momentId: String?
}

class MomentCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = MomentViewModel
    
    var currentItem: MomentViewModel?
    let label = ThemeLabel(font: .regularBold)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .red)
        self.contentView.layer.cornerRadius = Theme.innerCornerRadius
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
    }
    
    func configure(with item: MomentViewModel) {
        self.label.setText("\(item.date.day)")
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }
}
