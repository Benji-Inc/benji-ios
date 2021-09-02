//
//  ConversationCollectionViewManager+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/20/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

extension ConversationCollectionViewManager {

    func updateConsumers(for message: Messageable) async throws {
        // Make sure the message can be cosumed before trying to update it.
        guard let current = User.current(),
              !message.isFromCurrentUser,
              message.canBeConsumed,
              !message.hasBeenConsumedBy.contains(current.objectId!) else {

                  return
              }

        // create system message copy of current message
        let messageCopy = SystemMessage(with: message)

        let copyWithConsumers = try await messageCopy.updateConsumers(with: current)
        await self.updateItem(with: copyWithConsumers)
        if message.context == .timeSensitive {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }

        //call update on the actual message and update on callback
        try await message.updateConsumers(with: current)
    }

    func setAllMessagesToRead() async {
        do {
            for message in MessageSupplier.shared.unreadMessages {
                try await self.updateConsumers(for: message)
            }
        } catch {
            logDebug(error)
        }
    }
}
