//
//  NoticeCell.swift
//  Ours
//
//  Created by Benji Dodgson on 5/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticeCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Notice

    var currentItem: Notice?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.set(backgroundColor: .red)
    }

    func configure(with item: Notice) {
        guard let type = item.type else { return }
        switch type {
        case .alert:
            break
        case .connectionRequest:
            break
        case .system:
            break 
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}
