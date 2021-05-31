//
//  AlertCell.swift
//  Ours
//
//  Created by Benji Dodgson on 5/31/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AlertCell: NoticeCell {

    override func configure(with item: SystemNotice) {
        super.configure(with: item)

        guard let messageId = item.attributes?["channelId"] as? String,
              let channelId = item.attributes?["messageId"] as? String else { return }

        
    }
    
}
