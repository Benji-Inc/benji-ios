//
//  User+Cloud.swift
//  Benji
//
//  Created by Benji Dodgson on 5/30/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

struct UpdateUser: CloudFunction {
    typealias ReturnType = Void

    var attributes: [String: Any]

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> Future<ReturnType> {
        return self.makeRequest(andUpdate: statusables,
                                params: self.attributes,
                                callName: "updateUser",
                                viewsToIgnore: viewsToIgnore)
    }
}
