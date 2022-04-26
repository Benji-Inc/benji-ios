//
//  MessageDateLabel.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageDateLabel: ThemeLabel {
    
    func configure(with message: Messageable) {
        self.text = message.createdAt.getTimeAgoString()
    }
}
