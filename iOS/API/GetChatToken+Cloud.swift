//
//  ChatToken+Cloud.swift
//  Benji
//
//  Created by Benji Dodgson on 5/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

struct GetChatToken: CloudFunction {
    
    typealias ReturnType = String

    func makeRequest(andUpdate statusables: [Statusable] = [],
                     viewsToIgnore: [UIView] = []) -> AnyPublisher<String, Error> {

        return self.makeRequest(andUpdate: statusables,
                                params: [:],
                                callName: "getChatToken",
                                viewsToIgnore: viewsToIgnore).map({ (value) -> String in
            return value as? String ?? String()
        }).eraseToAnyPublisher()
    }

    func makeAsyncRequest(andUpdate statusables: [Statusable] = [],
                          viewsToIgnore: [UIView] = []) async throws -> String {

        let result = try await self.makeAsyncRequest(andUpdate: [],
                                                     params: [:],
                                                     callName: "getChatToken",
                                                     viewsToIgnore: [])

        guard let token = result as? String else {
            throw(ClientError.apiError(detail: "Chat token error"))
        }

        return token
    }
}
