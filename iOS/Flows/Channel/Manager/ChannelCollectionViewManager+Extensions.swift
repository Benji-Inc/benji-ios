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
    func updateConsumers(for message: Messageable) -> AnyPublisher<Void, Error> {
        guard let current = User.current(), !message.isFromCurrentUser, message.canBeConsumed, !message.hasBeenConsumedBy.contains(current.objectId!) else {
            return Future { promise in
                promise(.success(()))
            }.eraseToAnyPublisher()
        }

        return Future { promise in 
            //create system message copy of current message
            let messageCopy = SystemMessage(with: message)
            messageCopy.udpateConsumers(with: current)
                .mainSink { copyWithConsumers in
                    self.updateItem(with: copyWithConsumers) {
                        if message.context == .emergency {
                            UIApplication.shared.applicationIconBadgeNumber = 0
                        }

                        //call update on the actual message and update on callback
                        message.udpateConsumers(with: current)
                            .mainSink { _ in
                                promise(.success(()))
                            }.store(in: &self.cancellables)
                    }
                }.store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    func setAllMessagesToRead() -> AnyPublisher<[Void], Error> {
        let publishers: [AnyPublisher<Void, Error>] = MessageSupplier.shared.unreadMessages.map { (message) -> AnyPublisher<Void, Error> in
            return self.updateConsumers(for: message)
        }

        return waitForAll(publishers)
    }
}
