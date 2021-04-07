//
//  FeedManger.swift
//  Ours
//
//  Created by Benji Dodgson on 3/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Parse

class FeedManager {

    static let shared = FeedManager()
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var feeds: [Feed] = []
    @Published var selectedFeed: Feed? = nil
    
    init() {
        self.createFeedQuery()
    }

    private func createFeedQuery()  {
        guard let query = Feed.query() else { return }

        query.whereKey("owner", equalTo: User.current()!)
        query.includeKey("posts")
        query.getFirstObjectInBackground { object, error in
            if let feed = object as? Feed {
                self.feeds = [feed]
            } else {
                print("No feed found for the current user.")
            }
        }
    }

    func queryForPosts(for feed: Feed) -> Future<[Post], Error> {
        return Future { promise in
            if let query = feed.posts?.query() {
                query.whereKey("expirationDate", greaterThanOrEqualTo: Date())
                query.findObjectsInBackground { objects, error in
                    if let posts = objects {
                        promise(.success(posts))
                    } else {
                        promise(.failure(ClientError.message(detail: "No posts found on feed")))
                    }
                }

            } else {
                promise(.failure(ClientError.message(detail: "No query for posts")))
            }
        }
    }

    func createPost(with imageData: Data) -> Future<Post, Error> {

        return Future { promise in
            if self.feeds.isEmpty {
                promise(.failure(ClientError.apiError(detail: "No Feeds")))
            } else if let currentUserFeed = self.feeds.first(where: { feed in
                return feed.owner == User.current()
            }) {
                let post = Post()
                post.author = User.current()!
                post.body = ""
                post.priority = 2
                post.triggerDate = Date()
                post.expirationDate = Date.add(component: .day, amount: 2, toDate: Date())
                post.type = .media
                post.attributes = ["": String()]
                post.duration = 5
                post.file = PFFileObject(name: UUID().uuidString, data: imageData)
                post.saveToServer()
                    .mainSink { result in
                        switch result {
                        case .success(let p):
                            currentUserFeed.posts?.add(p)
                            currentUserFeed.saveToServer()
                                .mainSink { result in
                                    switch result {
                                    case .success(_):
                                        promise(.success(p))
                                    case .error(let e):
                                        promise(.failure(e))
                                    }
                                }.store(in: &self.cancellables)
                        case .error(let e):
                            promise(.failure(e))
                        }
                    }.store(in: &self.cancellables)
            } else {
                promise(.failure(ClientError.apiError(detail: "No feed found for user")))
            }
        }
    }
}
