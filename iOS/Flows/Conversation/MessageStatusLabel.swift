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

    var taskPool = TaskPool()

    deinit {
        Task {
            await self.taskPool.cancelAndRemoveAll()
        }
    }

    func set(status: ChatMessageStatus?) {
        guard let status = status else {
            self.text = nil
            return
        }

        self.setText(self.getText(for: status))

        Task {
            await Task.snooze(seconds: 2.0)
            self.setReplies(for: status.message)
        }.add(to: self.taskPool)
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

    @MainActor
    private func setReplies(for message: Message) {
        Task {
            await UIView.awaitAnimation(with: .fast, animations: {
                self.alpha = 0
            })
            self.setText(self.getReplies(for: message))
            await UIView.awaitAnimation(with: .fast, animations: {
                self.alpha = 1
            })
        }.add(to: self.taskPool)
    }

    private func getReplies(for message: Message) -> Localized {
        if message.replyCount == 0 {
            return "No replies"
        } else if message.replyCount == 1 {
            return "1 reply"
        } else {
            return "\(message.replyCount) replies"
        }
    }
}
