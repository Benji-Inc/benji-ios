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

class FeedSupplier {

    static let shared = FeedSupplier()

    private(set) var items: [PostType] = []
    private var cancellables = Set<AnyCancellable>()

    func getFirstItems() -> AnyPublisher<[PostType], Error> {
        var futures: [Future<Void, Error>] = []
        self.items.append(.rountine)
        futures.append(self.getNewChannels())

        return waitForAll(futures).map { (_) -> [PostType] in
            return self.items.sorted()
        }.eraseToAnyPublisher()
    }

    func getItems() -> AnyPublisher<[PostType], Error> {

        self.items.append(.meditation)

        ChannelSupplier.shared.allInvitedChannels.forEach { (channel) in
            switch channel.channelType {
            case .channel(let tchChannel):
                self.items.append(.channelInvite(tchChannel))
            default:
                break
            }
        }

        var futures: [Future<Void, Error>] = []
        futures.append(self.getInviteAsk())
        futures.append(self.getNotificationPermissions())
        futures.append(self.getUnreadMessages())
        futures.append(self.getConnections())

        return waitForAll(futures).map { (_) -> [PostType] in
            return self.items.sorted()
        }.eraseToAnyPublisher()
    }

    private func getInviteAsk() -> Future<Void, Error> {
        return Future { promise in
            Reservation.getFirstUnclaimed(for: User.current()!)
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let reservation):
                        self.items.append(.inviteAsk(reservation))
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

    private func getUnreadMessages() -> Future<Void, Error> {
        var channelFutures: [Future<PostType, Error>] = []
        for channel in ChannelSupplier.shared.allJoinedChannels {
            switch channel.channelType {
            case .channel(let tchChannel):
                channelFutures.append(tchChannel.getUnconsumedAmount())
            default:
                break
            }
        }

        if channelFutures.count == 0 {
            self.items.append(.timeSaved(0))
        }

        return Future { promise in
            waitForAll(channelFutures)
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let channelItems):
                        var totalCount: Int = 0
                        let items = channelItems.filter { (feedType) -> Bool in
                            switch feedType {
                            case .unreadMessages(_,let count):
                                totalCount += count
                                return count > 0
                            default:
                                return false
                            }
                        }
                        self.items.append(.timeSaved(totalCount))
                        self.items.append(contentsOf: items)
                    case .error(_):
                        break 
                    }

                    promise(.success(()))
                }).store(in: &self.cancellables)
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
                                self.items.append(.connectionRequest(connection))
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
                                self.items.append(.newChannel(channel))
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
