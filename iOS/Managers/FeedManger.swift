//
//  FeedManger.swift
//  Ours
//
//  Created by Benji Dodgson on 3/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

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
}
