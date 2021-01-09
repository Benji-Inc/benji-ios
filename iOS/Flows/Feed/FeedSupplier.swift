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
        //futures.append(self.getInviteAsk())
        //futures.append(self.getNotificationPermissions())
        //futures.append(self.getUnreadMessages())
        //futures.append(self.getConnections())

        return waitForAll(futures).map { (_) -> [FeedType] in
            return self.items.sorted()
        }.eraseToAnyPublisher()
    }

//    private func getInviteAsk() -> Future<Void, Error> {
//        return Reservation.getFirstUnclaimed(for: User.current()!).map { (reservation) -> Void in
//            return ()
//        }
//        return Reservation.getFirstUnclaimed(for: User.current()!)
//            .flatMap({ (reservation) -> Void in
//                self.items.append(.inviteAsk(reservation))
//                return ()
//            })
//    }

//    private func getNotificationPermissions() -> Future<Void, Never>  {
//        let promise = Promise<Void>()
//        UserNotificationManager.shared.getNotificationSettings()
//            .observeValue { (settings) in
//                if settings.authorizationStatus != .authorized {
//                    self.items.append(.notificationPermissions)
//                }
//                promise.resolve(with: ())
//        }
//
//        return promise
//    }

//    private func getUnreadMessages() -> Future<Void> {
//
//        var channelFutures: [Future<FeedType>] = []
//        for channel in ChannelSupplier.shared.allJoinedChannels {
//            switch channel.channelType {
//            case .channel(let tchChannel):
//                channelFutures.append(tchChannel.getUnconsumedAmount())
//            default:
//                break
//            }
//        }
//
//        if channelFutures.count == 0 {
//            self.items.append(.timeSaved(0))
//        }

//        return waitForAll(futures: channelFutures).transform { (channelItems) -> Void in
//            var totalCount: Int = 0
//            let items = channelItems.filter { (feedType) -> Bool in
//                switch feedType {
//                case .unreadMessages(_,let count):
//                    totalCount += count
//                    return count > 0
//                default:
//                    return false
//                }
//            }
//            self.items.append(.timeSaved(totalCount))
//            self.items.append(contentsOf: items)
//        }.asVoid()
//    }
//
//    private func getConnections() -> Future<Void> {
//        let promise = Promise<Void>()
//        GetAllConnections(direction: .incoming)
//            .makeRequest(andUpdate: [], viewsToIgnore: [])
//            .mainSink(receiveValue: { [unowned self] (connections) in
//                connections.forEach { (connection) in
//                    if connection.status == .invited {
//                        self.items.append(.connectionRequest(connection))
//                    }
//                }
//            }, receiveCompletion: { (_) in
//
//            }).store(in: &self.cancellables)
//        }
//
//        return promise
//    }

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
