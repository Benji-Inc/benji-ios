//
//  MessageReadView.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/19/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class ReadIndicatorView: ImageCounterView {
    
    init() {
        super.init(with: .eyeglasses)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with message: Messageable) {
        if message.canBeConsumed {
            self.viewState = .empty
        } else if !message.isFromCurrentUser,
                   message.isConsumedByMe,
                   message.hasBeenConsumedBy.count == 1 {
            self.viewState = .empty
        } else {
            self.viewState = .count(message.nonMeConsumers.count)
        }
    }
}
