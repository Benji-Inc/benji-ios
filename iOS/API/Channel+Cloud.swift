//
//  Channel+Cloud.swift
//  Ours
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

struct CreateChannel: CloudFunction {
    
    typealias ReturnType = Any
    
    var uniqueName: String
    var friendlyName: String
    var attributes: [String: Any]
    var members: [String]
    
    func makeSynchronousRequest(andUpdate statusables: [Statusable],
                     viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {
        
        let params: [String: Any] = ["uniqueName": self.uniqueName,
                                     "friendlyName": self.friendlyName,
                                     "type": "private",
                                     "attributes": self.attributes,
                                     "members": self.members]
        
        return self.makeSynchronousRequest(andUpdate: statusables,
                                params: params,
                                callName: "createChannel",
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }

    @discardableResult
    func makeAsyncRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) async throws -> Any {
        let params: [String: Any] = ["uniqueName": self.uniqueName,
                                     "friendlyName": self.friendlyName,
                                     "type": "private",
                                     "attributes": self.attributes,
                                     "members": self.members]
        
        return try await self.makeRequest(andUpdate: statusables,
                                               params: params,
                                               callName: "createChannel",
                                               viewsToIgnore: viewsToIgnore)
    }
}
