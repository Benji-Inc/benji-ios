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

    private(set) var items: [FeedType] = []
    private var cancellables = Set<AnyCancellable>()

    func getFirstItems() -> AnyPublisher<[FeedType], Error> {
        var futures: [Future<Void, Error>] = []
        self.items.append(.rountine)
        futures.append(self.getNewChannels())

        return waitForAll(futures).map { (_) -> [FeedType] in
            return self.items.sorted()
        }.eraseToAnyPublisher()
    }

    func getItems() -> AnyPublisher<[FeedType], Error> {

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
        //futures.append(self.getConnections())

        return waitForAll(futures).map { (_) -> [FeedType] in
            return self.items.sorted()
        }.eraseToAnyPublisher()
    }

    private func getInviteAsk() -> Future<Void, Error> {
        return Future { promise in
            Reservation.getFirstUnclaimed(for: User.current()!)
                .mainSink { (reservation, error) in
                    if let res = reservation {
                        self.items.append(.inviteAsk(res))
                    }
                    promise(.success(()))
                }.store(in: &self.cancellables)
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
        var channelFutures: [Future<FeedType, Error>] = []
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
            waitForAll(channelFutures).mainSink { (channelItems, error) in
                var totalCount: Int = 0
                let items = channelItems?.filter { (feedType) -> Bool in
                    switch feedType {
                    case .unreadMessages(_,let count):
                        totalCount += count
                        return count > 0
                    default:
                        return false
                    }
                }
                self.items.append(.timeSaved(totalCount))
                if let i = items {
                    self.items.append(contentsOf: i)
                }

            }.store(in: &self.cancellables)
        }
    }

    private func getConnections() -> Future<Void, Error> {
        return Future { promise in
            GetAllConnections(direction: .incoming)
                .makeRequest(andUpdate: [], viewsToIgnore: [])
                .mainSink(receiveResult: { (connections, error) in
                    if let connections = connections {
                        connections.forEach { (connection) in
                            if connection.status == .invited {
                                self.items.append(.connectionRequest(connection))
                            }
                        }
                    }
                    promise(.success(()))
                }).store(in: &self.cancellables)
        }
    }

    private func getNewChannels() -> Future<Void, Error> {
        return Future { promise in
            GetAllConnections(direction: .incoming)
                .makeRequest(andUpdate: [], viewsToIgnore: [])
                .mainSink(receiveResult: { (connections, error) in
                    if let connections = connections {
                        connections.forEach { (connection) in
                            if connection.status == .accepted,
                               let channelId = connection.channelId,
                               let channel = ChannelSupplier.shared.getChannel(withSID: channelId) {
                                self.items.append(.newChannel(channel))
                            }
                        }
                        promise(.success(()))
                    } else {
                        promise(.failure(ClientError.generic))
                    }
                }).store(in: &self.cancellables)
        }
    }
}
