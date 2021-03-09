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

    private(set) var items: [Postable] = []
    private var cancellables = Set<AnyCancellable>()

    func getFirstItems() -> AnyPublisher<[Postable], Error> {
        var futures: [Future<Void, Error>] = []
        futures.append(self.getNewChannels())

        return waitForAll(futures).map { (_) -> [Postable] in
            return self.items // add sorted
        }.eraseToAnyPublisher()
    }

    func getItems() -> AnyPublisher<[Postable], Error> {

        self.items.append(MeditationPost())

        ChannelSupplier.shared.allInvitedChannels.forEach { (channel) in
            switch channel.channelType {
            case .channel(let tchChannel):
                self.items.append(ChannelInvitePost(with: tchChannel.sid!))
            default:
                break
            }
        }

        var futures: [Future<Void, Error>] = []
        futures.append(self.getInviteAsk())
        futures.append(self.getNotificationPermissions())
        futures.append(self.getConnections())

        return waitForAll(futures).map { (_) -> [Postable] in
            return self.items // sort
        }.eraseToAnyPublisher()
    }

    private func getInviteAsk() -> Future<Void, Error> {
        return Future { promise in
            Reservation.getFirstUnclaimed(for: User.current()!)
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let reservation):
                        self.items.append(ReservationPost(with: reservation))
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
                        self.items.append(NotificationPermissionsPost())
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
                                self.items.append(ConnectionRequestPost(with: connection))
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
                               let channelId = connection.channelId {
                                self.items.append(NewChannelPost(with: channelId))
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
