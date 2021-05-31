//
//  NoticeCell.swift
//  Ours
//
//  Created by Benji Dodgson on 5/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticeCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = SystemNotice

    var currentItem: SystemNotice?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.layer.borderWidth = 2
        self.contentView.layer.borderColor = Color.white.color.cgColor
        self.contentView.layer.cornerRadius = Theme.cornerRadius
    }

    func configure(with item: SystemNotice) {
        guard let type = item.type else { return }
        switch type {
        case .alert:
            break
        case .connectionRequest:
            break
        case .system:
            break 
        case .ritual:
            break 
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}
