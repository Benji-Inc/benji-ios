//
//  AttachmentOptionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class AttachmentOptionCell: OptionCell, ManageableCell {
    typealias ItemType = AttachmentsCollectionViewDataSource.OptionType
    
    var currentItem: AttachmentsCollectionViewDataSource.OptionType?

    func configure(with item: AttachmentsCollectionViewDataSource.OptionType) {
        self.configureFor(option: item)
    }
}
