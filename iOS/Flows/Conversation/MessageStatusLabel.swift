//
//  MessageStatusLabel.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class MessageStatusLabel: MessageDateLabel {

    func set(status: ChatMessageStatus?) {
        guard let status = status else {
            self.text = nil
            return
        }

        self.setText(self.getText(for: status))
    }

    private func getText(for status: ChatMessageStatus) -> Localized {

        if let state = status.state {
            switch state {
            case .pendingSync, .syncing:
                return "Syncing"
            case .syncingFailed, .sendingFailed:
                return "Error"
            case .pendingSend, .sending:
                return "Sending"
            case .deleting:
                break
            case .deletingFailed:
                break
            }
        } else if status.isRead {
            return status.message.isFromCurrentUser ? "Read" : "Seen"
        } else {
            return status.message.isFromCurrentUser ? "Sent" : "Received"
        }

        return LocalizedString.empty
    }
}
