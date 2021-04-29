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

    func getNextAvailableFeed(after user: User) -> Feed? {
        if let feed = self.feeds.first(where: { feed in
            return feed.owner == user
        }),
        let index = self.feeds.firstIndex(of: feed),
           let next = self.feeds[safe: index + 1] {
            return next
        } else {
            return nil 
        }
    }
}
