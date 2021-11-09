//
//  NoticeCell.swift
//  Jibber
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

        self.contentView.layer.cornerRadius = Theme.cornerRadius
    }

    func configure(with item: SystemNotice) {}
}
