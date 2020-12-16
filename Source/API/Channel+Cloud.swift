//
//  Channel+Cloud.swift
//  Benji
//
//  Created by Benji Dodgson on 5/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

struct CreateChannel: CloudFunction {
    typealias ReturnType = Void

    var uniqueName: String
    var friendlyName: String
    var attributes: [String: Any]
    var members: [String]

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> Future<ReturnType> {
        let params: [String: Any] = ["uniqueName": self.uniqueName,
                                     "friendlyName": self.friendlyName,
                                     "type": "private",
                                     "attributes": self.attributes,
                                     "members": self.members]

        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "createChannel",
                                viewsToIgnore: viewsToIgnore).asVoid()
    }
}
