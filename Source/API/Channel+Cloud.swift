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

    var friendlyName: String
    var context: ConversationContext
    var members: [String]

    func makeRequest() -> Future<String> {
        let promise = Promise<String>()

        let uniqueName = UUID().uuidString

        PFCloud.callFunction(inBackground: "createChatChannel",
                             withParameters: ["uniqueName": uniqueName,
                                              "friendlyName": self.friendlyName,
                                              "context": self.context.rawValue,
                                              "members": self.members]) { (object, error) in
                                                if let error = error {
                                                    SessionManager.shared.handleParse(error: error)
                                                    promise.reject(with: error)
                                                } else {
                                                    promise.resolve(with: uniqueName)
                                                }
        }

        return promise.withResultToast()
    }
}
