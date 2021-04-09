//
//  Feed+Cloud.swift
//  Ours
//
//  Created by Benji Dodgson on 4/7/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

struct GetAllFeeds: CloudFunction {
    typealias ReturnType = Any

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {

        return self.makeRequest(andUpdate: statusables,
                                params: [:],
                                callName: "getFeeds",
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }
}

struct CreateComment: CloudFunction {
    typealias ReturnType = Any

    var postId: String
    var body: String
    var attributes: [String: Any]?
    var replyId: String?

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {

        var params: [String: Any] = ["post": self.postId,
                                     "body": self.body]
        if let attributes = self.attributes {
            params["attributes"] = attributes
        }

        if let reply = self.replyId {
            params["reply"] = reply
        }

        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "createComment",
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }
}
