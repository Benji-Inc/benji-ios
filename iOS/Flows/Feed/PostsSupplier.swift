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

    private(set) var posts: [Postable] = []
    private var cancellables = Set<AnyCancellable>()

    func getItems() -> AnyPublisher<[Postable], Error> {
        self.posts = []
        self.posts.append(MeditationPost())

        ChannelSupplier.shared.allInvitedChannels.forEach { (channel) in
            switch channel.channelType {
            case .channel(let tchChannel):
                self.posts.append(ChannelInvitePost(with: tchChannel.sid!))
            default:
                break
            }
        }

        var publishers: [AnyPublisher<Void, Error>] = []
        publishers.append(self.getInviteAsk())
        publishers.append(self.getNotificationPermissions())
        publishers.append(self.getConnections())
        publishers.append(self.getPosts())

        return waitForAll(publishers).map { (_) -> [Postable] in
            return self.posts.sorted { lhs, rhs in
                return lhs.priority < rhs.priority
            }
        }.eraseToAnyPublisher()
    }

    private func getPosts() -> AnyPublisher<Void, Error> {
        return Future { promise in
            FeedManager.shared.$posts.mainSink { posts in
                self.posts.append(contentsOf: posts)
                promise(.success(()))
            }.store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    private func getInviteAsk() -> AnyPublisher<Void, Error> {
        return Future { promise in
            Reservation.getFirstUnclaimed(for: User.current()!)
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let reservation):
                        self.posts.append(ReservationPost(with: reservation))
                    case .error(_):
                        break
                    }
                    promise(.success(()))
                }).store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    private func getNotificationPermissions() -> AnyPublisher<Void, Error>  {
        return Future { promise in
            UserNotificationManager.shared.getNotificationSettings()
                .mainSink { (settings) in
                    if settings.authorizationStatus != .authorized {
                        self.posts.append(NotificationPermissionsPost())
                    }
                    promise(.success(()))
                }.store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    private func getConnections() -> AnyPublisher<Void, Error> {
        return Future { promise in
            GetAllConnections(direction: .incoming)
                .makeRequest(andUpdate: [], viewsToIgnore: [])
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let connections):
                        connections.forEach { (connection) in
                            if connection.status == .invited {
                                self.posts.append(ConnectionRequestPost(with: connection))
                            }
                        }
                    case .error(_):
                        break
                    }

                    promise(.success(()))
                }).store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
}
