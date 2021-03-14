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

    @Published private(set) var posts: [Postable] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.subscribeToUpdates()
    }

    private func subscribeToUpdates() {
        FeedManager.shared.$selectedFeed.mainSink(receiveValue: { _ in
            self.createPosts()
        }).store(in: &self.cancellables)
    }

    private func createPosts() {
        self.posts = []

        var initialPosts: [Postable] = []
        initialPosts.append(MeditationPost())

        ChannelSupplier.shared.allInvitedChannels.forEach { (channel) in
            switch channel.channelType {
            case .channel(let tchChannel):
                initialPosts.append(ChannelInvitePost(with: tchChannel.sid!))
            default:
                break
            }
        }

        var publishers: [AnyPublisher<[Postable], Error>] = []
        publishers.append(self.getInviteAsk())
        publishers.append(self.getNotificationPermissions())
        publishers.append(self.getConnections())
        publishers.append(self.getPosts())

        waitForAll(publishers).mainSink { result in
            switch result {
            case .success(let all):
                let joined = Array(all.joined())
                let sorted = joined.sorted { lhs, rhs in
                    return lhs.priority < rhs.priority
                }

                self.posts = sorted
            case .error(_):
                break
            }
        }.store(in: &self.cancellables)
    }

    private func getPosts() -> AnyPublisher<[Postable], Error> {
        return Future { promise in
            if let feed = FeedManager.shared.selectedFeed {
                FeedManager.shared.queryForPosts(for: feed)
                    .mainSink { result in
                        switch result {
                        case .success(let posts):
                            promise(.success(posts))
                        case .error(let e):
                            promise(.failure(e))
                        }
                }.store(in: &self.cancellables)
            } else {
                promise(.failure(ClientError.message(detail: "No feed selected")))
            }

        }.eraseToAnyPublisher()
    }

    private func getInviteAsk() -> AnyPublisher<[Postable], Error> {
        return Future { promise in
            Reservation.getFirstUnclaimed(for: User.current()!)
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let reservation):
                        promise(.success([ReservationPost(with: reservation)]))
                    case .error(_):
                        break
                    }

                }).store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    private func getNotificationPermissions() -> AnyPublisher<[Postable], Error>  {
        return Future { promise in
            UserNotificationManager.shared.getNotificationSettings()
                .mainSink { (settings) in
                    if settings.authorizationStatus != .authorized {
                        promise(.success([NotificationPermissionsPost()]))
                    } else {
                        promise(.success([]))
                    }
                }.store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    private func getConnections() -> AnyPublisher<[Postable], Error> {
        return Future { promise in
            GetAllConnections(direction: .incoming)
                .makeRequest(andUpdate: [], viewsToIgnore: [])
                .mainSink(receivedResult: { (result) in
                    var connetionPosts: [Postable] = []
                    switch result {
                    case .success(let connections):
                        connections.forEach { (connection) in
                            if connection.status == .invited {
                                connetionPosts.append(ConnectionRequestPost(with: connection))
                            }
                        }
                    case .error(_):
                        break
                    }

                    promise(.success(connetionPosts))
                }).store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
}
