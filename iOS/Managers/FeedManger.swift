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

        GetAllFeeds().makeRequest(andUpdate: [], viewsToIgnore: [])
            .mainSink { result in
                switch result {
                case .success(let object):
                    if let feeds = object as? [Feed] {
                        self.feeds = feeds
                    } else {
                        print("No feeds found for the current user.")
                    }
                case .error(_):
                    print("No feed found for the current user.")
                }
            }.store(in: &self.cancellables)
    }

    func queryForMediaPosts(for feed: Feed, excludeExpired: Bool = true) -> Future<[Post], Error> {
        return Future { promise in
            if let query = feed.posts?.query() {
                if feed.owner != User.current() {
                    query.whereKey("type", equalTo: "media")
                }
                if excludeExpired {
                    query.whereKey("expirationDate", greaterThanOrEqualTo: Date())
                }
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

    func createPost(with imageData: Data, progressHandler: @escaping (Int) -> Void) -> Future<Post, Error> {
        return Future { promise in
            if self.feeds.isEmpty {
                promise(.failure(ClientError.apiError(detail: "No Feeds")))
            } else if let currentUserFeed = self.feeds.first(where: { feed in
                return feed.owner == User.current()
            }) {

                let file = PFFileObject(name: UUID().uuidString, data: imageData)
                file?.saveInBackground({ success, error in
                    if let e = error {
                        promise(.failure(e))
                    } else {
                        let post = Post()
                        post.author = User.current()!
                        post.body = ""
                        post.priority = 2
                        post.triggerDate = Date()
                        post.expirationDate = Date.add(component: .day, amount: 2, toDate: Date())
                        post.type = .media
                        post.attributes = ["": String()]
                        post.duration = 5
                        post.file = file
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
                    }
                }, progressBlock: { progress in
                    progressHandler(Int(progress))
                })

            } else {
                promise(.failure(ClientError.apiError(detail: "No feed found for user")))
            }
        }
    }
}
