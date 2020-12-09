//
//  ChatToken+Cloud.swift
//  Benji
//
//  Created by Benji Dodgson on 5/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

struct GetChatToken: CloudFunction {
    typealias ReturnType = String

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> Future<ReturnType> {
        return self.makeRequest(andUpdate: statusables,
                                params: [:],
                                callName: "getChatToken",
                                viewsToIgnore: viewsToIgnore)
    }
}
