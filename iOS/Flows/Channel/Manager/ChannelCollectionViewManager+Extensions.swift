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

#warning("Convert to async")
    @discardableResult
    func updateConsumers(for message: Messageable) -> AnyPublisher<Void, Error> {
        guard let current = User.current(), !message.isFromCurrentUser, message.canBeConsumed, !message.hasBeenConsumedBy.contains(current.objectId!) else {
            return Future { promise in
                promise(.success(()))
            }.eraseToAnyPublisher()
        }

        return Future { promise in 
            //create system message copy of current message
            let messageCopy = SystemMessage(with: message)
            Task {
                do {
                    let copyWithConsumers = try await messageCopy.updateConsumers(with: current)
                    self.updateItem(with: copyWithConsumers) {
                        if message.context == .timeSensitive {
                            UIApplication.shared.applicationIconBadgeNumber = 0
                        }

                        Task {
                            do {
                                //call update on the actual message and update on callback
                                try await message.updateConsumers(with: current)
                                promise(.success(()))
                            } catch {
                                logDebug(error)
                            }
                        }
                    }
                } catch {
                    promise(.failure(error))
                }
            }

        }.eraseToAnyPublisher()
    }

    #warning("Convert to async")
    func setAllMessagesToRead() -> AnyPublisher<[Void], Error> {
        let publishers: [AnyPublisher<Void, Error>] = MessageSupplier.shared.unreadMessages.map { (message) -> AnyPublisher<Void, Error> in
            return self.updateConsumers(for: message)
        }

        return waitForAll(publishers)
    }
}
