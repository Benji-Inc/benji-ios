//
//  MessageContentView+Read.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/29/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

#if IOS
extension MessageContentView {

    func configureConsumption(for message: Messageable) {
        if message.isConsumedByMe {
            self.textView.setFont(.regular)
        } else {
            self.textView.setFont(.regular)
        }
    }

    func setToRead() {
        guard let msg = self.message, msg.canBeConsumed else { return }
        Task {
            try await self.message?.setToConsumed()
        }
    }

    func setToUnread() {
        guard let msg = self.message, msg.isConsumedByMe else { return }
        Task {
            try await self.message?.setToUnconsumed()
        }
    }
}
#endif
