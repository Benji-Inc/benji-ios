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

    private var cancellables = Set<AnyCancellable>()

    func getPosts(for user: User) -> Future<[Postable], Never> {

        var initialPosts: [Postable] = []

        var publishers: [AnyPublisher<[Postable], Error>] = []
        if user == User.current() {

            initialPosts.append(MeditationPost())

            ChannelSupplier.shared.allInvitedChannels.forEach { (channel) in
                switch channel.channelType {
                case .channel(let tchChannel):
                    initialPosts.append(ChannelInvitePost(with: tchChannel.sid!))
                default:
                    break
                }
            }

            publishers.append(self.getInviteAsk())
            publishers.append(self.getNotificationPermissions())
            publishers.append(self.getConnections())
        }

        publishers.append(self.queryForCurrentMediaPosts(for: user))
        publishers.append(self.queryForUnreadPosts(for: user))

        return Future { promise in
            waitForAll(publishers).mainSink { result in
                switch result {
                case .success(let all):
                    var joined: [Postable] = Array(all.joined())
                    joined.append(contentsOf: initialPosts)

                    let sorted = joined.sorted { lhs, rhs in
                        return lhs.priority < rhs.priority
                    }

                    promise(.success(sorted))
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
        }
    }

    func queryForCurrentMediaPosts(for owner: User) -> AnyPublisher<[Postable], Error> {
        return Future { promise in

            if let query = Post.query() {
                query.whereKey("type", containedIn: ["media"])
                query.whereKey("author", equalTo: owner)
                query.whereKey("expirationDate", greaterThanOrEqualTo: Date())
                query.order(byDescending: "createdAt")
                query.findObjectsInBackground { objects, error in
                    if let posts = objects as? [Post] {
                        promise(.success(posts))
                    } else {
                        promise(.failure(ClientError.message(detail: "No posts found on feed")))
                    }
                }

            } else {
                promise(.failure(ClientError.message(detail: "No query for posts")))
            }
        }.eraseToAnyPublisher()
    }

    func queryForUnreadPosts(for owner: User) -> AnyPublisher<[Postable], Error> {
        return Future { promise in

            if let query = Post.query() {
                query.whereKey("type", containedIn: ["unreadMessages", "generalUnreadMessages"])
                query.whereKey("author", equalTo: owner)
                query.whereKey("attributes.numberOfUnread", notEqualTo: 0)
                query.findObjectsInBackground { objects, error in
                    if let posts = objects as? [Post] {
                        promise(.success(posts))
                    } else {
                        promise(.failure(ClientError.message(detail: "No posts found on feed")))
                    }
                }

            } else {
                promise(.failure(ClientError.message(detail: "No query for posts")))
            }
        }.eraseToAnyPublisher()
    }

    func getCountOfMediaPosts(for user: User, excludeExpired: Bool = false) -> AnyPublisher<Int, Error> {

        return Future { promise in
            if let query = Post.query() {
                query.whereKey("type", equalTo: "media")
                query.whereKey("author", equalTo: user)
                if excludeExpired {
                    query.whereKey("expirationDate", greaterThanOrEqualTo: Date())
                }
                query.countObjectsInBackground { count, error in
                    promise(.success(Int(count)))
                }

            } else {
                promise(.failure(ClientError.message(detail: "No query for posts")))
            }
        }.eraseToAnyPublisher()
    }

    func queryForMediaPosts(before: Date? = nil,
                            limit: Int = 5,
                            for user: User) -> AnyPublisher<[Post], Error> {

        return Future { promise in
            if let query = Post.query() {
                query.whereKey("type", equalTo: "media")
                query.whereKey("author", equalTo: user)
                if let date = before {
                    query.whereKey("createdAt", lessThanOrEqualTo: date)
                }
                query.limit = limit
                query.order(byDescending: "createdAt")
                query.findObjectsInBackground { objects, error in
                    if let posts = objects as? [Post] {
                        promise(.success(posts))
                    } else {
                        promise(.failure(ClientError.message(detail: "No posts found on feed")))
                    }
                }

            } else {
                promise(.failure(ClientError.message(detail: "No query for posts")))
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
                        promise(.success([]))
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
