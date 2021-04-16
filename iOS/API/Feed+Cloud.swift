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

    var comment: SystemComment

    // Add system comment

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {

        var params: [String: Any] = ["post": self.comment.post!.objectId!,
                                     "body": self.comment.body!,
                                     "updateId": self.comment.updateId!]
        if let attributes = self.comment.attributes {
            params["attributes"] = attributes
        }

        if let reply = self.comment.reply?.objectId {
            params["reply"] = reply
        }

        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "createComment",
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }
}
