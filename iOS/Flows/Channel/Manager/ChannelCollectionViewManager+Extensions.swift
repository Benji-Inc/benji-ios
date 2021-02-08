//
//  ChannelCollectionViewManager+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/20/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

extension ChannelCollectionViewManager {

    @discardableResult
    func updateConsumers(for message: Messageable) -> Future<Void, Error> {
        guard let current = User.current(), !message.isFromCurrentUser, message.canBeConsumed, !message.hasBeenConsumedBy.contains(current.id) else { return Future { promise in promise(.success(()))}
        }
        
        //create system message copy of current message
        let messageCopy = SystemMessage(with: message)
        messageCopy.udpateConsumers(with: current)

        runMain {
            //update the current message with the copy
            self.updateItem(with: messageCopy, completion: nil)
        }

        //call update on the actual message and update on callback
        return message.udpateConsumers(with: current)
    }

    func setAllMessagesToRead() -> AnyPublisher<[Void], Error> {
        let futures: [Future<Void, Error>] = MessageSupplier.shared.unreadMessages.map { (message) -> Future<Void, Error> in
            return self.updateConsumers(for: message)
        }

        return waitForAll(futures)
    }
}
