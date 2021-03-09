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

    @Published private(set) var posts: [Post] = []
    @Published private(set) var hasInitialized: Bool = false

    init() {
        self.createFeedQuery()
    }

    private func createFeedQuery()  {
        guard let query = Feed.query() else { return }

        query.whereKey("user", equalTo: User.current()!)
        query.getFirstObjectInBackground { object, error in
            if let feed = object as? Feed {
                self.queryForPosts(for: feed)
            } else {
                print("No feed found for the current user.")
            }
        }
    }

    private func queryForPosts(for feed: Feed) {
        guard let query = feed.posts?.query() else { return }

        query.findObjectsInBackground { objects, error in
            if let posts = objects {
                self.posts = posts
                self.hasInitialized = true
            } else {
                self.hasInitialized = false
            }
        }
    }
}
