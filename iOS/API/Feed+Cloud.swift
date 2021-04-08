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
                                callName: "getMediaFeeds",
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }
}
