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

    func selectFeed(for user: User) {
        self.selectedFeed = self.feeds.first(where: { feed in
            return feed.owner == user 
        })
    }

    func createPost(with data: Data,
                    previewData: Data,
                    progressHandler: @escaping (Int) -> Void) -> Future<Post, Error> {

        return Future { promise in
            if self.feeds.isEmpty {
                promise(.failure(ClientError.apiError(detail: "No Feeds")))
            } else if let currentUserFeed = self.feeds.first(where: { feed in
                return feed.owner == User.current()
            }) {

                let previewFile = PFFileObject(name: UUID().uuidString, data: previewData)
                previewFile?.saveInBackground({ success, error in
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
                        post.preview = previewFile
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

    private func upload(data: Data, for post: Post) {
        let file = PFFileObject(name: UUID().uuidString, data: data)
        file?.saveInBackground({ success, error in
            if let e = error {
                // Do something...
                print(e)
            } else {
                post.file = file
                post.saveToServer()
            }
        }, progressBlock: { progress in
            print(progress)
        })
    }
}
