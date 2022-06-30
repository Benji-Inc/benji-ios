//
//  RepliesBadgeView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class RepliesBadgeView: BadgeCounterView {
    
    func configure(with message: Messageable) {
        self.set(value: message.totalReplyCount)
    }
}
