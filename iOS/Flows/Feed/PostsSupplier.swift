//
//  FeedSupplier.swift
//  Benji
//
//  Created by Benji Dodgson on 11/16/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Parse

class PostsSupplier {

    static let shared = PostsSupplier()

    private(set) var items: [PostType] = []
    private var cancellables = Set<AnyCancellable>()

    func getFirstItems() -> AnyPublisher<[PostType], Error> {
        var futures: [Future<Void, Error>] = []
        futures.append(self.getNewChannels())

        return waitForAll(futures).map { (_) -> [PostType] in
            return self.items // add sorted
        }.eraseToAnyPublisher()
    }

    func getItems() -> AnyPublisher<[PostType], Error> {

        self.items.append(.meditation)

        ChannelSupplier.shared.allInvitedChannels.forEach { (channel) in
            switch channel.channelType {
            case .channel(let tchChannel):
                break
               // self.items.append(.channelInvite(tchChannel))
            default:
                break
            }
        }

        var futures: [Future<Void, Error>] = []
        futures.append(self.getInviteAsk())
        futures.append(self.getNotificationPermissions())
        futures.append(self.getConnections())

        return waitForAll(futures).map { (_) -> [PostType] in
            return self.items // sort
        }.eraseToAnyPublisher()
    }

    private func getInviteAsk() -> Future<Void, Error> {
        return Future { promise in
            Reservation.getFirstUnclaimed(for: User.current()!)
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let reservation):
                        break
                        //self.items.append(.inviteAsk(reservation))
                    case .error(_):
                        break
                    }
                    promise(.success(()))
                }).store(in: &self.cancellables)
        }
    }

    private func getNotificationPermissions() -> Future<Void, Error>  {
        return Future { promise in
            UserNotificationManager.shared.getNotificationSettings()
                .mainSink { (settings) in
                    if settings.authorizationStatus != .authorized {
                        self.items.append(.notificationPermissions)
                    }
                    promise(.success(()))
                }.store(in: &self.cancellables)
        }
    }

    private func getConnections() -> Future<Void, Error> {
        return Future { promise in
            GetAllConnections(direction: .incoming)
                .makeRequest(andUpdate: [], viewsToIgnore: [])
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let connections):
                        connections.forEach { (connection) in
                            if connection.status == .invited {
                                //self.items.append(.connectionRequest(connection))
                            }
                        }
                    case .error(_):
                        break
                    }

                    promise(.success(()))
                }).store(in: &self.cancellables)
        }
    }

    private func getNewChannels() -> Future<Void, Error> {
        return Future { promise in
            GetAllConnections(direction: .incoming)
                .makeRequest(andUpdate: [], viewsToIgnore: [])
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let connections):
                        connections.forEach { (connection) in
                            if connection.status == .accepted,
                               let channelId = connection.channelId,
                               let channel = ChannelSupplier.shared.getChannel(withSID: channelId) {
                                //self.items.append(.newChannel(channel))
                            }
                        }
                        promise(.success(()))
                    case .error(let e):
                        promise(.failure(e))
                    }
                }).store(in: &self.cancellables)
        }
    }
}
